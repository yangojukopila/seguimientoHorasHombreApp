-- ============================================
-- Horas-CMK-CIC - Script Completo de Configuración
-- Ejecutar este script completo en el SQL Editor de Supabase
-- ============================================

-- PASO 1: CREAR TABLAS
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Employees table
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cedula TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    position TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employees_cedula ON employees(cedula);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    client TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_code ON projects(code);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);

-- Islands table
CREATE TABLE IF NOT EXISTS islands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL DEFAULT uuid_generate_v4()::TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_islands_token ON islands(token);
CREATE INDEX IF NOT EXISTS idx_islands_status ON islands(status);

-- Time records table
CREATE TABLE IF NOT EXISTS time_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    island_id UUID NOT NULL REFERENCES islands(id) ON DELETE CASCADE,
    check_in TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out TIMESTAMP WITH TIME ZONE,
    hours_breakdown JSONB DEFAULT '{
        "ordinaria_diurna": 0,
        "ordinaria_nocturna": 0,
        "extra_diurna": 0,
        "extra_nocturna": 0,
        "dominical_festiva_diurna": 0,
        "dominical_festiva_nocturna": 0
    }'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_time_records_employee ON time_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_time_records_project ON time_records(project_id);
CREATE INDEX IF NOT EXISTS idx_time_records_island ON time_records(island_id);
CREATE INDEX IF NOT EXISTS idx_time_records_check_in ON time_records(check_in);
CREATE INDEX IF NOT EXISTS idx_time_records_check_out ON time_records(check_out);

-- Holidays table
CREATE TABLE IF NOT EXISTS holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE UNIQUE NOT NULL,
    name TEXT NOT NULL,
    year INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_holidays_date ON holidays(date);
CREATE INDEX IF NOT EXISTS idx_holidays_year ON holidays(year);

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
DROP TRIGGER IF EXISTS update_employees_updated_at ON employees;
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_time_records_updated_at ON time_records;
CREATE TRIGGER update_time_records_updated_at BEFORE UPDATE ON time_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- PASO 2: CREAR FUNCIONES DE NEGOCIO
-- ============================================

-- Check if employee has active shift
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

-- Check if date is a holiday
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

