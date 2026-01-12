-- ============================================
-- Horas-CMK-CIC Row Level Security Policies
-- Security model for kiosk and admin access
-- ============================================

-- Enable RLS on all tables
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE islands ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;

-- ============================================
-- EMPLOYEES TABLE POLICIES
-- ============================================

-- Admin: Full access
CREATE POLICY "Admin full access to employees"
    ON employees
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Kiosk (anon): Read only active employees
CREATE POLICY "Kiosk read active employees"
    ON employees
    FOR SELECT
    TO anon
    USING (status = 'active');

-- ============================================
-- PROJECTS TABLE POLICIES
-- ============================================

-- Admin: Full access
CREATE POLICY "Admin full access to projects"
    ON projects
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Kiosk (anon): Read only active projects
CREATE POLICY "Kiosk read active projects"
    ON projects
    FOR SELECT
    TO anon
    USING (status = 'active');

-- ============================================
-- ISLANDS TABLE POLICIES
-- ============================================

-- Admin: Full access
CREATE POLICY "Admin full access to islands"
    ON islands
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Kiosk (anon): Read only via valid token (handled in application layer)
CREATE POLICY "Kiosk read islands"
    ON islands
    FOR SELECT
    TO anon
    USING (status = 'active');

-- ============================================
-- TIME_RECORDS TABLE POLICIES
-- ============================================

-- Admin: Full access
CREATE POLICY "Admin full access to time_records"
    ON time_records
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Kiosk (anon): Insert only (check-in/check-out)
CREATE POLICY "Kiosk insert time_records"
    ON time_records
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Kiosk (anon): Update only for checkout (setting check_out)
CREATE POLICY "Kiosk update time_records for checkout"
    ON time_records
    FOR UPDATE
    TO anon
    USING (check_out IS NULL)
    WITH CHECK (check_out IS NOT NULL);

-- Kiosk (anon): Read own records (for validation)
CREATE POLICY "Kiosk read time_records"
    ON time_records
    FOR SELECT
    TO anon
    USING (true);

-- ============================================
-- HOLIDAYS TABLE POLICIES
-- ============================================

-- Admin: Full access
CREATE POLICY "Admin full access to holidays"
    ON holidays
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Kiosk (anon): Read only
CREATE POLICY "Kiosk read holidays"
    ON holidays
    FOR SELECT
    TO anon
    USING (true);

-- ============================================
-- GRANT EXECUTE PERMISSIONS ON FUNCTIONS
-- ============================================

-- Allow anon to execute validation and calculation functions
GRANT EXECUTE ON FUNCTION fn_check_active_shift(UUID) TO anon;
GRANT EXECUTE ON FUNCTION fn_is_holiday(DATE) TO anon;
GRANT EXECUTE ON FUNCTION fn_calculate_hours(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO anon;

-- Allow authenticated to execute all functions
GRANT EXECUTE ON FUNCTION fn_check_active_shift(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_is_holiday(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_calculate_hours(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_generate_holidays(INTEGER) TO authenticated;
