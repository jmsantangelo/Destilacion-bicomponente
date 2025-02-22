# Destilacion 
# Simulador McCabe-Thiele en Processing 4

Este programa es un simulador interactivo del método McCabe-Thiele para el diseño de columnas de destilación de dos componentes, desarrollado en Processing 4. Permite ajustar parámetros como la relación de reflujo (\(R\)), el parámetro de alimentación (\(q\)), y las fracciones molares (\(xD\), \(zF\), \(xB\)), visualizar el diagrama, calcular etapas y exportar resultados en PDF o texto.

## Características
- Interfaz gráfica con deslizadores para ajustar parámetros.
- Visualización del diagrama McCabe-Thiele con líneas de operación y curva de equilibrio.
- Cálculo automático de etapas.
- Exportación de informes y gráficos en PDF.
- Advertencia cuando el punto de intersección está fuera del área válida, con opción de volver a valores iniciales.

## Requisitos
- [Processing 4](https://processing.org/download/)
- Biblioteca **ControlP5** y **processing.pdf** (instálala desde el menú de Processing: `Sketch > Import Library > Add Library`, buscar la libreria en cuestion y haz clic en "Install").

## Instalación y uso
1. Descarga este repositorio (clic en **Code** > **Download ZIP**) o clónalo con Git:
   ```bash
   git clone https://github.com/tu-usuario/McCabeThieleSimulator.git
