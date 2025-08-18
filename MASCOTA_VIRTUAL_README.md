# 🐾 Mascota Virtual - App Socioemocional

## Descripción

La **Mascota Virtual** es una nueva funcionalidad agregada a la pantalla del estudiante que reemplaza los "Registros Recientes" con una mascota interactiva que reacciona según el estado emocional predominante del estudiante.

## 🎯 Características

### Comportamiento Adaptativo
La mascota cambia su apariencia y comportamiento según la emoción más frecuente registrada por el estudiante:

- **🎨 Color**: Cambia según la emoción dominante
- **😊 Expresión**: Boca y ojos que reflejan el estado emocional
- **🎭 Detalles**: Elementos adicionales como lágrimas, cejas, orejas, etc.
- **🏃 Animaciones**: Movimiento y ritmo adaptado a cada emoción

### Estados Emocionales

#### 😊 **Feliz** (Naranja)
- **Color**: Naranja vibrante
- **Boca**: Sonrisa amplia hacia arriba
- **Detalles**: Orejas puntiagudas felices
- **Animación**: Rebote frecuente (cada 3 segundos)
- **Mensaje**: "¡Estoy muy feliz de verte! 😊"

#### 😢 **Triste** (Azul)
- **Color**: Azul suave
- **Boca**: Boca triste hacia abajo
- **Detalles**: Lágrimas en los ojos
- **Animación**: Rebote lento (cada 8 segundos)
- **Mensaje**: "Estoy aquí para acompañarte... 💙"

#### 😠 **Enojado** (Rojo)
- **Color**: Rojo intenso
- **Boca**: Boca pequeña y tensa
- **Detalles**: Cejas fruncidas
- **Animación**: Rebote agitado (cada 2 segundos)
- **Mensaje**: "Respira profundo... 😤"

#### 😰 **Ansioso** (Púrpura)
- **Color**: Púrpura
- **Boca**: Boca circular (como sorprendido)
- **Detalles**: Gotas de sudor
- **Animación**: Rebote irregular (cada 1 segundo)
- **Mensaje**: "Tranquilo, todo estará bien... 😰"

#### 😌 **Calmado** (Verde)
- **Color**: Verde relajante
- **Boca**: Boca pequeña y serena
- **Detalles**: Sin elementos adicionales
- **Animación**: Rebote suave (cada 6 segundos)
- **Mensaje**: "Me siento muy tranquilo contigo 😌"

## 🔧 Implementación Técnica

### Widget Principal: `VirtualPet`

```dart
class VirtualPet extends StatefulWidget {
  final String dominantEmotion;  // Emoción predominante
  final int totalEmotions;       // Total de registros
  
  const VirtualPet({
    super.key,
    required this.dominantEmotion,
    required this.totalEmotions,
  });
}
```

### Animaciones Implementadas

#### 1. **Respiración Continua**
- Escala suave entre 0.95 y 1.05
- Duración: 2 segundos por ciclo
- Efecto: La mascota "respira" constantemente

#### 2. **Parpadeo Ocasional**
- Los ojos se cierran y abren
- Frecuencia: Cada 2-6 segundos (aleatorio)
- Duración: 200ms por parpadeo

#### 3. **Rebote Emocional**
- Frecuencia adaptada a cada emoción:
  - Feliz: Cada 3 segundos
  - Enojado: Cada 2 segundos
  - Ansioso: Cada 1 segundo
  - Triste: Cada 8 segundos
  - Calmado: Cada 6 segundos

### Cálculo de Emoción Dominante

```dart
String _getDominantEmotion(List<EmotionRecord> emotions) {
  if (emotions.isEmpty) return 'calmado';
  
  // Contar cada emoción
  Map<String, int> emotionCounts = {};
  for (final emotion in emotions) {
    emotionCounts[emotion.emotion] = (emotionCounts[emotion.emotion] ?? 0) + 1;
  }
  
  // Encontrar la emoción más frecuente
  String dominantEmotion = 'calmado';
  int maxCount = 0;
  
  emotionCounts.forEach((emotion, count) {
    if (count > maxCount) {
      maxCount = count;
      dominantEmotion = emotion;
    }
  });
  
  return dominantEmotion;
}
```

## 🎨 Diseño Visual

### Estructura de la Mascota
```
┌─────────────────┐
│     Orejas      │ (solo si está feliz)
├─────────────────┤
│  Ojo    Ojo     │
│                 │
│      Boca       │
└─────────────────┘
```

### Elementos Visuales
- **Cuerpo**: Círculo con gradiente radial
- **Ojos**: Círculos blancos con pupilas negras
- **Boca**: Formas geométricas según la emoción
- **Detalles**: Elementos adicionales posicionados

### Efectos Visuales
- **Sombra**: Sombra suave del color de la emoción
- **Gradiente**: Gradiente radial para profundidad
- **Animaciones**: Transiciones suaves entre estados

## 📱 Integración en la App

### Ubicación
- **Pantalla**: `StudentHomeScreen`
- **Sección**: Reemplaza "Registros Recientes"
- **Título**: "Tu Mascota Virtual"

### Información Mostrada
- Mascota virtual animada
- Mensaje personalizado según la emoción
- Contador total de registros emocionales

## 🚀 Beneficios Educativos

### 1. **Gamificación**
- Hace el registro de emociones más atractivo
- Crea una conexión emocional con la app
- Motiva a los estudiantes a registrar más emociones

### 2. **Reflexión Emocional**
- Visualización inmediata del estado emocional
- Feedback visual del patrón emocional
- Fomenta la autoconciencia emocional

### 3. **Acompañamiento**
- La mascota actúa como compañero virtual
- Mensajes de apoyo y comprensión
- Reduce la sensación de soledad

### 4. **Motivación**
- Los estudiantes quieren "cuidar" de su mascota
- Registran emociones para ver cambios
- Crean una rutina de autoconocimiento

## 🔮 Futuras Mejoras

### Funcionalidades Planificadas
1. **Interacción Táctil**: Tocar la mascota para diferentes reacciones
2. **Sonidos**: Efectos de sonido según la emoción
3. **Evolución**: La mascota cambia de forma con el tiempo
4. **Logros**: Desbloqueo de nuevas mascotas
5. **Personalización**: Diferentes tipos de mascotas
6. **Compartir**: Enviar capturas de la mascota

### Mejoras Técnicas
1. **Optimización**: Reducir el uso de memoria
2. **Animaciones**: Más fluidas y naturales
3. **Responsive**: Adaptación a diferentes tamaños
4. **Accesibilidad**: Soporte para lectores de pantalla

## 📊 Métricas de Uso

### Indicadores a Monitorear
- Tiempo de interacción con la mascota
- Frecuencia de registro de emociones
- Cambios en el estado emocional dominante
- Engagement general de los estudiantes

### Objetivos
- Aumentar el registro de emociones en un 30%
- Mejorar la retención de usuarios
- Fomentar la reflexión emocional diaria
- Crear una experiencia más personalizada

## 🎯 Conclusión

La Mascota Virtual representa una innovación significativa en la experiencia del usuario, transformando el registro de emociones de una tarea funcional a una experiencia interactiva y emocionalmente significativa. Esta funcionalidad no solo mejora la usabilidad de la aplicación, sino que también contribuye al desarrollo de la inteligencia emocional de los estudiantes de manera lúdica y efectiva.
