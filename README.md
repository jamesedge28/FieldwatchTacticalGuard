# Fieldwatch Tactical Guard (iOS / SwiftUI)
### Suite Táctica de Privacidad, Seguridad y Contrainteligencia Militar

Fieldwatch Tactical Guard es una aplicación desarrollada en **SwiftUI** con arquitectura modular orientada a objetos para operaciones de contramedidas de vigilancia técnica (TSCM - *Technical Surveillance Countermeasures*), auditoría de espacios seguros y detección de dispositivos de espionaje encubiertos.

---

## 🛡️ Especificaciones de Diseño Táctico (Modo Oscuro Estricto)

La interfaz se ha diseñado bajo los más estrictos estándares visuales militares:
- **Fondo Primario:** Negro Puro `#000000` (Optimizado para pantallas OLED / Visión nocturna / Sin emisiones luminosas parásitas).
- **Tarjetas y Paneles Tácticos:** Gris Oscuro `#1C1C1E` con bordes finos `#2C2C2E`.
- **Acentos e Interacción:** Verde Neón `#00FF00` (Estilo visión HUD / terminal táctica).
- **Alertas y Anomalías:** Rojo Militar `#FF3B30` y Ámbar de Advertencia `#FF9500`.
- **Tipografía:** Tipografía monoespaciada táctica de alta legibilidad (`.monospaced`).

---

## 🗂️ Arquitectura Modular (Exactamente 5 Pestañas Tácticas)

```
FieldwatchTacticalGuard/
├── App/
│   ├── FieldwatchTacticalGuardApp.swift     # Punto de entrada @main de la app iOS
│   └── Info.plist                           # Claves de privacidad (Bluetooth, Cámara, Mic, LiDAR)
├── Theme/
│   └── TacticalTheme.swift                  # Paleta #000000, #1C1C1E, #00FF00, modificadores HUD y tarjetas
├── Services/
│   └── AudioHapticEngine.swift              # Síntesis acústica táctica (sirena, geiger RF) y hápticos CoreHaptics
├── Models/
│   ├── BLEDeviceModel.swift                 # Modelo de paquetes de anuncio BLE, RSSI y distancia logarítmica
│   ├── HeatmapPoint.swift                   # Retículo espacial de radiofrecuencia y gradientes de zonas ciegas
│   ├── ParasiteDeviceModel.swift            # Base de datos de fábrica y cálculo de exceso volumétrico
│   ├── SentinelSnapshot.swift               # Matriz de profundidad 3D y umbral de intrusión > 5cm
│   └── SurfaceAuditProfile.swift            # Auditoría sub-milimétrica (< 1.0mm) de cerraduras y paredes
├── ViewModels/
│   ├── SignalsViewModel.swift               # Escáner pasivo CBCentralManager y cálculo de zonas ciegas
│   ├── VisualScannerViewModel.swift         # Pipeline AVFoundation y filtro CIFilter para destellos IR
│   ├── Vision3DViewModel.swift              # ARKit (sceneReconstruction = .mesh), Matrix wireframe y rebote láser
│   ├── SentinelViewModel.swift              # Snapshot de referencia LiDAR, ciclo de monitoreo continuo y alarma
│   └── PhysicalIntegrityViewModel.swift     # Auditoría de micro-relieves y catálogo de hardware parásito
└── Views/
    ├── ContentView.swift                    # TabView principal con las 5 pestañas modulares obligatorias
    ├── Signals/
    │   ├── SignalsView.swift                # Listado de periféricos BLE, barra RSSI y clasificación
    │   └── BlindZoneHeatmapView.swift       # Retículo interactivo 2D/3D con vector de transmisor y punto ciego
    ├── VisualScanner/
    │   ├── VisualScannerView.swift          # Retícula HUD de cámara, controles de corte IR y ganancia EV
    │   └── CameraPreviewRepresentable.swift # Representable de fotogramas filtrados en tiempo real
    ├── Vision3D/
    │   ├── Vision3DView.swift               # HUD espacial, telemetría de malla, deslizador de sensibilidad
    │   └── ARMatrixRepresentable.swift      # ARSCNView con malla Matrix verde fluorescente y balizas rojas 3D
    ├── Sentinel/
    │   └── SentinelView.swift               # Botón de armado central, alerta estroboscópica y registro
    └── PhysicalIntegrity/
        ├── PhysicalIntegrityView.swift      # Selector modular de microrrelieves vs parásitos
        ├── SurfaceAuditView.swift           # Malla de microrrelieve 10x10 para detección de micrófonos de contacto
        └── ParasiteCatalogView.swift        # Calibrador LiDAR 3D y cálculo de sobredimensión volumétrica
```

