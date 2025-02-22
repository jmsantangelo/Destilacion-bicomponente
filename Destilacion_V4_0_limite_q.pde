import processing.pdf.*;
import controlP5.*;
import javax.swing.JFileChooser;

// Clase para almacenar datos de cada etapa de destilación
class EtapaData {
  int numero;           // Número de la etapa
  float xEntrada;       // Fracción molar de entrada en x
  float ySalida;        // Fracción molar de salida en y
  float xSalida;        // Fracción molar de salida en x
  float yEntrada;       // Fracción molar de entrada en y

  EtapaData(int numero, float xEntrada, float ySalida, float xSalida, float yEntrada) {
    this.numero = numero;
    this.xEntrada = xEntrada;
    this.ySalida = ySalida;
    this.xSalida = xSalida;
    this.yEntrada = yEntrada;
  }
}

// Constantes iniciales y parámetros del gráfico
final float R_INICIAL = 2, Q_INICIAL = 0.5, XD_INICIAL = 0.8, ZF_INICIAL = 0.5, XB_INICIAL = 0.2;
final float X_MIN = 0, X_MAX = 1.1, Y_MIN = 0, Y_MAX = 1.1, STEP = 0.05;
final float GRAPH_OFFSET_X = 300;
final color FONDO_GRAFICA = color(255);  // Fondo blanco para la gráfica
final color CUADRICULA = color(220);     // Gris claro para la cuadrícula
final float RELATIVE_VOLATILITY = 2.5;   // Volatilidad relativa fija del sistema

// Variables globales
ControlP5 cp5;
float R = R_INICIAL, q = Q_INICIAL, xD = XD_INICIAL, zF = ZF_INICIAL, xB = XB_INICIAL;
float interseccionX, interseccionY;      // Coordenadas de la intersección entre líneas
boolean calcularEtapasPresionado = false;// Bandera para activar el cálculo de etapas
ArrayList<PVector> etapasHoriz = new ArrayList<PVector>(); // Líneas horizontales de etapas
ArrayList<PVector> etapasVert = new ArrayList<PVector>();  // Líneas verticales de etapas
ArrayList<EtapaData> tablaEtapas = new ArrayList<EtapaData>(); // Tabla de datos de etapas
// Variables para el parpadeo del punto de intersección
boolean puntoFuera = false;  // Indica si el punto está fuera del área
int ultimoCambio = 0;        // Último tiempo de cambio de color
boolean mostrarPunto = true; // Estado del parpadeo (visible o no)
final int INTERVALO = 500;   // Intervalo de parpadeo en milisegundos (0.5 segundos)
// Variables para la advertencia
boolean mostrarAdvertencia = false;  // Controla si se muestra el cuadro de advertencia
// Estado válido anterior
Button calcularRminButton, resetValoresButton, calcularEtapasButton, exportarInformeButton, generarPDFButton;
float R_valido, q_valido, xD_valido, zF_valido, xB_valido;
Button volverButton;  // Botón "Volver" de ControlP5
Textlabel rminLabel;                     // Etiqueta para mostrar Rmin
int etapa = 0;                           // Contador de etapas
float xActual;                           // Variable para el cálculo de etapas

// Configuración de la ventana de texto para logs
String logText = "";
final int TEXT_WINDOW_X = 305;
final int TEXT_WINDOW_Y = 718;
final int TEXT_WINDOW_WIDTH = 300;
final int TEXT_WINDOW_HEIGHT = 40;

// Configuración inicial del programa
void setup() {
  size(1160, 860);
  background(255);
  cp5 = new ControlP5(this);
  configurarInterfaz();
  
  // Inicializar estado válido
  R_valido = R_INICIAL;
  q_valido = Q_INICIAL;
  xD_valido = XD_INICIAL;
  zF_valido = ZF_INICIAL;
  xB_valido = XB_INICIAL;
}

