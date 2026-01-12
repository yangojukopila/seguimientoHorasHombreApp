-- ============================================
-- Horas-CMK-CIC Database Functions
-- Business Logic for Hour Classification
-- ============================================

-- ============================================
-- FUNCTION: Check if employee has active shift
-- ============================================
CREATE OR REPLACE FUNCTION fn_check_active_shift(p_employee_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    active_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO active_count
    FROM time_records
    WHERE employee_id = p_employee_id
      AND check_out IS NULL;
    
    RETURN active_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Check if date is a holiday
-- ============================================
CREATE OR REPLACE FUNCTION fn_is_holiday(p_date DATE)
RETURNS BOOLEAN AS $$
DECLARE
    holiday_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO holiday_count
    FROM holidays
    WHERE date = p_date;
    
    RETURN holiday_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Calculate hours breakdown
-- Colombian labor law classification
-- ============================================
CREATE OR REPLACE FUNCTION fn_calculate_hours(
    p_check_in TIMESTAMP WITH TIME ZONE,
    p_check_out TIMESTAMP WITH TIME ZONE
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_current_time TIMESTAMP WITH TIME ZONE;
    v_segment_end TIMESTAMP WITH TIME ZONE;
    v_segment_hours NUMERIC;
    v_day_of_week INTEGER;
    v_is_holiday BOOLEAN;
    v_is_sunday BOOLEAN;
    v_hour_of_day INTEGER;
    v_is_night BOOLEAN;
    v_is_regular_hours BOOLEAN;
    
    -- Official schedule boundaries
    v_morning_start TIME := '07:00:00';
    v_morning_end TIME := '12:00:00';
    v_afternoon_start TIME := '13:00:00';
    v_afternoon_end_thu TIME := '17:15:00';
    v_afternoon_end_fri TIME := '16:00:00';
    
    -- Night hours boundary (9 PM to 6 AM)
    v_night_start TIME := '21:00:00';
    v_night_end TIME := '06:00:00';
    
    -- Accumulators
    v_ordinaria_diurna NUMERIC := 0;
    v_ordinaria_nocturna NUMERIC := 0;
    v_extra_diurna NUMERIC := 0;
    v_extra_nocturna NUMERIC := 0;
    v_dominical_festiva_diurna NUMERIC := 0;
    v_dominical_festiva_nocturna NUMERIC := 0;
BEGIN
    -- Initialize current time to check_in
    v_current_time := p_check_in;
    
    -- Process time in 1-hour segments
    WHILE v_current_time < p_check_out LOOP
        -- Calculate segment end (1 hour or remaining time)
        v_segment_end := LEAST(
            v_current_time + INTERVAL '1 hour',
            p_check_out
        );
        
        -- Calculate segment duration in hours
        v_segment_hours := EXTRACT(EPOCH FROM (v_segment_end - v_current_time)) / 3600.0;
        
        -- Get day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
        v_day_of_week := EXTRACT(DOW FROM v_current_time);
        
        -- Check if Sunday
        v_is_sunday := (v_day_of_week = 0);
        
        -- Check if holiday
        v_is_holiday := fn_is_holiday(v_current_time::DATE);
        
        -- Get hour of day
        v_hour_of_day := EXTRACT(HOUR FROM v_current_time);
        
        -- Check if night time (9 PM to 6 AM)
        v_is_night := (v_current_time::TIME >= v_night_start OR v_current_time::TIME < v_night_end);
        
        -- Check if within regular hours (Mon-Fri, official schedule)
        v_is_regular_hours := FALSE;
        IF v_day_of_week BETWEEN 1 AND 5 AND NOT v_is_holiday THEN
            -- Monday to Thursday
            IF v_day_of_week BETWEEN 1 AND 4 THEN
                v_is_regular_hours := (
                    (v_current_time::TIME >= v_morning_start AND v_current_time::TIME < v_morning_end) OR
                    (v_current_time::TIME >= v_afternoon_start AND v_current_time::TIME < v_afternoon_end_thu)
                );
            -- Friday
            ELSIF v_day_of_week = 5 THEN
                v_is_regular_hours := (
                    (v_current_time::TIME >= v_morning_start AND v_current_time::TIME < v_morning_end) OR
                    (v_current_time::TIME >= v_afternoon_start AND v_current_time::TIME < v_afternoon_end_fri)
                );
            END IF;
        END IF;
        
        -- Classify the segment
        IF v_is_sunday OR v_is_holiday THEN
            -- Sunday or holiday hours
            IF v_is_night THEN
                v_dominical_festiva_nocturna := v_dominical_festiva_nocturna + v_segment_hours;
            ELSE
                v_dominical_festiva_diurna := v_dominical_festiva_diurna + v_segment_hours;
            END IF;
        ELSIF v_is_regular_hours THEN
            -- Regular working hours
            IF v_is_night THEN
                v_ordinaria_nocturna := v_ordinaria_nocturna + v_segment_hours;
            ELSE
                v_ordinaria_diurna := v_ordinaria_diurna + v_segment_hours;
            END IF;
        ELSE
            -- Overtime hours
            IF v_is_night THEN
                v_extra_nocturna := v_extra_nocturna + v_segment_hours;
            ELSE
                v_extra_diurna := v_extra_diurna + v_segment_hours;
            END IF;
        END IF;
        
        -- Move to next segment
        v_current_time := v_segment_end;
    END LOOP;
    
    -- Build result JSON
    v_result := jsonb_build_object(
        'ordinaria_diurna', ROUND(v_ordinaria_diurna, 2),
        'ordinaria_nocturna', ROUND(v_ordinaria_nocturna, 2),
        'extra_diurna', ROUND(v_extra_diurna, 2),
        'extra_nocturna', ROUND(v_extra_nocturna, 2),
        'dominical_festiva_diurna', ROUND(v_dominical_festiva_diurna, 2),
        'dominical_festiva_nocturna', ROUND(v_dominical_festiva_nocturna, 2)
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER: Auto-calculate hours on checkout
-- ============================================
CREATE OR REPLACE FUNCTION trigger_calculate_hours_on_checkout()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate if check_out is being set and was previously NULL
    IF NEW.check_out IS NOT NULL AND OLD.check_out IS NULL THEN
        NEW.hours_breakdown := fn_calculate_hours(NEW.check_in, NEW.check_out);
        NEW.updated_at := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_hours_on_checkout
    BEFORE UPDATE ON time_records
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calculate_hours_on_checkout();

-- ============================================
-- FUNCTION: Generate Colombian holidays
-- ============================================
CREATE OR REPLACE FUNCTION fn_generate_holidays(p_year INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_easter_date DATE;
    v_count INTEGER := 0;
    
    -- Helper function to calculate next Monday
    FUNCTION next_monday(p_date DATE) RETURNS DATE AS $inner$
    BEGIN
        RETURN p_date + ((8 - EXTRACT(DOW FROM p_date)::INTEGER) % 7)::INTEGER;
    END;
    $inner$ LANGUAGE plpgsql IMMUTABLE;
BEGIN
    -- Calculate Easter using Meeus/Jones/Butcher algorithm
    DECLARE
        a INTEGER := p_year % 19;
        b INTEGER := p_year / 100;
        c INTEGER := p_year % 100;
        d INTEGER := b / 4;
        e INTEGER := b % 4;
        f INTEGER := (b + 8) / 25;
        g INTEGER := (b - f + 1) / 3;
        h INTEGER := (19 * a + b - d - g + 15) % 30;
        i INTEGER := c / 4;
        k INTEGER := c % 4;
        l INTEGER := (32 + 2 * e + 2 * i - h - k) % 7;
        m INTEGER := (a + 11 * h + 22 * l) / 451;
        month INTEGER := (h + l - 7 * m + 114) / 31;
        day INTEGER := ((h + l - 7 * m + 114) % 31) + 1;
    BEGIN
        v_easter_date := make_date(p_year, month, day);
    END;
    
    -- Delete existing holidays for this year
    DELETE FROM holidays WHERE year = p_year;
    
    -- Fixed holidays
    INSERT INTO holidays (date, name, year) VALUES
        (make_date(p_year, 1, 1), 'Año Nuevo', p_year),
        (make_date(p_year, 5, 1), 'Día del Trabajo', p_year),
        (make_date(p_year, 7, 20), 'Día de la Independencia', p_year),
        (make_date(p_year, 8, 7), 'Batalla de Boyacá', p_year),
        (make_date(p_year, 12, 8), 'Inmaculada Concepción', p_year),
        (make_date(p_year, 12, 25), 'Navidad', p_year);
    
    v_count := v_count + 6;
    
    -- Holidays moved to next Monday (Ley Emiliani)
    INSERT INTO holidays (date, name, year) VALUES
        (next_monday(make_date(p_year, 1, 6)), 'Reyes Magos', p_year),
        (next_monday(make_date(p_year, 3, 19)), 'San José', p_year),
        (next_monday(make_date(p_year, 6, 29)), 'San Pedro y San Pablo', p_year),
        (next_monday(make_date(p_year, 8, 15)), 'Asunción de la Virgen', p_year),
        (next_monday(make_date(p_year, 10, 12)), 'Día de la Raza', p_year),
        (next_monday(make_date(p_year, 11, 1)), 'Todos los Santos', p_year),
        (next_monday(make_date(p_year, 11, 11)), 'Independencia de Cartagena', p_year);
    
    v_count := v_count + 7;
    
    -- Easter-based holidays
    INSERT INTO holidays (date, name, year) VALUES
        (v_easter_date - INTERVAL '3 days', 'Jueves Santo', p_year),
        (v_easter_date - INTERVAL '2 days', 'Viernes Santo', p_year),
        (next_monday(v_easter_date + INTERVAL '39 days'), 'Ascensión del Señor', p_year),
        (next_monday(v_easter_date + INTERVAL '60 days'), 'Corpus Christi', p_year),
        (next_monday(v_easter_date + INTERVAL '68 days'), 'Sagrado Corazón', p_year);
    
    v_count := v_count + 5;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
