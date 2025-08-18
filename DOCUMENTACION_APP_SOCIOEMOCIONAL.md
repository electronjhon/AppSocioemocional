# Documentación Completa - App Socioemocional

## Descripción General
La App Socioemocional es una aplicación Flutter diseñada para la gestión emocional de estudiantes en la Institución Educativa Departamental Pbro. Carlos Garavito A. La aplicación permite a los estudiantes registrar sus emociones diarias, a los docentes monitorear el estado emocional de sus estudiantes, y a los administradores gestionar usuarios y enviar notificaciones.

## Arquitectura de la Aplicación

### Estructura de Directorios
```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── models/                      # Modelos de datos
├── providers/                   # Proveedores de estado
├── screens/                     # Pantallas de la aplicación
│   ├── admin/                   # Pantallas de administrador
│   ├── student/                 # Pantallas de estudiante
│   └── teacher/                 # Pantallas de docente
├── services/                    # Servicios de negocio
└── widgets/                     # Componentes reutilizables
```

---

## 1. PUNTO DE ENTRADA

### `lib/main.dart`
**Funcionalidad Principal**: Configuración inicial de la aplicación y punto de entrada.

**Líneas Principales**:
- **Líneas 10-17**: Inicialización de Firebase, servicios de conectividad y creación del usuario administrador por defecto
- **Líneas 25-35**: Configuración del tema de la aplicación con Material 3 y Google Fonts
- **Líneas 36-40**: Configuración del SessionProvider para gestión de estado global
- **Línea 42**: Navegación inicial a SplashScreen

---

## 2. MODELOS DE DATOS

### `lib/models/app_user.dart`
**Funcionalidad**: Modelo de datos para usuarios de la aplicación.

**Líneas Principales**:
- **Líneas 1-8**: Definición de propiedades del usuario (uid, documento, email, rol, curso, avatar, nombres)
- **Líneas 20-30**: Método `toMap()` para convertir objeto a Map para Firebase
- **Líneas 32-42**: Constructor `fromMap()` para crear objeto desde datos de Firebase
- **Líneas 44-58**: Método `copyWith()` para crear copias modificadas del objeto

### `lib/models/emotion_record.dart`
**Funcionalidad**: Modelo para registros de emociones de estudiantes.

**Líneas Principales**:
- **Líneas 1-7**: Propiedades del registro (id, estudiante, emoción, nota, fecha, día, sincronización)
- **Líneas 18-26**: Conversión a Map con timestamp en milisegundos
- **Líneas 28-38**: Constructor desde Map con conversión de timestamp
- **Líneas 40-52**: Método copyWith para modificaciones

### `lib/models/notification_message.dart`
**Funcionalidad**: Modelo para mensajes de notificación (píldoras).

**Líneas Principales**:
- **Líneas 1-11**: Propiedades del mensaje (id, título, mensaje, URL, remitente, destinatarios)
- **Líneas 23-35**: Conversión a Map con arrays de roles y cursos objetivo
- **Líneas 37-50**: Constructor desde Map con manejo de arrays y booleanos
- **Líneas 52-70**: Método copyWith para modificaciones

---

## 3. PROVEEDORES DE ESTADO

### `lib/providers/session_provider.dart`
**Funcionalidad**: Gestión global del estado de sesión del usuario.

**Líneas Principales**:
- **Líneas 8-12**: Propiedades privadas para usuario actual y estado de inicialización
- **Líneas 18-35**: Listener de cambios de autenticación de Firebase
- **Líneas 37-40**: Getters públicos para acceder al estado
- **Líneas 42-50**: Métodos para limpiar sesión manualmente
- **Líneas 52-60**: Métodos para manejo de cierre de sesión
- **Líneas 62-68**: Restauración del listener después del cierre

---

## 4. SERVICIOS DE NEGOCIO

### `lib/services/auth_service.dart`
**Funcionalidad**: Gestión de autenticación y usuarios.