-- Calculate hours breakdown (simplified version for initial setup)
CREATE OR REPLACE FUNCTION fn_calculate_hours(
    p_check_in TIMESTAMP WITH TIME ZONE,
    p_check_out TIMESTAMP WITH TIME ZONE
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_total_hours NUMERIC;
    v_day_of_week INTEGER;
    v_is_holiday BOOLEAN;
BEGIN
    -- Calculate total hours
    v_total_hours := EXTRACT(EPOCH FROM (p_check_out - p_check_in)) / 3600.0;
    
    -- Get day of week (0=Sunday)
    v_day_of_week := EXTRACT(DOW FROM p_check_in);
    
    -- Check if holiday
    v_is_holiday := fn_is_holiday(p_check_in::DATE);
    
    -- Simple classification (will be enhanced)
    IF v_is_holiday OR v_day_of_week = 0 THEN
        -- Sunday or holiday
        v_result := jsonb_build_object(
            'ordinaria_diurna', 0,
            'ordinaria_nocturna', 0,
            'extra_diurna', 0,
            'extra_nocturna', 0,
            'dominical_festiva_diurna', ROUND(v_total_hours, 2),
            'dominical_festiva_nocturna', 0
        );
    ELSE
        -- Regular weekday (simplified)
        v_result := jsonb_build_object(
            'ordinaria_diurna', ROUND(LEAST(v_total_hours, 9), 2),
            'ordinaria_nocturna', 0,
            'extra_diurna', ROUND(GREATEST(v_total_hours - 9, 0), 2),
            'extra_nocturna', 0,
            'dominical_festiva_diurna', 0,
            'dominical_festiva_nocturna', 0
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-calculate hours on checkout
CREATE OR REPLACE FUNCTION trigger_calculate_hours_on_checkout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_out IS NOT NULL AND OLD.check_out IS NULL THEN
        NEW.hours_breakdown := fn_calculate_hours(NEW.check_in, NEW.check_out);
        NEW.updated_at := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculate_hours_on_checkout ON time_records;
CREATE TRIGGER calculate_hours_on_checkout
    BEFORE UPDATE ON time_records
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calculate_hours_on_checkout();

-- Generate Colombian holidays
CREATE OR REPLACE FUNCTION fn_generate_holidays(p_year INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
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
    
    v_count := 6;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 3: CONFIGURAR SEGURIDAD (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE islands ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admin full access to employees" ON employees;
DROP POLICY IF EXISTS "Kiosk read active employees" ON employees;
DROP POLICY IF EXISTS "Admin full access to projects" ON projects;
DROP POLICY IF EXISTS "Kiosk read active projects" ON projects;
DROP POLICY IF EXISTS "Admin full access to islands" ON islands;
DROP POLICY IF EXISTS "Kiosk read islands" ON islands;
DROP POLICY IF EXISTS "Admin full access to time_records" ON time_records;
DROP POLICY IF EXISTS "Kiosk insert time_records" ON time_records;
DROP POLICY IF EXISTS "Kiosk update time_records for checkout" ON time_records;
DROP POLICY IF EXISTS "Kiosk read time_records" ON time_records;
DROP POLICY IF EXISTS "Admin full access to holidays" ON holidays;
DROP POLICY IF EXISTS "Kiosk read holidays" ON holidays;

-- Employees policies
CREATE POLICY "Admin full access to employees" ON employees FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Kiosk read active employees" ON employees FOR SELECT TO anon USING (status = 'active');

-- Projects policies
CREATE POLICY "Admin full access to projects" ON projects FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Kiosk read active projects" ON projects FOR SELECT TO anon USING (status = 'active');

-- Islands policies
CREATE POLICY "Admin full access to islands" ON islands FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Kiosk read islands" ON islands FOR SELECT TO anon USING (status = 'active');

-- Time records policies
CREATE POLICY "Admin full access to time_records" ON time_records FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Kiosk insert time_records" ON time_records FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Kiosk update time_records for checkout" ON time_records FOR UPDATE TO anon USING (check_out IS NULL) WITH CHECK (check_out IS NOT NULL);
CREATE POLICY "Kiosk read time_records" ON time_records FOR SELECT TO anon USING (true);

-- Holidays policies
CREATE POLICY "Admin full access to holidays" ON holidays FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Kiosk read holidays" ON holidays FOR SELECT TO anon USING (true);

-- Grant function permissions
GRANT EXECUTE ON FUNCTION fn_check_active_shift(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION fn_is_holiday(DATE) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION fn_calculate_hours(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION fn_generate_holidays(INTEGER) TO authenticated;

-- PASO 4: DATOS DE PRUEBA (OPCIONAL)
-- ============================================

-- Sample employees
INSERT INTO employees (cedula, full_name, position, status) VALUES
    ('1234567890', 'Juan Pérez García', 'Soldador', 'active'),
    ('0987654321', 'María López Rodríguez', 'Operario de Torno', 'active'),
    ('1122334455', 'Carlos Martínez Silva', 'Fresador', 'active')
ON CONFLICT (cedula) DO NOTHING;

-- Sample projects
INSERT INTO projects (code, name, client, status) VALUES
    ('PRJ-001', 'Estructura Metálica Edificio Central', 'Constructora ABC', 'active'),
    ('PRJ-002', 'Tanques de Almacenamiento', 'Petroquímica XYZ', 'active'),
    ('PRJ-003', 'Escaleras Industriales', 'Fábrica 123', 'active')
ON CONFLICT (code) DO NOTHING;

-- Sample islands
INSERT INTO islands (name, token, status) VALUES
    ('Isla Taller Principal', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'active'),
    ('Isla Área de Soldadura', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'active')
ON CONFLICT (token) DO NOTHING;

-- Generate holidays for 2026 and 2027
SELECT fn_generate_holidays(2026);
SELECT fn_generate_holidays(2027);

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Ver tablas creadas
SELECT 'Tablas creadas:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Ver funciones creadas
SELECT 'Funciones creadas:' as info;
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Ver datos de prueba
SELECT 'Empleados:' as info;
SELECT cedula, full_name, status FROM employees;

SELECT 'Proyectos:' as info;
SELECT code, name, status FROM projects;

SELECT 'Islas:' as info;
SELECT name, LEFT(token, 20) || '...' as token_preview, status FROM islands;

SELECT 'Festivos 2026:' as info;
SELECT COUNT(*) as total_festivos FROM holidays WHERE year = 2026;

-- ============================================
-- ✅ CONFIGURACIÓN COMPLETA
-- ============================================
