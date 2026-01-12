-- ============================================
-- Horas-CMK-CIC Sample Data (Optional)
-- For testing and development
-- ============================================

-- Sample employees
INSERT INTO employees (cedula, full_name, position, status) VALUES
    ('1234567890', 'Juan Pérez García', 'Soldador', 'active'),
    ('0987654321', 'María López Rodríguez', 'Operario de Torno', 'active'),
    ('1122334455', 'Carlos Martínez Silva', 'Fresador', 'active'),
    ('5544332211', 'Ana Gómez Torres', 'Inspector de Calidad', 'inactive');

-- Sample projects
INSERT INTO projects (code, name, client, status) VALUES
    ('PRJ-001', 'Estructura Metálica Edificio Central', 'Constructora ABC', 'active'),
    ('PRJ-002', 'Tanques de Almacenamiento', 'Petroquímica XYZ', 'active'),
    ('PRJ-003', 'Escaleras Industriales', 'Fábrica 123', 'closed');

-- Sample islands
INSERT INTO islands (name, token, status) VALUES
    ('Isla Taller Principal', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'active'),
    ('Isla Área de Soldadura', 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'active'),
    ('Isla Oficina', 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'inactive');

-- Generate holidays for current year
SELECT fn_generate_holidays(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER);

-- Note: Time records should be created through the application
-- to ensure proper validation and hour calculation