---

## 📡 Detalle Operativo de los Módulos

### 1. Tab "Señales" (Ecosistema Radiofrecuencia)
- **Escáner Pasivo CoreBluetooth:** Utiliza `CBCentralManager` configurado para escaneo continuo de paquetes de anuncio sin interrupción (`CBCentralManagerScanOptionAllowDuplicatesKey: true`). Monitorea el RSSI en tiempo real, normaliza la potencia (-100 dBm a -30 dBm) y estima la distancia física mediante el modelo de propagación logarítmica (*Log-Distance Path Loss*). Clasifica heurísticamente los dispositivos en:
  - Transmisor Sospechoso (cámaras o transmisores encubiertos).
  - Baliza / Rastreador (AirTags, SmartTags, balizas BLE).
  - Enlace AV Inalámbrico (auriculares, micrófonos).
  - Dispositivo Genérico / Desconocido.
- **Submódulo "Mapeo de Zonas Ciegas":** Fusiona la intensidad de señal con la posición en una cuadrícula espacial de 8x8. Calcula el vector del gradiente electromagnético para ubicar el origen del transmisor (punto caliente crítico) y calcula el sector óptimo apantallado (punto ciego seguro) con mínima exposición radioeléctrica. Dispone de proyección perspectiva 3D y clics acústicos estilo Geiger.

### 2. Tab "Escáner Visual" (Detección Óptica e Infrarroja)
- **Cámara Trasera AVFoundation:** Captura fotogramas a 30 FPS en cola serial dedicada de alta prioridad.
- **Pipeline de Supresión Cromática CIFilter:**
  - `CIColorControls` con saturación 0.0 y alto contraste (1.8).
  - `CIExposureAdjust` con supresión de frecuencias medias y oscuras.
  - `CIGammaAdjust` / función de transferencia de alta luminancia para aislar emisiones de LEDs infrarrojos invisibles (850nm / 940nm) utilizados por cámaras espía para visión nocturna.
  - Retículo táctico dinámico que detecta el centroide y coloca una mira HUD roja (`IR-P1`, `IR-P2`) sobre el destello de la cámara oculta.

### 3. Tab "Visión 3D" (LiDAR Espacial y Reflejos)
- **Sesión ARKit con Reconstrucción de Malla:** `ARWorldTrackingConfiguration` con `sceneReconstruction = .mesh` activado para dispositivos con sensor LiDAR (iPhone 12 Pro o superior).
- **Submódulo "Visión Estilo Matrix":** Renderiza la geometría poligonal del entorno en modo *Wireframe* con aristas verde neón fluorescente sobre fondo negro absoluto, permitiendo al operador distinguir paredes, muebles y obstáculos físicos en oscuridad total sin encender linternas visibles.
- **Submódulo "Reflejo Láser":** Analiza el retorno del haz láser LiDAR. Cuando el pulso colisiona con el cristal o recubrimiento anti-reflectante de un lente estenopeico (pinhole), se produce un pico de reflectancia óptica especular. El algoritmo detecta esta discontinuidad y genera un **nodo virtual 3D flotante rojo** (`SCNNode` con esfera pulsante y anillo de mira giratorio) anclado en las coordenadas exactas del espacio de realidad aumentada.

