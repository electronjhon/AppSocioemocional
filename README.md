# App Socioemocional

Aplicación de monitoreo emocional con almacenamiento local y sincronización en la nube.

## Características

### ✅ Funcionalidades Implementadas
- **Autenticación**: Login y registro con Firebase Auth
- **Roles**: Estudiantes y Docentes
- **Registro de Emociones**: 5 tipos de emociones (Feliz, Triste, Enojado, Ansioso, Calmado)
- **Almacenamiento Local**: SQLite para guardar datos sin conexión
- **Sincronización**: Sincronización automática cuando hay conexión
- **Exportación**: Exportar datos a Google Drive en formato CSV y JSON
- **Visualización**: Gráficos circulares y historial de emociones
- **Modo Offline**: Funciona completamente sin conexión a internet

### 🔧 Nuevas Funcionalidades

#### Almacenamiento Local
- Los registros de emociones se guardan localmente en SQLite
- Funciona sin conexión a internet
- Sincronización automática cuando se restaura la conexión
- Indicador visual del estado de sincronización

#### Exportación a Google Drive
- Exportar datos en formato CSV (para análisis en Excel)
- Exportar datos en formato JSON (para respaldo completo)
- Autenticación con Google Sign-In
- Archivos organizados por usuario y fecha

#### Gestión de Datos
- Eliminar registros individuales
- Visualización de estadísticas locales
- Indicadores de estado de sincronización
- Manejo de errores robusto

## Configuración

### 1. Firebase Setup
```bash
# Instalar dependencias
flutter pub get

# Configurar Firebase (si no está configurado)
flutterfire configure
```

### 2. Google Drive API Setup

#### Para Android:
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita la Google Drive API
4. Crea credenciales OAuth 2.0
5. Descarga el archivo `google-services.json` y colócalo en `android/app/`
6. Actualiza `android/app/src/main/res/values/strings.xml` con tu Web Client ID

#### Para iOS:
1. Configura las credenciales en `ios/Runner/Info.plist`
2. Agrega el URL Scheme para Google Sign-In

### 3. Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Uso

### Para Estudiantes:
1. **Registro**: Crear cuenta con documento, email y contraseña
2. **Registrar Emociones**: Seleccionar emoción y guardar
3. **Ver Historial**: Gráficos y lista de emociones registradas
4. **Exportar**: Conectar con Google Drive y exportar datos
5. **Sincronizar**: Los datos se sincronizan automáticamente

### Para Docentes:
1. **Ver Estudiantes**: Lista de estudiantes por curso
2. **Monitorear**: Ver emociones de cada estudiante
3. **Análisis**: Gráficos y estadísticas por estudiante

## Estructura de Datos

### Base de Datos Local (SQLite)
```sql
CREATE TABLE emotions (
  id TEXT PRIMARY KEY,
  studentUid TEXT NOT NULL,
  emotion TEXT NOT NULL,
  note TEXT,
  createdAt INTEGER NOT NULL,
  dayKey TEXT NOT NULL,
  isSynced INTEGER NOT NULL DEFAULT 0
);
```

### Firebase Collections
- `users`: Perfiles de usuarios
- `documents_index`: Índice para login por documento
- `students/{uid}/emotions`: Emociones sincronizadas

## Ventajas del Sistema Híbrido

### 🚀 Rendimiento
- Acceso instantáneo a datos locales
- Menos dependencia de la conexión
- Reducción de costos de Firebase

### 💾 Ahorro de Almacenamiento
- Solo se sincronizan datos nuevos
- Eliminación de duplicados automática
- Control granular de sincronización

### 🔄 Experiencia de Usuario
- Funciona offline
- Sincronización transparente
- Indicadores de estado claros

## Desarrollo

### Comandos Útiles
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Construir APK
flutter build apk

# Limpiar cache
flutter clean
```

### Estructura del Proyecto
```
lib/
├── models/
│   ├── app_user.dart
│   └── emotion_record.dart
├── services/
│   ├── auth_service.dart
│   ├── emotion_service.dart
│   ├── local_database_service.dart
│   ├── google_drive_service.dart
│   └── connectivity_service.dart
├── providers/
│   └── session_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── splash_screen.dart
│   ├── student/
│   │   └── student_home_screen.dart
│   └── teacher/
│       └── teacher_home_screen.dart
└── widgets/
    ├── gradient_background.dart
    ├── sync_status_widget.dart
    └── export_widget.dart
```

## Próximas Mejoras

- [ ] Notificaciones push para recordatorios
- [ ] Análisis de tendencias temporales
- [ ] Reportes avanzados para docentes
- [ ] Configuración de cursos dinámica
- [ ] Backup automático programado
- [ ] Modo oscuro
- [ ] Múltiples idiomas

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.
