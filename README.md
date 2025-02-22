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
   git clone https://github.com/jmsantangelo/Destilacion_V4_0_limite_q.git

## Uso
- Ajusta los deslizadores para modificar \(R\), \(q\), \(xD\), \(zF\), y \(xB\).
- Presiona "Etapas" para calcular las etapas de destilación.
- Usa "PDF" para exportar el gráfico o "Exportar Informe" para guardar los datos.
- Si el punto de intersección sale del área válida, aparecerá una advertencia. Usa "Volver" o ajusta manualmente los deslizadores para regresar a una condición válida.

## Licencia
Este proyecto está licenciado bajo la [MIT License](LICENSE) - siéntete libre de usarlo, editarlo y modificarlo como desees, siempre que incluyas el aviso de copyright y esta licencia.

## Contribuciones
¡Las contribuciones son bienvenidas! Si quieres mejorar este programa:
1. Haz un fork del repositorio.
2. Crea una rama para tus cambios (`git checkout -b mi-mejora`).
3. Commitea tus cambios (`git commit -m "Descripción de la mejora"`).
4. Sube tu rama (`git push origin mi-mejora`).
5. Abre un Pull Request en GitHub.

## Autor
- [Juan Manuel Santangelo] (jmsantangelo@gmail.com)

## Créditos
Desarrollado con la ayuda de Grok (xAI) para optimización y depuración.