**Líneas Principales**:
- **Líneas 8-9**: Instancias de Firebase Auth y Firestore
- **Líneas 15-19**: Obtener perfil de usuario por UID
- **Líneas 21-40**: Registro de usuarios con validación de documento único
- **Líneas 42-55**: Login por documento y contraseña usando índice auxiliar
- **Líneas 57-70**: Cierre de sesión con manejo de errores
- **Líneas 72-85**: Búsqueda de usuario por número de documento
- **Líneas 87-95**: Obtener todos los usuarios del sistema
- **Líneas 97-105**: Actualización de datos de usuario
- **Líneas 107-125**: Actualización de contraseña (requiere Admin SDK)
- **Líneas 127-135**: Eliminación de usuario
- **Líneas 137-155**: Eliminación de emociones de un usuario específico
- **Líneas 157-185**: Eliminación de todas las emociones del sistema
- **Líneas 187-215**: Creación de usuario por administrador
- **Líneas 217-230**: Verificación de rol de administrador
- **Líneas 232-260**: Creación automática del usuario administrador por defecto

### `lib/services/emotion_service.dart`
**Funcionalidad**: Gestión de registros de emociones con sincronización offline/online.

**Líneas Principales**:
- **Líneas 8-10**: Instancias de servicios necesarios
- **Líneas 12-35**: Registro de emoción con validación de límite diario (3 por día)
- **Líneas 37-55**: Sincronización de emoción a Firebase
- **Líneas 57-65**: Sincronización de todas las emociones no sincronizadas
- **Líneas 67-105**: Stream que combina datos locales y de Firebase
- **Líneas 107-155**: Eliminación de emoción con múltiples estrategias de fallback
- **Líneas 157-165**: Obtención de estadísticas locales
- **Líneas 167-175**: Conteo de emociones locales
- **Líneas 177-185**: Obtención de emociones locales
- **Líneas 187-195**: Eliminación de emoción local
- **Líneas 197-201**: Limpieza de todas las emociones locales
- **Líneas 203-207**: Stream de estudiantes por curso
- **Líneas 209-217**: Verificación de emociones no sincronizadas
- **Líneas 219-223**: Obtención de emociones no sincronizadas
- **Líneas 225-230**: Verificación de límite diario de emociones
- **Líneas 232-236**: Conteo de emociones del día actual

### `lib/services/notification_service.dart`
**Funcionalidad**: Gestión de notificaciones (píldoras) del sistema.

**Líneas Principales**:
- **Líneas 8-10**: Instancias de servicios necesarios
- **Líneas 12-45**: Envío de notificación con distribución automática
- **Líneas 47-85**: Distribución de notificación a usuarios objetivo
- **Líneas 87-95**: Stream de notificaciones del usuario en tiempo real
- **Líneas 97-110**: Obtención de notificaciones no leídas
- **Líneas 112-125**: Conteo de notificaciones no leídas
- **Líneas 127-150**: Marcado de notificación como leída
- **Líneas 152-175**: Marcado de todas las notificaciones como leídas
- **Líneas 177-190**: Eliminación de notificación de usuario
- **Líneas 192-220**: Eliminación de notificación del historial global
- **Líneas 222-260**: Eliminación de todas las notificaciones enviadas
- **Líneas 262-300**: Obtención de notificaciones enviadas por administrador
- **Líneas 302-310**: Verificación de disponibilidad de navegador
- **Líneas 312-350**: Apertura de URL con múltiples intentos
- **Líneas 352-375**: Obtención de estadísticas de notificaciones

### `lib/services/local_database_service.dart`
**Funcionalidad**: Base de datos local SQLite para almacenamiento offline.

**Líneas Principales**:
- **Líneas 4-5**: Variables estáticas para instancia de base de datos
- **Líneas 7-11**: Getter para obtener instancia de base de datos
- **Líneas 13-20**: Inicialización de la base de datos
- **Líneas 22-35**: Creación de tabla con índices para rendimiento
- **Líneas 37-46**: Inserción de emoción con ID único
- **Líneas 48-56**: Obtención de emociones por estudiante
- **Líneas 58-66**: Obtención de emociones no sincronizadas
- **Líneas 68-75**: Marcado de emoción como sincronizada
- **Líneas 77-84**: Actualización de ID de emoción
- **Líneas 86-93**: Eliminación de emoción por ID
- **Líneas 95-102**: Eliminación por timestamp
- **Líneas 104-115**: Eliminación por múltiples criterios
- **Líneas 117-120**: Limpieza de todas las emociones
- **Líneas 122-129**: Conteo de emociones por estudiante
- **Líneas 131-142**: Estadísticas de emociones por tipo
- **Líneas 144-151**: Conteo de emociones por día

### `lib/services/whatsapp_service.dart`
**Funcionalidad**: Integración con WhatsApp para contacto de soporte.

