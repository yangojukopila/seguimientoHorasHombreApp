# 🚀 Inicio Rápido - Horas-CMK-CIC

## ✅ Estado Actual

- ✅ Credenciales de Supabase configuradas
- ✅ Servidor de desarrollo corriendo en `http://localhost:4200`
- ⏳ **Falta**: Ejecutar script SQL en Supabase

---

## 📋 Próximo Paso: Configurar Base de Datos

### Opción 1: Script Consolidado (Recomendado - Más Rápido)

1. **Abre Supabase**:
   - Ve a: https://supabase.com/dashboard/project/nfqaifxkmhnwunehpnwi
   - Click en **SQL Editor** en el menú lateral

2. **Ejecuta el script completo**:
   - Click en **"+ New query"**
   - Copia y pega TODO el contenido de: [`supabase/setup-completo.sql`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/supabase/setup-completo.sql)
   - Click en **"Run"** (o `Ctrl/Cmd + Enter`)
   - Espera ~10 segundos

3. **Verifica el resultado**:
   - Deberías ver al final:
     ```
     Tablas creadas: 5
     Funciones creadas: 4
     Empleados: 3
     Proyectos: 3
     Islas: 2
     Festivos 2026: 6
     ```

### Opción 2: Scripts Individuales (Paso a Paso)

Si prefieres ejecutar los scripts por separado, sigue la guía detallada en: [`SETUP_SUPABASE.md`](file:///Users/yangojukopila/Documents/seguimientoHorasHombreApp/SETUP_SUPABASE.md)

---

## 🔐 Crear Usuario Administrador

Después de ejecutar el script SQL:

1. En Supabase, ve a **Authentication** > **Users**
2. Click en **"Add user"** > **"Create new user"**
3. Ingresa:
   - **Email**: `admin@empresa.com` (o el que prefieras)
   - **Password**: Una contraseña segura
4. Click en **"Create user"**

---

## 🧪 Probar la Aplicación

### 1. Probar el Kiosk

La aplicación ya está corriendo en: **http://localhost:4200**

1. **Activar Isla**:
   - Ve a: http://localhost:4200/kiosk/activate
   - Ingresa el token: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
   - Click en "Activar Isla"

2. **Registrar Entrada**:
   - Ingresa cédula: `1234567890` (Juan Pérez García)
   - Selecciona proyecto: `PRJ-001 - Estructura Metálica`
   - Click en "Registrar"
   - Deberías ver: **"¡Bienvenido, Juan Pérez García!"**

3. **Registrar Salida**:
   - Ingresa la misma cédula: `1234567890`
   - Click en "Registrar"
   - Deberías ver: **"¡Hasta luego, Juan Pérez García!"**

### 2. Probar el Admin

1. **Login**:
   - Ve a: http://localhost:4200/admin/login
   - Ingresa las credenciales del usuario que creaste
   - Click en "Iniciar Sesión"

2. **Dashboard**:
   - Deberías ver:
     - 3 Empleados Activos
     - 3 Proyectos Activos
     - Registros de hoy (si hiciste check-in/out)
     - Desglose de horas

---

## 📊 Datos de Prueba Incluidos

### Empleados
- **1234567890** - Juan Pérez García (Soldador)
- **0987654321** - María López Rodríguez (Operario de Torno)
- **1122334455** - Carlos Martínez Silva (Fresador)

### Proyectos
- **PRJ-001** - Estructura Metálica Edificio Central
- **PRJ-002** - Tanques de Almacenamiento
- **PRJ-003** - Escaleras Industriales

### Tokens de Islas
- **Isla Taller Principal**: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
- **Isla Área de Soldadura**: `b2c3d4e5-f6a7-8901-bcde-f12345678901`

---

## ❓ Solución de Problemas

### "Error de conexión a Supabase"
- ✅ Verifica que ejecutaste el script SQL en Supabase
- ✅ Verifica que las credenciales en `environment.ts` son correctas

### "Token inválido" en el kiosk
- ✅ Ejecuta el script `setup-completo.sql` que crea las islas
- ✅ O copia exactamente el token: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### "Empleado no encontrado"
- ✅ Ejecuta el script `setup-completo.sql` que crea los empleados
- ✅ O usa la cédula exacta: `1234567890`

### No puedo hacer login en admin
- ✅ Crea el usuario en Supabase: Authentication > Users > Add user

---

## 📱 URLs de la Aplicación

- **Kiosk - Activar Isla**: http://localhost:4200/kiosk/activate
- **Kiosk - Check-in/out**: http://localhost:4200/kiosk/checkin
- **Admin - Login**: http://localhost:4200/admin/login
- **Admin - Dashboard**: http://localhost:4200/admin/dashboard

---

## 🎯 Siguiente Paso

**👉 Ejecuta el script SQL en Supabase y prueba la aplicación!**

Una vez que funcione, podemos continuar con:
- Crear más empleados y proyectos
- Configurar más islas
- Desarrollar las interfaces CRUD completas
- Implementar reportes avanzados

---

**¿Listo?** Ejecuta el script SQL y avísame si tienes algún problema! 🚀