// Bucle principal de dibujo
void draw() {
  background(255);
  
  dibujarFondoGraficaEstatico();
  dibujarInterfaz();
  dibujarGrafica();
  dibujarEtapas();
  agregarAlLog("Área: " + (calcularEtapasPresionado ? nf(calcularArea(), 0, 3) : "-"));
  dibujarVentanaTexto();

  if (!puntoFuera) {
    R_valido = R;
    q_valido = q;
    xD_valido = xD;
    zF_valido = zF;
    xB_valido = xB;
  }

  if (puntoFuera && !mostrarAdvertencia) {
    println("Advertencia activada: puntoFuera = " + puntoFuera);
    mostrarAdvertencia = true;
    configurarBotonVolver();
    // Bloquear botones de fondo
    calcularRminButton.lock();
    resetValoresButton.lock();
    calcularEtapasButton.lock();
    exportarInformeButton.lock();
    generarPDFButton.lock();
  } else if (!puntoFuera && mostrarAdvertencia) {
    println("Advertencia desactivada: puntoFuera = " + puntoFuera);
    mostrarAdvertencia = false;
    if (volverButton != null) {
      volverButton.remove();
      volverButton = null;
      println("Botón eliminado desde draw");
    }
    // Desbloquear botones de fondo
    calcularRminButton.unlock();
    resetValoresButton.unlock();
    calcularEtapasButton.unlock();
    exportarInformeButton.unlock();
    generarPDFButton.unlock();
  }

  if (mostrarAdvertencia) {
    fill(200, 200, 200, 100);
    noStroke();
    rect(0, 0, width, height);

    fill(255);
    stroke(0);
    rect(width/2 - 200, height/2 - 100, 400, 200, 10);

    fill(0);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Sin solución posible", width/2, height/2 - 20);
  }
}

// Dibuja el fondo estático de la gráfica con cuadrícula
void dibujarFondoGraficaEstatico() {
  float offsetX = GRAPH_OFFSET_X + 5, offsetY = height - 180;

  fill(FONDO_GRAFICA);
  noStroke();
  rect(offsetX, 80, width - 165 - offsetX, offsetY - 80);

  stroke(CUADRICULA);
  strokeWeight(1);
  textSize(12);
  fill(0);
  textAlign(CENTER, TOP);

  // Dibuja líneas verticales y etiquetas en el eje X
  for (float x = X_MIN; x <= X_MAX; x += STEP) {
    float screenX = map(x, X_MIN, X_MAX, offsetX, width - 165);
    line(screenX, offsetY, screenX, 80);
    text(nf(x, 0, 2), screenX, offsetY + 5);
  }

  textAlign(RIGHT, CENTER);
  // Dibuja líneas horizontales y etiquetas en el eje Y
  for (float y = Y_MIN; y <= Y_MAX; y += STEP) {
    float screenY = map(y, Y_MIN, Y_MAX, offsetY, 80);
    line(offsetX, screenY, width - 165, screenY);
    text(nf(y, 0, 2), offsetX - 5, screenY);
  }
}

// Configura la interfaz de usuario con sliders y botones
void configurarInterfaz() {
  final int SLIDER_X = 20, SLIDER_WIDTH = 140, SLIDER_HEIGHT = 20, START_Y = 130, SPACING = 50;

  configurarSlider("R", SLIDER_X, START_Y, SLIDER_WIDTH, SLIDER_HEIGHT, 0.05, 5, R_INICIAL);
  configurarSlider("q", SLIDER_X, START_Y + SPACING, SLIDER_WIDTH, SLIDER_HEIGHT, -2, 3, Q_INICIAL);
  configurarSlider("xD", SLIDER_X, START_Y + 2 * SPACING, SLIDER_WIDTH, SLIDER_HEIGHT, 0.7, 0.95, XD_INICIAL);
  configurarSlider("zF", SLIDER_X, START_Y + 3 * SPACING, SLIDER_WIDTH, SLIDER_HEIGHT, 1.1 * 0.25, 0.9 * 0.7, ZF_INICIAL);
  configurarSlider("xB", SLIDER_X, START_Y + 4 * SPACING, SLIDER_WIDTH, SLIDER_HEIGHT, 0.05, 0.25, XB_INICIAL);

  calcularRminButton = cp5.addButton("calcularRmin")
                          .setPosition(SLIDER_X, START_Y + 5 * SPACING)
                          .setSize(SLIDER_WIDTH, 30)
                          .setLabel("Cálculo de Rmin");
  resetValoresButton = cp5.addButton("resetValores")
                          .setPosition(SLIDER_X, height - 60)
                          .setSize(SLIDER_WIDTH, 30)
                          .setLabel("Reset");
  calcularEtapasButton = cp5.addButton("calcularEtapas")
                            .setPosition(width - 150, (80 + (height - 160)) / 2 - 15)
                            .setSize(SLIDER_WIDTH, 30)
                            .setLabel("Etapas");
  exportarInformeButton = cp5.addButton("exportarInforme")
                             .setPosition(width - 150, (80 + (height - 160)) / 2 - 15 + 30 + 10)
                             .setSize(SLIDER_WIDTH, 30)
                             .setLabel("Exportar Informe");
  generarPDFButton = cp5.addButton("generarPDF")
                          .setPosition(width - 150, (80 + (height - 160)) / 2 - 15 + 30 + 10 + 30 + 10)
                          .setSize(SLIDER_WIDTH, 30)
                          .setLabel("PDF");

  rminLabel = cp5.addTextlabel("rminValue")
                 .setText("Rmin: -")
                 .setPosition(SLIDER_X, START_Y + 5 * SPACING + 40)
                 .setColorValue(0)
                 .setFont(createFont("Arial", 12));
}

