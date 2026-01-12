# Guía de Configuración de Supabase

## ✅ Credenciales Configuradas

Las credenciales de Supabase ya están configuradas en los archivos de entorno:

- **URL del Proyecto**: `https://nfqaifxkmhnwunehpnwi.supabase.co`
- **Anon Key**: Configurada ✓

---

## 📋 Pasos para Configurar la Base de Datos

### 1. Acceder al Editor SQL de Supabase

1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Inicia sesión con tu cuenta
3. Selecciona el proyecto: **nfqaifxkmhnwunehpnwi**
4. En el menú lateral, haz clic en **SQL Editor**

---

### 2. Ejecutar Scripts SQL en Orden

> ⚠️ **IMPORTANTE**: Debes ejecutar los scripts en el orden exacto que se indica a continuación.

#### **Paso 1: Crear Tablas** (schema.sql)

1. En el SQL Editor, haz clic en **"+ New query"**
2. Copia y pega el contenido completo de: [`supabase/schema.sql`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/supabase/schema.sql)
3. Haz clic en **"Run"** o presiona `Ctrl/Cmd + Enter`
4. Verifica que aparezca el mensaje: **"Success. No rows returned"**

**Qué crea este script:**
- Tabla `employees` (empleados)
- Tabla `projects` (proyectos)
- Tabla `islands` (islas/kioscos)
- Tabla `time_records` (registros de tiempo)
- Tabla `holidays` (festivos)
- Triggers para actualizar timestamps

---

#### **Paso 2: Crear Funciones y Triggers** (functions.sql)

1. Crea una nueva query en el SQL Editor
2. Copia y pega el contenido completo de: [`supabase/functions.sql`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/supabase/functions.sql)
3. Haz clic en **"Run"**
4. Verifica que aparezca el mensaje de éxito

**Qué crea este script:**
- `fn_check_active_shift()` - Valida si empleado tiene turno activo
- `fn_is_holiday()` - Verifica si una fecha es festivo
- `fn_calculate_hours()` - Calcula y clasifica horas automáticamente
- `fn_generate_holidays()` - Genera festivos colombianos por año
- Trigger para calcular horas al hacer check-out

---

#### **Paso 3: Configurar Seguridad (RLS)** (rls.sql)

1. Crea una nueva query en el SQL Editor
2. Copia y pega el contenido completo de: [`supabase/rls.sql`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/supabase/rls.sql)
3. Haz clic en **"Run"**
4. Verifica que aparezca el mensaje de éxito

**Qué crea este script:**
- Políticas de Row Level Security (RLS)
- Permisos para usuarios anónimos (kioscos)
- Permisos para usuarios autenticados (admins)
- Permisos de ejecución de funciones

---

#### **Paso 4 (Opcional): Datos de Prueba** (seed.sql)

1. Crea una nueva query en el SQL Editor
2. Copia y pega el contenido completo de: [`supabase/seed.sql`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/supabase/seed.sql)
3. Haz clic en **"Run"**

**Qué crea este script:**
- 4 empleados de ejemplo
- 3 proyectos de ejemplo
- 3 islas de ejemplo con tokens
- Festivos para el año actual

> 💡 **Tip**: Si no ejecutas este script, deberás crear empleados, proyectos e islas manualmente desde el panel admin.

---

### 3. Generar Festivos Colombianos

Ejecuta el siguiente comando SQL para generar los festivos de 2026 y 2027:

```sql
-- Generar festivos para 2026
SELECT fn_generate_holidays(2026);

-- Generar festivos para 2027
SELECT fn_generate_holidays(2027);
```

Deberías ver un resultado como:
```
fn_generate_holidays
--------------------
18
```

Esto significa que se crearon 18 festivos colombianos para cada año.

---

### 4. Crear Usuario Administrador

1. En el dashboard de Supabase, ve a **Authentication** > **Users**
2. Haz clic en **"Add user"** > **"Create new user"**
3. Ingresa:
   - **Email**: Tu correo de administrador (ej: `admin@empresa.com`)
   - **Password**: Una contraseña segura
4. Haz clic en **"Create user"**

Este usuario podrá acceder al panel administrativo en `/admin/login`

---

### 5. Verificar la Configuración

#### Verificar Tablas Creadas

En el SQL Editor, ejecuta:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

Deberías ver:
- `employees`
- `holidays`
- `islands`
- `projects`
- `time_records`

#### Verificar Funciones Creadas

```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;
```

Deberías ver:
- `fn_calculate_hours`
- `fn_check_active_shift`
- `fn_generate_holidays`
- `fn_is_holiday`

#### Verificar Datos de Prueba (si ejecutaste seed.sql)

```sql
-- Ver empleados
SELECT cedula, full_name, status FROM employees;

-- Ver proyectos
SELECT code, name, status FROM projects;

-- Ver islas y sus tokens
SELECT name, token, status FROM islands;

-- Ver festivos
SELECT date, name FROM holidays WHERE year = 2026 ORDER BY date;
```

---

## 🚀 Siguiente Paso: Ejecutar la Aplicación

Una vez completados todos los pasos anteriores:

```bash
cd /Users/yangojukopila/Documents/seguimientoHorasHombreApp
npm start
```

La aplicación estará disponible en: `http://localhost:4200`

### Probar el Kiosk

1. Ve a `http://localhost:4200/kiosk/activate`
2. Ingresa uno de los tokens de las islas (si ejecutaste seed.sql):
   - `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
   - `b2c3d4e5-f6a7-8901-bcde-f12345678901`
3. Ingresa una cédula de empleado (si ejecutaste seed.sql):
   - `1234567890` (Juan Pérez García)
   - `0987654321` (María López Rodríguez)
4. Selecciona un proyecto
5. Haz clic en "Registrar"

### Probar el Admin

1. Ve a `http://localhost:4200/admin/login`
2. Ingresa las credenciales del usuario que creaste en Supabase
3. Deberías ver el dashboard con estadísticas

---

## ❓ Solución de Problemas

### Error: "relation 'employees' does not exist"
- **Causa**: No se ejecutó el script `schema.sql`
- **Solución**: Ejecuta el script `schema.sql` en el SQL Editor

### Error: "function fn_calculate_hours does not exist"
- **Causa**: No se ejecutó el script `functions.sql`
- **Solución**: Ejecuta el script `functions.sql` en el SQL Editor

### Error: "Token inválido" en el kiosk
- **Causa**: El token no existe en la tabla `islands` o la isla está inactiva
- **Solución**: Ejecuta `seed.sql` o crea una isla manualmente

### No puedo hacer login en el admin
- **Causa**: No se creó el usuario en Supabase Auth
- **Solución**: Ve a Authentication > Users y crea un usuario

---

## 📊 Estructura de la Base de Datos

```
┌─────────────┐
│  employees  │ ─┐
└─────────────┘  │
                 │
┌─────────────┐  │    ┌──────────────┐
│  projects   │ ─┼───→│ time_records │
└─────────────┘  │    └──────────────┘
                 │           ↓
┌─────────────┐  │    (trigger auto-calcula horas)
│   islands   │ ─┘
└─────────────┘

┌─────────────┐
│  holidays   │ (usado por fn_calculate_hours)
└─────────────┘
```

---

¡Configuración completa! 🎉