**Líneas Principales**:
- **Líneas 3-4**: Constantes para configuración de número
- **Líneas 6-10**: Obtención del número configurado
- **Líneas 12-20**: Configuración del número de WhatsApp
- **Líneas 22-65**: Envío de mensaje con información del usuario
- **Líneas 67-71**: Validación de formato de número telefónico
- **Líneas 73-85**: Formateo de número para mostrar

---

## 5. PANTALLAS PRINCIPALES

### `lib/screens/splash_screen.dart`
**Funcionalidad**: Pantalla de carga inicial con verificación de autenticación.

**Líneas Principales**:
- **Líneas 25-27**: Delay de 2 segundos para mostrar splash
- **Líneas 35-45**: Espera de inicialización del SessionProvider
- **Líneas 47-55**: Verificación de autenticación
- **Líneas 57-75**: Navegación según rol del usuario
- **Líneas 77-85**: Navegación a login si no está autenticado
- **Líneas 87-130**: UI del splash con logo y información de la institución

### `lib/screens/login_screen.dart`
**Funcionalidad**: Pantalla de inicio de sesión.

**Líneas Principales**:
- **Líneas 18-25**: Controladores de formulario y estado
- **Líneas 27-32**: Limpieza de controladores
- **Líneas 34-55**: Proceso de login con manejo de errores
- **Líneas 57-75**: UI del formulario de login
- **Líneas 77-95**: Campo de documento con validación
- **Líneas 97-120**: Campo de contraseña con toggle de visibilidad
- **Líneas 122-140**: Botón de login con estado de carga
- **Líneas 142-150**: Enlace para registro

### `lib/screens/register_screen.dart`
**Funcionalidad**: Pantalla de registro de nuevos usuarios.

**Líneas Principales**:
- **Líneas 7-9**: Assets de avatares disponibles
- **Líneas 20-30**: Controladores de formulario y estado
- **Líneas 32-40**: Limpieza de controladores
- **Líneas 42-65**: Proceso de registro con validaciones
- **Líneas 67-85**: UI del formulario de registro
- **Líneas 87-105**: Campos de información personal
- **Líneas 107-130**: Validación de documento (8+ dígitos, solo números)
- **Líneas 132-150**: Validación de email con regex
- **Líneas 152-185**: Validación de contraseña (letras + números)
- **Líneas 187-205**: Confirmación de contraseña
- **Líneas 207-225**: Selección de rol (estudiante/docente)
- **Líneas 227-260**: Selección de avatar con preview
- **Líneas 262-275**: Botón de registro con estado de carga

### `lib/screens/notifications_screen.dart`
**Funcionalidad**: Pantalla de visualización de notificaciones (píldoras).

**Líneas Principales**:
- **Líneas 25-50**: Marcado de todas las notificaciones como leídas
- **Líneas 52-70**: Marcado de notificación individual como leída
- **Líneas 72-120**: Apertura de URL con múltiples intentos
- **Líneas 122-200**: Diálogo de error para URLs que no se pueden abrir
- **Líneas 202-250**: Manejo de acciones del diálogo (copiar, reintentar, etc.)
- **Líneas 252-280**: UI de la pantalla con AppBar
- **Líneas 282-320**: Stream de notificaciones en tiempo real
- **Líneas 322-350**: Estado vacío cuando no hay notificaciones
- **Líneas 352-450**: Lista de notificaciones con diseño diferenciado
- **Líneas 452-475**: Menú contextual para acciones de notificación

### `lib/screens/student/student_home_screen.dart`
**Funcionalidad**: Pantalla principal del estudiante para registro de emociones.

**Líneas Principales**:
- **Líneas 25-30**: Lista de emociones disponibles y estado
- **Líneas 32-35**: Servicios y controladores
- **Líneas 37-42**: Inicialización y carga de datos
- **Líneas 44-75**: Listener de notificaciones con toast automático
- **Líneas 77-90**: Carga del conteo de emociones del día
- **Líneas 92-120**: UI principal con AppBar y drawer
- **Líneas 122-150**: Contador de emociones del día (máximo 3)
- **Líneas 152-180**: Botones de selección de emociones
- **Líneas 182-220**: Campo de nota opcional
- **Líneas 222-240**: Mensaje de límite alcanzado
- **Líneas 242-280**: Botón de registro de emoción
- **Líneas 282-320**: Sección de resumen con gráfica circular
- **Líneas 322-400**: Gráfica de distribución de emociones
- **Líneas 402-450**: Lista de registros recientes
- **Líneas 452-480**: Colores e iconos para cada emoción