### 4. Tab "Centinela" (Alarma Volumétrica en Oscuridad)
- **Protocolo de Armado Táctico:** Cuenta regresiva táctica de 5 segundos con pulsos acústicos para permitir al operador colocar el iPhone apuntando a la zona crítica (puerta, ventana o balcón de un cuarto de hotel) y retirarse.
- **Snapshot Tridimensional:** Toma un registro de profundidad de referencia (matriz 16x16 de distancias focales LiDAR).
- **Monitoreo Continuo a 10 Hz:** Compara fotograma a fotograma las distancias en tiempo real contra el snapshot. Si cualquier celda experimenta una variación volumétrica o desplazamiento mayor a **5 centímetros** ($\Delta z > 0.05\text{ m}$), activa la **Alerta de Intrusión**:
  - Sirena acústica táctica dual sintetizada en segundo plano.
  - Vibración háptica extrema continua (`UINotificationFeedbackGenerator(.error)` y `UIImpactFeedbackGenerator(.heavy)`).
  - Pantalla estroboscópica roja parpadeante de alta visibilidad.
  - Registro forense con hora exacta y variación en centímetros.

### 5. Tab "Integridad Física" (Análisis de Superficies y Parásitos)
- **Submódulo "Alteraciones en Paredes y Cerraduras":** Muestreo de ultra alta resolución (malla de microrrelieve 10x10) de cerraduras de puertas, diales de cajas fuertes o paredes lisas. Permite guardar la línea base antes de salir de la habitación y realizar una segunda pasada al volver (**Modo Auditoría**). Resalta anomalías sub-milimétricas menores a **1 milímetro** que delatan:
  - Hundimientos de 0.8mm a 1.2mm producidos por micrófonos de contacto / estetoscópicos.
  - Taladrado milimétrico de cerraduras o manipulación de pernos.
  - Parches recientes de masilla o pintura fresca sobre micro-cámaras empotradas.
- **Submódulo "Dispositivos Parásitos":** Catálogo local de fábrica (*Mock Data*) con dimensiones nominales en milímetros (Ancho, Alto, Profundidad) y volumen estándar en $cm^3$ de cargadores (Apple 20W, Anker GaN), detectores de humo, regletas multicontacto y placas de enchufe. Dispone de un calibrador 3D LiDAR para medir el objeto real: calcula la variación porcentual ($\Delta V\%$) y clasifica el riesgo. Si el cargador posee un exceso volumétrico superior a la tolerancia (ej. +22%), delata que la carcasa ha sido modificada para alojar una micro-cámara o transmisor espía alimentado por la red eléctrica.

---

## 🚀 Guía de Instalación y Exportación a Xcode

1. **Abrir Xcode:**
   - Selecciona **Create a new Xcode project**.
   - Escoge **iOS > App** y pulsa **Next**.
   - Configura:
     - **Product Name:** `FieldwatchTacticalGuard`
     - **Interface:** `SwiftUI`
     - **Language:** `Swift`
2. **Copiar Archivos:**
   - Arrastra todas las carpetas (`App`, `Theme`, `Services`, `Models`, `ViewModels`, `Views`) a tu proyecto en el navegador de archivos de Xcode.
3. **Configurar Permisos en Info.plist:**
   - Asegúrate de incluir las descripciones de privacidad para Bluetooth, Cámara y Micrófono presentes en `App/Info.plist`.
4. **Requisitos de Dispositivo:**
   - Para las funciones completas de LiDAR (.mesh y Reconstrucción Espacial), se recomienda iPhone 12 Pro / 13 Pro / 14 Pro / 15 Pro / 16 Pro o iPad Pro con LiDAR.
   - En dispositivos sin LiDAR o en el Simulador de iOS, la aplicación conmuta automáticamente a sus **modos de simulación táctica**, permitiendo probar el 100% de la interfaz, el escaneo BLE, el mapa térmico, los filtros ópticos y las alarmas de intrusión.