void configurarBotonVolver() {
  if (volverButton == null) {
    volverButton = cp5.addButton("volver")
                      .setPosition(width/2 - 50, height/2 + 20)
                      .setSize(100, 40)
                      .setLabel("Volver")
                      .setColorBackground(color(100, 100, 255))
                      .setColorForeground(color(150, 150, 255))
                      .setColorActive(color(200, 200, 255));
    println("Botón Volver creado"); // Depuración
  }
}

// Configura un slider con rango y valor inicial
void configurarSlider(String nombre, int x, int y, int width, int height, float min, float max, float valorInicial) {
  Slider slider = cp5.addSlider(nombre)
                     .setPosition(x, y)
                     .setSize(width, height)
                     .setRange(min, max)
                     .setValue(valorInicial);
  
  slider.addListener(new ControlListener() {
    public void controlEvent(ControlEvent event) {
      switch (nombre) {
        case "R": R = event.getController().getValue(); break;
        case "q": q = event.getController().getValue(); break;
        case "xD": xD = event.getController().getValue(); break;
        case "zF": zF = event.getController().getValue(); break;
        case "xB": xB = event.getController().getValue(); break;
      }
      if (calcularEtapasPresionado) calcularEtapas();
    }
  });
}

// Dibuja los elementos estáticos de la interfaz (títulos y etiquetas)
void dibujarInterfaz() {
  textSize(24);
  fill(0);
  textAlign(CENTER, TOP);
  text("DESTILACIÓN DE 2 COMPONENTES", width / 2, 20);

  textSize(12);
  textAlign(LEFT, CENTER);
  final int SLIDER_X = 20, START_Y = 130, SPACING = 50;
  text("R (Relación de Reflujo)", SLIDER_X, START_Y - 15);
  text("q (Parámetro de Alimentación)", SLIDER_X, START_Y + SPACING - 15);
  text("xD (Fracción molar destilado)", SLIDER_X, START_Y + 2 * SPACING - 15);
  text("zF (Fracción molar alimentación)", SLIDER_X, START_Y + 3 * SPACING - 15);
  text("xB (Fracción molar fondo)", SLIDER_X, START_Y + 4 * SPACING - 15);
}

