# Horas-CMK-CIC

Sistema de registro, análisis y control de horas hombre para empresa metalmecánica.

## 🎯 Descripción

Aplicación web completa para el seguimiento de horas trabajadas por el personal operativo, con clasificación automática según la legislación laboral colombiana.

### Características Principales

- ✅ **Registro de Asistencia vía Islas (Kioscos)**: Tablets o PCs sin autenticación
- ⚙️ **Clasificación Automática de Horas**: 6 categorías según horario y día
- 👥 **Gestión de Empleados y Proyectos**: Panel administrativo completo
- 📊 **Reportes y Exportación**: Excel/CSV con filtros avanzados
- 🎨 **UI/UX Premium**: Diseño corporativo moderno y responsivo

## 🛠️ Stack Tecnológico

- **Frontend**: Angular 18
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Estilos**: SCSS con sistema de diseño personalizado
- **Librerías**: date-fns, xlsx, @supabase/supabase-js

## 📋 Requisitos Previos

- Node.js v20.17.0 o superior
- npm 10.8.2 o superior
- Cuenta de Supabase (gratuita)

## 🚀 Configuración Inicial

### 1. Clonar e Instalar Dependencias

```bash
cd seguimientoHorasHombreApp
npm install
```

### 2. Configurar Supabase

#### a) Crear Proyecto en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. Guarda la URL del proyecto y la clave anónima (anon key)

#### b) Ejecutar Scripts de Base de Datos

En el editor SQL de Supabase, ejecuta en orden:

1. **Schema**: `supabase/schema.sql`
2. **Functions**: `supabase/functions.sql`
3. **RLS Policies**: `supabase/rls.sql`
4. **Seed Data** (opcional): `supabase/seed.sql`

#### c) Generar Festivos Colombianos

En el editor SQL de Supabase:

```sql
SELECT fn_generate_holidays(2026);
SELECT fn_generate_holidays(2027);
```

#### d) Crear Usuario Administrador

En la sección Authentication > Users de Supabase:

1. Click en "Add user" > "Create new user"
2. Ingresa email y contraseña
3. Este usuario tendrá acceso al panel administrativo

### 3. Configurar Variables de Entorno

Edita `src/environments/environment.ts`:

```typescript
export const environment = {
  production: false,
  supabase: {
    url: 'https://tu-proyecto.supabase.co',
    anonKey: 'tu-clave-anonima-aqui'
  }
};
```

Edita `src/environments/environment.prod.ts` con los mismos valores para producción.

## 🎮 Ejecutar la Aplicación

### Modo Desarrollo

```bash
npm start
```

La aplicación estará disponible en `http://localhost:4200`

### Build de Producción

```bash
npm run build
```

Los archivos compilados estarán en `dist/`

## 📱 Uso del Sistema

### Configuración de Islas (Kioscos)

1. Inicia sesión como administrador en `/admin/login`
2. Ve a "Islas" en el menú
3. Crea una nueva isla
4. Copia el token generado
5. En la tablet/PC del kiosko:
   - Abre `http://tu-dominio/kiosk`
   - Ingresa el token
   - La isla queda activada

### Registro de Empleados

Los empleados solo necesitan:

1. Acercarse a cualquier isla activa
2. Ingresar su cédula (solo números)
3. Seleccionar el proyecto
4. Presionar "Registrar"

- **Primera vez del día**: Registra entrada
- **Segunda vez**: Registra salida automáticamente

### Panel Administrativo

Accede a `/admin/login` con las credenciales de Supabase.

**Funcionalidades:**

- **Dashboard**: Métricas en tiempo real
- **Empleados**: CRUD completo, activar/desactivar
- **Proyectos**: CRUD completo, cerrar/reabrir
- **Islas**: Crear, regenerar tokens, ver actividad
- **Reportes**: Filtros por fecha, empleado, proyecto, exportar Excel/CSV
- **Configuración**: Generar festivos por año

## 🕐 Clasificación de Horas

El sistema clasifica automáticamente las horas en 6 categorías:

### Horario Oficial

**Lunes a Jueves**: 7:00-12:00, 13:00-17:15  
**Viernes**: 7:00-12:00, 13:00-16:00

### Categorías

1. **Ordinaria Diurna**: Horario oficial, día laboral, 6:00-21:00
2. **Ordinaria Nocturna**: Horario oficial, día laboral, 21:00-6:00
3. **Extra Diurna**: Fuera de horario oficial, día laboral, 6:00-21:00
4. **Extra Nocturna**: Fuera de horario oficial, día laboral, 21:00-6:00
5. **Dominical/Festiva Diurna**: Domingo o festivo, 6:00-21:00
6. **Dominical/Festiva Nocturna**: Domingo o festivo, 21:00-6:00

## 🔒 Seguridad

- **Islas**: Solo token, sin acceso a datos administrativos
- **Admin**: Autenticación Supabase con email/contraseña
- **RLS**: Políticas de seguridad a nivel de base de datos
- **Validaciones**: Empleado activo, proyecto activo, turno único

## 📊 Estructura del Proyecto

```
seguimientoHorasHombreApp/
├── src/
│   ├── app/
│   │   ├── core/
│   │   │   ├── guards/          # Auth guard
│   │   │   ├── models/          # TypeScript interfaces
│   │   │   └── services/        # Servicios (Supabase, Auth, Kiosk, etc.)
│   │   ├── kiosk/               # Módulo de islas
│   │   │   ├── activate/        # Activación de isla
│   │   │   └── checkin/         # Check-in/out
│   │   └── admin/               # Módulo administrativo (pendiente)
│   ├── environments/            # Configuración
│   └── styles.scss              # Tema global
├── supabase/
│   ├── schema.sql               # Tablas
│   ├── functions.sql            # Funciones y triggers
│   ├── rls.sql                  # Políticas de seguridad
│   └── seed.sql                 # Datos de prueba
└── README.md
```

## 🎨 Personalización

### Colores Corporativos

Edita las variables CSS en `src/styles.scss`:

```scss
:root {
  --primary-500: #0091ea;  // Color primario
  --accent-600: #00897b;   // Color acento
  // ...
}
```

### Logo

Reemplaza el emoji ⚙️ en los componentes con tu logo corporativo.

## 🐛 Solución de Problemas

### Error: "Token inválido"

- Verifica que el token esté activo en el panel de Islas
- Regenera el token si es necesario

### Error: "Empleado no encontrado"

- Verifica que el empleado esté creado y activo
- Confirma que la cédula sea correcta (solo números)

### Error de conexión a Supabase

- Verifica las credenciales en `environment.ts`
- Confirma que el proyecto de Supabase esté activo

## 📄 Licencia

Proyecto propietario - Todos los derechos reservados

## 👨‍💻 Soporte

Para soporte técnico, contacta al equipo de desarrollo.

---

**Horas-CMK-CIC** - Sistema de Control de Horas Hombre v1.0
