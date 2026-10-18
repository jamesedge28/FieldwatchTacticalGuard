# Reglas de Proyecto: Fieldwatch Tactical Guard

## Contexto del Proyecto
Fieldwatch Tactical Guard es una aplicación táctica de ciberseguridad, privacidad y contrainteligencia militar para iOS en SwiftUI.

## Directrices de Desarrollo
1. Mantener el diseño estricto en modo oscuro:
   - Fondos: `#000000` (Negro Puro).
   - Tarjetas y Contenedores: `#1C1C1E` (Gris Oscuro).
   - Acentos, Textos Interactivos y Gráficas: `#00FF00` (Verde Neón Táctico).
   - Alertas Críticas: `#FF3B30` (Rojo Militar) y `#FF9500` (Ámbar Advertencia).
2. Conservar la arquitectura modular orientada a objetos en Swift en las 5 pestañas principales:
   - Pestaña 1: Señales (BLE pasivo y Zonas Ciegas RF).
   - Pestaña 2: Escáner Visual (AVFoundation y CIFilter de infrarrojos).
   - Pestaña 3: Visión 3D (ARKit .mesh Wireframe Matrix y Rebote Láser).
   - Pestaña 4: Centinela (Snapshot 3D y Alarma de Intrusión > 5cm).
   - Pestaña 5: Integridad Física (Microrrelieves < 1mm y Hardware Parásito).
3. Todas las descripciones técnicas y documentación deben mantenerse en español.