// Dibuja las líneas principales del gráfico McCabe-Thiele
void dibujarGrafica() {
  float offsetX = GRAPH_OFFSET_X + 5, offsetY = height - 180;

  strokeWeight(2);
  stroke(0);
  line(offsetX, 80, offsetX, offsetY);
  line(offsetX, offsetY, width - 165, offsetY);

  stroke(0, 0, 255);
  strokeWeight(2);
  drawLine(X_MIN, Y_MIN, 1.0, 1.0);

  stroke(255, 0, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (float x = X_MIN; x <= 1.0; x += 0.01) {
    float y = (RELATIVE_VOLATILITY * x) / (1 + (RELATIVE_VOLATILITY - 1) * x);
    vertex(map(x, X_MIN, X_MAX, offsetX, width - 165), map(y, Y_MIN, Y_MAX, offsetY, 80));
  }
  endShape();

  stroke(150, 0, 150);
  strokeWeight(2);
  dibujarLineaQ();

  calcularInterseccion();
  dibujarOperacion(); // Ya está sin parámetros
}

// Dibuja la línea de alimentación (línea q)
void dibujarLineaQ() {
  if (q != 1) {
    float y1_q = constrain((q / (q - 1)) * X_MIN - (zF / (q - 1)), Y_MIN, Y_MAX);
    float y2_q = constrain((q / (q - 1)) * X_MAX - (zF / (q - 1)), Y_MIN, Y_MAX);
    float x1_q = (y1_q == Y_MIN || y1_q == Y_MAX) ? ((y1_q + (zF / (q - 1))) * (q - 1)) / q : X_MIN;
    float x2_q = (y2_q == Y_MIN || y2_q == Y_MAX) ? ((y2_q + (zF / (q - 1))) * (q - 1)) / q : X_MAX;
    drawLine(x1_q, y1_q, x2_q, y2_q);
  } else {
    drawLine(zF, Y_MIN, zF, Y_MAX);          // Caso especial: q = 1, línea vertical
  }
}

// Calcula la intersección entre la línea de operación y la línea q
void calcularInterseccion() {
  if (q == 1) {
    interseccionX = zF;
    interseccionY = (R / (R + 1)) * interseccionX + (xD / (R + 1));
  } else {
    interseccionX = ((xD / (R + 1)) + (zF / (q - 1))) / ((q / (q - 1)) - (R / (R + 1)));
    interseccionY = (R / (R + 1)) * interseccionX + (xD / (R + 1));
  }
  // Se eliminan las restricciones relacionadas con la curva de equilibrio y la línea y=x
}

// Dibuja las líneas de operación y puntos clave
void dibujarOperacion() {
  // Verificar si el punto está dentro del área
  puntoFuera = !estaDentroDelArea(interseccionX, interseccionY);

  // Controlar el parpadeo si está fuera
  if (puntoFuera) {
    int tiempoActual = millis();
    if (tiempoActual - ultimoCambio >= INTERVALO) {
      mostrarPunto = !mostrarPunto;
      ultimoCambio = tiempoActual;
    }
  } else {
    mostrarPunto = true; // Siempre visible si está dentro
  }

  if (interseccionX >= X_MIN && interseccionX <= X_MAX && interseccionY >= Y_MIN && interseccionY <= Y_MAX) {
    // Dibujar punto de intersección
    if (mostrarPunto) {
      fill(puntoFuera ? color(255, 0, 0) : color(255, 255, 0)); // Rojo si fuera, amarillo si dentro
      stroke(0);
      drawPoint(interseccionX, interseccionY);
    }

    stroke(0, 150, 0); // Línea de rectificación en verde
    strokeWeight(2);
    drawLine(xD, xD, interseccionX, interseccionY);
    stroke(255, 204, 0); // Línea de agotamiento en naranja
    drawLine(xB, xB, interseccionX, interseccionY);
  }

  fill(255, 0, 0); // Puntos clave en rojo
  stroke(0);
  drawPoint(xB, xB);
  drawPoint(zF, zF);
  drawPoint(xD, xD);
}

// Dibuja las etapas calculadas en el gráfico
void dibujarEtapas() {
  if (!calcularEtapasPresionado) return;

  strokeWeight(3);

  // Dibuja líneas horizontales de las etapas (hacia la izquierda)
  for (int i = 0; i < etapasHoriz.size() - 1; i += 2) {
    PVector inicio = etapasHoriz.get(i);
    PVector fin = etapasHoriz.get(i + 1);
    stroke(255);                            // Fondo blanco para contraste
    drawLine(inicio.x, inicio.y, fin.x, fin.y);
    stroke(0);                              // Línea negra principal
    drawLine(inicio.x, inicio.y, fin.x, fin.y);
  }

  // Dibuja líneas verticales de las etapas (descendentes)
  for (int i = 0; i < etapasVert.size() - 1; i += 2) {
    PVector inicio = etapasVert.get(i);
    PVector fin = etapasVert.get(i + 1);
    stroke(255);                            // Fondo blanco para contraste
    drawLine(inicio.x, inicio.y, fin.x, fin.y);
    stroke(0);                              // Línea negra principal
    drawLine(inicio.x, inicio.y, fin.x, fin.y);
  }

  strokeWeight(1);
}

// Función auxiliar para dibujar líneas en el gráfico
void drawLine(float x1, float y1, float x2, float y2) {
  float offsetX = GRAPH_OFFSET_X + 5, offsetY = height - 180;
  line(map(x1, X_MIN, X_MAX, offsetX, width - 165), map(y1, Y_MIN, Y_MAX, offsetY, 80),
       map(x2, X_MIN, X_MAX, offsetX, width - 165), map(y2, Y_MIN, Y_MAX, offsetY, 80));
}

// Función auxiliar para dibujar puntos en el gráfico
void drawPoint(float x, float y) {
  float offsetX = GRAPH_OFFSET_X + 5, offsetY = height - 180;
  ellipse(map(x, X_MIN, X_MAX, offsetX, width - 165), map(y, Y_MIN, Y_MAX, offsetY, 80), 8, 8);
}

// Convierte coordenadas del gráfico a coordenadas del PDF
PVector graphToPDF(float graph_x, float graph_y) {
  float offsetX = GRAPH_OFFSET_X + 5; // x=305 (referencia del gráfico en pantalla)
  float offsetY = height - 180;       // y=680 (referencia del gráfico en pantalla)
  float screen_x = map(graph_x, X_MIN, X_MAX, offsetX, width - 165); // Mapea x al rango del gráfico en pantalla
  float screen_y = map(graph_y, Y_MIN, Y_MAX, offsetY, 80);          // Mapea y al rango del gráfico en pantalla
  // Escala al nuevo tamaño del PDF (740x710, con márgenes)
  float pdf_x = map(screen_x, offsetX, width - 165, 50, 690);  // Márgenes de 50px a la izquierda y derecha
  float pdf_y = map(screen_y, 80, offsetY, 50, 660);           // Márgenes de 50px arriba y abajo
  return new PVector(pdf_x, pdf_y);
}

// Reinicia los valores a los iniciales
void resetValores() {
  calcularEtapasPresionado = false;
  etapasHoriz.clear();
  etapasVert.clear();
  tablaEtapas.clear();
  cp5.getController("R").setValue(R_INICIAL);
  cp5.getController("q").setValue(Q_INICIAL);
  cp5.getController("xD").setValue(XD_INICIAL);
  cp5.getController("zF").setValue(ZF_INICIAL);
  cp5.getController("xB").setValue(XB_INICIAL);
  R = R_INICIAL; q = Q_INICIAL; xD = XD_INICIAL; zF = ZF_INICIAL; xB = XB_INICIAL;
  rminLabel.setText("Rmin: -");
}

// Calcula el número de etapas usando el método McCabe-Thiele
void calcularEtapas() {
  calcularEtapasPresionado = true;
  etapasHoriz.clear();
  etapasVert.clear();
  tablaEtapas.clear();

  xActual = xD;
  float yActual = xD;
  etapa = 0;
  int maxEtapas = 100;
  float umbralXB = xB + 0.05 * xB;

  while (xActual > umbralXB && etapa < maxEtapas) {
    float xE = xActual;
    float yE = (RELATIVE_VOLATILITY * xE) / (1 + (RELATIVE_VOLATILITY - 1) * xE);
    yE = constrain(yE, Y_MIN, Y_MAX);

    if (abs(yE - yActual) > 0.001) {
      float a = RELATIVE_VOLATILITY - (RELATIVE_VOLATILITY - 1) * yActual;
      float b = yActual;
      xE = (abs(a) < 0.0001) ? 0 : b / a;
      yE = yActual;
    }
    xE = constrain(xE, X_MIN, X_MAX);

    etapasHoriz.add(new PVector(xActual, yActual));
    etapasHoriz.add(new PVector(xE, yE));

    float yOp;
    if (xE > interseccionX) {
      yOp = (R / (R + 1)) * xE + (xD / (R + 1));
    } else {
      if (xE <= xB) {
        yOp = xE;
      } else if (abs(interseccionX - xB) < 0.001) {
        yOp = xB;
      } else {
        float mAgot = (interseccionY - xB) / (interseccionX - xB);
        float bAgot = interseccionY - mAgot * interseccionX;
        yOp = mAgot * xE + bAgot;
      }
    }
    yOp = constrain(yOp, Y_MIN, Y_MAX);

    etapasVert.add(new PVector(xE, yE));
    etapasVert.add(new PVector(xE, yOp));

    etapa++;
    tablaEtapas.add(new EtapaData(etapa, xActual, yE, xE, yOp));
    xActual = xE;
    yActual = yOp;
  }

  float area = calcularArea();
  agregarAlLog("Área: " + nf(area, 0, 3));
}

// Calcula la relación de reflujo mínima (Rmin)
void calcularRmin() {
  float xInt = calcularInterseccionCurvaEquilibrio(), yInt = (RELATIVE_VOLATILITY * xInt) / (1 + (RELATIVE_VOLATILITY - 1) * xInt);
  float Rmin = ((yInt - xD) / (xInt - xD)) / (1 - ((yInt - xD) / (xInt - xD)));
  rminLabel.setText("Rmin: " + nf(Rmin, 0, 2));
  cp5.getController("R").setValue(Rmin);
}

// Calcula la intersección entre la línea q y la curva de equilibrio
float calcularInterseccionCurvaEquilibrio() {
  float xInt, yInt;
  if (q == 1) {
    xInt = zF;
    yInt = (RELATIVE_VOLATILITY * xInt) / (1 + (RELATIVE_VOLATILITY - 1) * xInt);
  } else {
    xInt = xD;
    float tolerance = 0.0001, delta = 1.0;
    while (abs(delta) > tolerance) {
      float f = (q / (q - 1)) * xInt - (zF / (q - 1)) - (RELATIVE_VOLATILITY * xInt) / (1 + (RELATIVE_VOLATILITY - 1) * xInt);
      float df = (q / (q - 1)) - (RELATIVE_VOLATILITY) / pow(1 + (RELATIVE_VOLATILITY - 1) * xInt, 2);
      delta = f / df;
      xInt -= delta;
    }
    yInt = (RELATIVE_VOLATILITY * xInt) / (1 + (RELATIVE_VOLATILITY - 1) * xInt);
  }
  interseccionX = xInt;
  interseccionY = yInt;
  return xInt;
}

// Dibuja la ventana de texto para mostrar información del cálculo
void dibujarVentanaTexto() {
  fill(255);
  stroke(0);
  rect(TEXT_WINDOW_X, TEXT_WINDOW_Y, TEXT_WINDOW_WIDTH, TEXT_WINDOW_HEIGHT);

  fill(0);
  textSize(12);
  textAlign(LEFT, TOP);
  text(logText, TEXT_WINDOW_X + 5, TEXT_WINDOW_Y + 5, TEXT_WINDOW_WIDTH - 10, TEXT_WINDOW_HEIGHT - 10);
}

// Añade información al log de texto
void agregarAlLog(String mensaje) {
  String estadoInterseccion = puntoFuera ? "Sin solución posible" : "";
  logText = "Etapas calculadas: " + etapa + "\n" +
            "Último xActual: " + nf(xActual, 0, 2) + ", xB: " + nf(xB, 0, 2) + "\n" +
            mensaje + (estadoInterseccion.isEmpty() ? "" : "\n" + estadoInterseccion);
  String[] lines = logText.split("\n");
  if (lines.length > 10) {
    logText = join(subset(lines, lines.length - 10), "\n");
  }
}

// Función auxiliar para seleccionar ruta
String seleccionarRutaArchivo(String nombrePorDefecto) {
  JFileChooser fileChooser = new JFileChooser();
  fileChooser.setSelectedFile(new java.io.File(nombrePorDefecto));
  int resultado = fileChooser.showSaveDialog(null);
  
  if (resultado == JFileChooser.APPROVE_OPTION) {
    return fileChooser.getSelectedFile().getAbsolutePath();
  } else {
    println("Guardado cancelado por el usuario.");
    return null;
  }
}

// Exporta un informe con los datos de las etapas
void exportarInforme() {
  String[] lineas = new String[tablaEtapas.size() + 1];
  lineas[0] = String.format("%8s %8s %8s %8s %8s", "Etapa", "x_entrada", "y_salida", "x_salida", "y_entrada");

  for (int i = 0; i < tablaEtapas.size(); i++) {
    EtapaData e = tablaEtapas.get(i);
    lineas[i + 1] = String.format("%8d %8.3f %8.3f %8.3f %8.3f",
                                  e.numero,
                                  e.xEntrada,
                                  e.ySalida,
                                  e.xSalida,
                                  e.yEntrada);
  }

  String ruta = seleccionarRutaArchivo("informe_etapas.txt");
  if (ruta != null) {
    saveStrings(ruta, lineas);
    println("Informe exportado a: " + ruta);
  }
}

// Genera un archivo PDF del área del gráfico
void generarPDF() {
  String ruta = seleccionarRutaArchivo("graph.pdf");
  if (ruta != null) {
    PGraphics pdf = createGraphics(790, 760, PDF, ruta); // Aumenta el tamaño para incluir más contenido
    pdf.beginDraw();
    pdf.background(FONDO_GRAFICA);
    dibujarFondoGraficaPDF(pdf);
    dibujarEjesPDF(pdf); // Añade las escalas de los ejes
    dibujarGraficaPDF(pdf);
    dibujarEtapasPDF(pdf);
    dibujarVentanaTextoPDF(pdf); // Añade el cuadro de texto con los logs
    pdf.endDraw();
    pdf.dispose();
    println("PDF exportado a: " + ruta);
  }
}

// Dibuja el fondo y la cuadrícula en el PDF
void dibujarFondoGraficaPDF(PGraphics pdf) {
  pdf.fill(FONDO_GRAFICA);
  pdf.noStroke();
  pdf.rect(50, 50, 690, 610);  // Mantiene el área del gráfico, ajustando para texto y ejes

  pdf.stroke(CUADRICULA);
  pdf.strokeWeight(1);

  // Líneas verticales (eje X) - solo las líneas, las etiquetas van en dibujarEjesPDF
  for (float x = X_MIN; x <= X_MAX; x += STEP) {
    PVector p1 = graphToPDF(x, Y_MIN);
    PVector p2 = graphToPDF(x, Y_MAX);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
  }

  // Líneas horizontales (eje Y) - solo las líneas, las etiquetas van en dibujarEjesPDF
  for (float y = Y_MIN; y <= Y_MAX; y += STEP) {
    PVector p1 = graphToPDF(X_MIN, y);
    PVector p2 = graphToPDF(X_MAX, y);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
  }
}

// Dibuja las líneas principales y puntos en el PDF
void dibujarGraficaPDF(PGraphics pdf) {
  pdf.strokeWeight(2);

  // Línea y=x (azul)
  pdf.stroke(0, 0, 255);
  PVector p1 = graphToPDF(X_MIN, Y_MIN);
  PVector p2 = graphToPDF(1.0, 1.0);
  pdf.line(p1.x, p1.y, p2.x, p2.y);

  // Curva de equilibrio (rojo)
  pdf.stroke(255, 0, 0);
  pdf.noFill();
  pdf.beginShape();
  for (float x = X_MIN; x <= 1.0; x += 0.01) {
    float y = (RELATIVE_VOLATILITY * x) / (1 + (RELATIVE_VOLATILITY - 1) * x);
    PVector p = graphToPDF(x, y);
    pdf.vertex(p.x, p.y);
  }
  pdf.endShape();

  // Línea q (morado)
  pdf.stroke(150, 0, 150);
  if (q != 1) {
    float y1_q = constrain((q / (q - 1)) * X_MIN - (zF / (q - 1)), Y_MIN, Y_MAX);
    float y2_q = constrain((q / (q - 1)) * X_MAX - (zF / (q - 1)), Y_MIN, Y_MAX);
    float x1_q = (y1_q == Y_MIN || y1_q == Y_MAX) ? ((y1_q + (zF / (q - 1))) * (q - 1)) / q : X_MIN;
    float x2_q = (y2_q == Y_MIN || y2_q == Y_MAX) ? ((y2_q + (zF / (q - 1))) * (q - 1)) / q : X_MAX;
    PVector pq1 = graphToPDF(x1_q, y1_q);
    PVector pq2 = graphToPDF(x2_q, y2_q);
    pdf.line(pq1.x, pq1.y, pq2.x, pq2.y);
  } else {
    PVector pq1 = graphToPDF(zF, Y_MIN);
    PVector pq2 = graphToPDF(zF, Y_MAX);
    pdf.line(pq1.x, pq1.y, pq2.x, pq2.y);
  }

  // Líneas de operación y puntos
  if (interseccionX >= xB && interseccionX >= X_MIN && interseccionX <= X_MAX && interseccionY >= Y_MIN && interseccionY <= Y_MAX) {
    pdf.fill(255, 255, 0); // Punto de intersección
    pdf.stroke(0);
    PVector pi = graphToPDF(interseccionX, interseccionY);
    pdf.ellipse(pi.x, pi.y, 8, 8);

    pdf.stroke(0, 150, 0); // Línea de rectificación
    PVector pd = graphToPDF(xD, xD);
    pdf.line(pd.x, pd.y, pi.x, pi.y);

    pdf.stroke(255, 204, 0); // Línea de agotamiento
    PVector pb = graphToPDF(xB, xB);
    pdf.line(pb.x, pb.y, pi.x, pi.y);
  }

  pdf.fill(255, 0, 0); // Puntos clave
  pdf.stroke(0);
  PVector pb = graphToPDF(xB, xB);
  PVector pf = graphToPDF(zF, zF);
  PVector pd = graphToPDF(xD, xD);
  pdf.ellipse(pb.x, pb.y, 8, 8);
  pdf.ellipse(pf.x, pf.y, 8, 8);
  pdf.ellipse(pd.x, pd.y, 8, 8);
}

// Dibuja las etiquetas de los ejes X e Y en el PDF
void dibujarEjesPDF(PGraphics pdf) {
  pdf.stroke(0);
  pdf.strokeWeight(2);
  pdf.textSize(12);
  pdf.fill(0);
  
  // Eje X (horizontal, base)
  PVector xMinPoint = graphToPDF(X_MIN, Y_MIN);
  PVector xMaxPoint = graphToPDF(X_MAX, Y_MIN);
  pdf.line(xMinPoint.x, xMinPoint.y, xMaxPoint.x, xMaxPoint.y);  // Línea del eje X
  for (float x = X_MIN; x <= X_MAX; x += STEP) {
    PVector p = graphToPDF(x, Y_MIN);
    pdf.line(p.x, p.y, p.x, p.y + 10);  // Ticks en el eje X
    pdf.textAlign(CENTER, TOP);
    pdf.text(nf(x, 0, 2), p.x, p.y + 15);  // Etiqueta del eje X
  }

  // Eje Y (vertical, lado izquierdo)
  PVector yMinPoint = graphToPDF(X_MIN, Y_MIN);
  PVector yMaxPoint = graphToPDF(X_MIN, Y_MAX);
  pdf.line(yMinPoint.x, yMinPoint.y, yMaxPoint.x, yMaxPoint.y);  // Línea del eje Y
  for (float y = Y_MIN; y <= Y_MAX; y += STEP) {
    PVector p = graphToPDF(X_MIN, y);
    pdf.line(p.x, p.y, p.x - 10, p.y);  // Ticks en el eje Y (corrige la dirección)
    pdf.textAlign(RIGHT, CENTER);
    pdf.text(nf(y, 0, 2), p.x - 15, p.y);  // Etiqueta del eje Y, ajustadas para no solapar
  }
}

// Dibuja el área de texto con el resultado del cálculo en el PDF
void dibujarVentanaTextoPDF(PGraphics pdf) {
  final int TEXT_WINDOW_X = 50;  // Posición izquierda del cuadro de texto
  final int TEXT_WINDOW_Y = 695;  // Nueva posición vertical del cuadro de texto
  final int TEXT_WINDOW_WIDTH = 300;  // Nuevo ancho del cuadro de texto
  final int TEXT_WINDOW_HEIGHT = 40;  // Altura del cuadro de texto

  pdf.fill(255);
  pdf.stroke(0);
  pdf.rect(TEXT_WINDOW_X, TEXT_WINDOW_Y, TEXT_WINDOW_WIDTH, TEXT_WINDOW_HEIGHT);

  pdf.fill(0);
  pdf.textSize(12);
  pdf.textAlign(LEFT, TOP);
  pdf.text(logText, TEXT_WINDOW_X + 5, TEXT_WINDOW_Y + 5, TEXT_WINDOW_WIDTH - 10, TEXT_WINDOW_HEIGHT - 10);
}

// Dibuja las etapas en el PDF
void dibujarEtapasPDF(PGraphics pdf) {
  if (!calcularEtapasPresionado) return;

  pdf.strokeWeight(3);

  // Dibuja líneas horizontales de las etapas (hacia la izquierda)
  for (int i = 0; i < etapasHoriz.size() - 1; i += 2) {
    PVector inicio = etapasHoriz.get(i);
    PVector fin = etapasHoriz.get(i + 1);
    PVector p1 = graphToPDF(inicio.x, inicio.y);
    PVector p2 = graphToPDF(fin.x, fin.y);
    pdf.stroke(255);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
    pdf.stroke(0);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
  }

  // Dibuja líneas verticales de las etapas (descendentes)
  for (int i = 0; i < etapasVert.size() - 1; i += 2) {
    PVector inicio = etapasVert.get(i);
    PVector fin = etapasVert.get(i + 1);
    PVector p1 = graphToPDF(inicio.x, inicio.y);
    PVector p2 = graphToPDF(fin.x, fin.y);
    pdf.stroke(255);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
    pdf.stroke(0);
    pdf.line(p1.x, p1.y, p2.x, p2.y);
  }

  pdf.strokeWeight(1);
}

float calcularArea() {
  int pasos = 1000;
  float dx = (xD - xB) / pasos;
  float area = 0;

  for (int i = 0; i < pasos; i++) {
    float x1 = xB + i * dx;
    float x2 = xB + (i + 1) * dx;

    float yEq1 = (RELATIVE_VOLATILITY * x1) / (1 + (RELATIVE_VOLATILITY - 1) * x1);
    float yEq2 = (RELATIVE_VOLATILITY * x2) / (1 + (RELATIVE_VOLATILITY - 1) * x2);

    float y45_1 = x1;
    float y45_2 = x2;

    float superior1 = min(yEq1, xD);
    float superior2 = min(yEq2, xD);
    float inferior1 = y45_1;
    float inferior2 = y45_2;

    float altura1 = max(0, superior1 - inferior1);
    float altura2 = max(0, superior2 - inferior2);
    area += 0.5 * (altura1 + altura2) * dx;
  }

  return area;
}

boolean estaDentroDelArea(float x, float y) {
  float yEquilibrio = (RELATIVE_VOLATILITY * x) / (1 + (RELATIVE_VOLATILITY - 1) * x);
  float ySuperior = min(xD, yEquilibrio);
  return (x >= xB && x <= xD && y >= x && y <= ySuperior);
}

public void volver() {
  println("Botón Volver presionado, restaurando valores iniciales");
  
  // Restaurar valores iniciales usando resetValores
  resetValores();
  
  // Ocultar advertencia y limpiar botón
  mostrarAdvertencia = false;
  if (volverButton != null) {
    volverButton.remove();
    volverButton = null;
    println("Botón Volver eliminado");
  }
  
  // Desbloquear botones de fondo
  calcularRminButton.unlock();
  resetValoresButton.unlock();
  calcularEtapasButton.unlock();
  exportarInformeButton.unlock();
  generarPDFButton.unlock();
}