### `lib/screens/admin/admin_home_screen.dart`
**Funcionalidad**: Panel de administración principal.

**Líneas Principales**:
- **Líneas 18-20**: Instancia del servicio de autenticación
- **Líneas 22-50**: Eliminación de todas las emociones del sistema
- **Líneas 52-100**: Proceso de cierre de sesión
- **Líneas 102-130**: UI del AppBar con avatar del administrador
- **Líneas 132-160**: Header con información del administrador
- **Líneas 162-200**: Grid de acciones administrativas
- **Líneas 202-240**: Tarjetas de acción (agregar usuario, gestionar usuarios)
- **Líneas 242-280**: Tarjetas de acción (eliminar registros, enviar píldoras)
- **Líneas 282-320**: Tarjetas de acción (historial, configuración WhatsApp)
- **Líneas 322-360**: Método para construir tarjetas de acción

---

## 6. WIDGETS REUTILIZABLES

### `lib/widgets/app_drawer.dart`
**Funcionalidad**: Menú lateral con navegación y funcionalidades.

**Líneas Principales**:
- **Líneas 20-25**: Estado de conectividad y sincronización
- **Líneas 27-40**: Verificación de estado de servicios
- **Líneas 42-80**: Exportación a Google Drive (CSV/JSON)
- **Líneas 82-150**: Diálogo de contacto por WhatsApp
- **Líneas 152-200**: Proceso de cierre de sesión
- **Líneas 202-250**: Header del drawer con información del usuario
- **Líneas 252-280**: Indicador de estado de conexión
- **Líneas 282-320**: Enlaces de navegación (historial, píldoras)
- **Líneas 322-360**: Integración con WhatsApp
- **Líneas 362-420**: Sección de Google Drive con exportación
- **Líneas 422-450**: Botón de cierre de sesión

---

## 7. CARACTERÍSTICAS TÉCNICAS

### Funcionalidades Principales

1. **Autenticación Multi-rol**:
   - Estudiantes: Registro de emociones diarias
   - Docentes: Monitoreo de estudiantes
   - Administradores: Gestión completa del sistema

2. **Sincronización Offline/Online**:
   - Base de datos local SQLite para funcionamiento sin conexión
   - Sincronización automática cuando hay conexión
   - Límite de 3 emociones por día por estudiante

3. **Sistema de Notificaciones**:
   - Píldoras enviadas por administradores
   - Distribución por roles y cursos
   - URLs opcionales para recursos externos

4. **Integración Externa**:
   - WhatsApp para soporte técnico
   - Google Drive para exportación de datos
   - Firebase para backend en la nube

5. **Gestión de Datos**:
   - Exportación en formatos CSV y JSON
   - Eliminación masiva de registros
   - Estadísticas y gráficas de emociones

### Tecnologías Utilizadas

- **Frontend**: Flutter con Material Design 3
- **Backend**: Firebase (Auth, Firestore)
- **Base de Datos Local**: SQLite con sqflite
- **Estado Global**: Provider pattern
- **Gráficas**: fl_chart
- **Integración**: url_launcher, shared_preferences

### Patrones de Diseño

1. **Provider Pattern**: Para gestión de estado global
2. **Service Layer**: Separación de lógica de negocio
3. **Repository Pattern**: Abstracción de fuentes de datos
4. **Observer Pattern**: Streams para datos en tiempo real
5. **Factory Pattern**: Creación de modelos desde datos

### Consideraciones de Seguridad

- Validación de entrada en formularios
- Autenticación por Firebase Auth
- Reglas de Firestore para acceso a datos
- Límites de uso (3 emociones por día)
- Validación de roles para acciones administrativas

---

## 8. FLUJO DE USUARIO

### Estudiante
1. Login con documento y contraseña
2. Registro de emociones (máximo 3 por día)
3. Visualización de historial personal
4. Recepción de píldoras de administradores
5. Contacto por WhatsApp para soporte

### Docente
1. Login con credenciales
2. Monitoreo de estudiantes del curso
3. Visualización de estadísticas
4. Recepción de píldoras

### Administrador
1. Login con credenciales especiales
2. Gestión de usuarios (crear, editar, eliminar)
3. Envío de píldoras a usuarios específicos
4. Configuración del sistema
5. Exportación y eliminación de datos

---

Esta documentación proporciona una visión completa de la arquitectura y funcionalidad de la App Socioemocional, facilitando el mantenimiento y desarrollo futuro del sistema.
