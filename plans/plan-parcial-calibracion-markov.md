# Plan: Parcial de calibración del modelo Markov-modulado

> Fuente principal: [Julian Alejandro Archila Caro - Parcial Calibracion Markov Modulado.pdf](../Julian%20Alejandro%20Archila%20Caro%20-%20Parcial%20Calibracion%20Markov%20Modulado.pdf)

## 1. Contexto

Este parcial completa el trabajo de los talleres anteriores sobre valoración de opciones bajo un modelo de volatilidad Markov-modulado con dos regímenes. En los talleres se asumían conocidos los parámetros

\[
\theta=(\sigma_0,\sigma_1,\lambda_0,\lambda_1).
\]

El parcial plantea el problema inverso: estimar esos parámetros a partir de precios reales de opciones. El subyacente asignado a Julián Alejandro Archila Caro es el ETF **SPY**.

El trabajo debe integrar tres rutas de valoración:

1. **Ruta A - Fórmula analítica:** mezcla de precios Black-Scholes sobre la distribución de la varianza integrada.
2. **Ruta B - Fourier/COS:** implementación desarrollada en el Taller 2.
3. **Ruta C - EDP acoplada:** diferencias finitas desarrolladas en el Taller 3/4.

La calibración principal utiliza una tasa constante común a ambos regímenes,
\(r_0=r_1=r\). El régimen modula la volatilidad, no la tasa. Esto permite usar simultáneamente las tres rutas. La posibilidad \(r_0\ne r_1\) queda reservada para una extensión opcional.

El resultado debe ser reproducible: la cadena de opciones se congela en un CSV, las semillas aleatorias se fijan y cada tabla o figura debe poder regenerarse mediante instrucciones documentadas.

## 2. Material de referencia

### Enunciado oficial

- [PDF del parcial](../Julian%20Alejandro%20Archila%20Caro%20-%20Parcial%20Calibracion%20Markov%20Modulado.pdf)

### Taller 2: Fourier, FFT y COS

- [Notebook principal del Taller 2](../reference/taller2/Taller_2_Metodos.ipynb)
- [Resultados del Taller 2](../reference/taller2/Resultados.pdf)
- [Notebook de trabajo del Taller 2](../reference/taller2/wip.ipynb)

Componentes reutilizables identificados:

- función característica del log-retorno Markov-modulado;
- Carr-Madan FFT;
- método COS para calls y puts;
- precios Black-Scholes;
- inversión de volatilidad implícita;
- pruebas de consistencia entre FFT y COS;
- sensibilidades y Greeks que pueden servir para la extensión opcional.

La comparación existente entre FFT y COS alcanza diferencias cercanas a
\(2\times10^{-7}\) para los parámetros de prueba del curso.

### Taller 3/4: EDP y Monte Carlo

- [Notebook principal del Taller 3](../reference/taller3/Taller3.ipynb)
- [Enunciado de diferencias finitas y Monte Carlo](../reference/taller3/Taller%20Diferencias%20Finitas%20y%20Monte%20Carlo.pdf)
- [Rúbrica del Taller 3](../reference/taller3/Rubrica%20Taller%203.pdf)

Componentes reutilizables identificados:

- EDP acoplada para puts europeas;
- EDP acoplada para calls europeas;
- esquema \(\theta\), especialmente Crank-Nicolson con \(\theta=1/2\);
- análisis de convergencia espacial y temporal;
- paridad call-put;
- simuladores Monte Carlo con semillas fijas;
- valoración de opciones exóticas, útil si se desarrolla la extensión E2.

La EDP existente presenta convergencia aproximadamente de segundo orden con
Crank-Nicolson. Para la validación del parcial probablemente será necesario usar
una malla cercana a \(M=N_t=800\) para obtener error inferior a \(10^{-3}\).

## 3. Objetivo y definición de terminado

El parcial estará terminado cuando se pueda ejecutar un flujo reproducible que:

1. genere o lea un snapshot congelado de opciones de SPY;
2. implemente correctamente la fórmula analítica por mezcla;
3. demuestre que las rutas A, B y C coinciden dentro de la tolerancia exigida;
4. calibre \(\theta\) mediante brute force, Nelder-Mead y BFGS;
5. compare al menos dos esquemas de ponderación;
6. diagnostique sensibilidad, identificabilidad y posibles óptimos locales;
7. compare el modelo Markov-modulado contra Black-Scholes plano;
8. produzca automáticamente las tablas y figuras del informe;
9. incluya un informe de máximo 12 páginas, código, CSV y README.

## 4. Decisiones duraderas

- **Subyacente:** SPY.
- **Modelo principal:** dos regímenes con
  \(\theta=(\sigma_0,\sigma_1,\lambda_0,\lambda_1)\).
- **Convención de etiquetas:** imponer \(0<\sigma_0<\sigma_1\).
- **Intensidades:** \(\lambda_0,\lambda_1>0\).
- **Tasas durante la calibración:** \(r_0=r_1=r\).
- **Dividendos:** incorporar una tasa \(q\) y trabajar con
  \(F=S_0e^{(r-q)T}\), o de manera equivalente con spot ajustado
  \(S_0e^{-qT}\). La convención elegida debe usarse en todo el proyecto.
- **Régimen inicial desconocido:** usar inicialmente la distribución
  estacionaria
  \(\pi_0=\lambda_1/(\lambda_0+\lambda_1)\) y
  \(\pi_1=1-\pi_0\).
- **Motor dentro de la calibración:** COS vectorizado.
- **Rutas de verificación:** fórmula analítica y EDP.
- **Objetivo principal:** RMSE en volatilidad implícita.
- **Reproducibilidad:** datos congelados, configuración explícita y semillas
  fijas.
- **Estructura de trabajo:** desarrollar el parcial completo en un único notebook
  reproducible. Los notebooks anteriores se conservan como referencia y las
  funciones necesarias se incorporan, limpian y documentan en el notebook del
  parcial.

## 5. Orden general de ejecución

```text
Preparar proyecto
      ↓
Congelar y validar datos SPY
      ↓
Implementar Ruta A
      ↓
Validar A ↔ B ↔ C
      ↓
Construir objetivo de calibración
      ↓
Ejecutar los tres optimizadores
      ↓
Diagnosticar las soluciones
      ↓
Analizar e interpretar
      ↓
Generar informe y paquete reproducible
```

---

## Fase 1: Base reproducible y extracción del código previo

**Cubre:** infraestructura transversal y reutilización de los Talleres 2 y 3/4.

### Qué construir

Crear un notebook ejecutable de principio a fin y trasladar a él las
implementaciones necesarias de los notebooks anteriores. El objetivo no es
copiar los talleres completos, sino incorporar una versión limpia y verificable
de Black-Scholes, función característica, COS, FFT, EDP e inversión de
volatilidad implícita.

### Pasos

1. Organizar un único notebook con secciones que sigan el orden del parcial.
2. Registrar las dependencias y la versión de Python.
3. Incorporar las funciones reutilizables de los talleres sin modificar los
   notebooks originales.
4. Unificar nombres inconsistentes como `S0/SO`, `sigma1/sigmal` y
   `lam0/lamo`.
5. Añadir validaciones de dominio para vencimientos, volatilidades, intensidades,
   régimen y strikes.
6. Crear una celda inicial para rutas, tolerancias, semillas y parámetros
   numéricos.
7. Añadir y ejecutar celdas de validación para Black-Scholes, función
   característica, COS y EDP.
8. Registrar qué fragmentos provienen de cada taller.

### Criterios de aceptación

- [ ] El entorno puede instalarse desde instrucciones escritas.
- [ ] El notebook puede ejecutarse completo desde un kernel reiniciado.
- [ ] Los notebooks de los talleres permanecen intactos.
- [ ] COS y FFT reproducen la comparación previa con error del orden de
      \(10^{-6}\) o menor.
- [ ] La EDP reproduce los resultados de referencia del Taller 3.
- [ ] Las validaciones rápidas están agrupadas al inicio del notebook.

---

## Fase 2: Snapshot reproducible de opciones de SPY

**Cubre:** Parte 0 - Datos, 10% de la nota.

### Qué construir

Crear el conjunto de mercado que alimentará toda la calibración. La descarga se
ejecutará una vez y el resto del proyecto trabajará exclusivamente contra el CSV
congelado.

### Pasos

1. Descargar spot y cadena de opciones de SPY para al menos 5 o 6 vencimientos
   distribuidos aproximadamente entre un mes y un año.
2. Guardar fecha, hora, zona horaria, spot y fuente de los datos.
3. Conservar inicialmente calls y puts, aunque después pueda seleccionarse un
   subconjunto más limpio.
4. Calcular `mid=(bid+ask)/2`.
5. Eliminar cotizaciones con:
   - bid o ask inválidos;
   - spread excesivo;
   - volumen e interés abierto nulos o insuficientes;
   - precios que violen cotas básicas de no arbitraje;
   - moneyness fuera del intervalo sugerido
     \(0.8\le K/S_0\le1.2\).
6. Definir \(T\) usando una convención explícita de días.
7. Fijar y documentar la curva o aproximación de tasa libre de riesgo \(r(T)\).
8. Fijar y documentar la tasa de dividendos \(q(T)\) de SPY.
9. Calcular volatilidad implícita y vega Black-Scholes para cada observación.
10. Guardar tanto el snapshot crudo como el conjunto filtrado.
11. Producir una tabla de conteos por vencimiento y tipo de opción.
12. Crear gráficos exploratorios de precios, spreads e IV observada.

### Columnas mínimas del conjunto calibrable

- fecha del snapshot;
- vencimiento;
- tipo (`call` o `put`);
- \(S_0\), \(K\), \(T\);
- bid, ask, mid y spread;
- volumen e interés abierto;
- \(r\) y \(q\);
- forward;
- volatilidad implícita de mercado;
- vega;
- indicador o razón de moneyness.

### Criterios de aceptación

- [ ] Hay al menos 5 vencimientos utilizables.
- [ ] El CSV contiene únicamente datos congelados, no consultas en vivo.
- [ ] Los filtros son deterministas y están documentados.
- [ ] Todas las observaciones finales tienen precio, IV y vega finitos.
- [ ] Existe una tabla con el número de cotizaciones por vencimiento.
- [ ] La descarga puede repetirse, pero la calibración no depende de repetirla.

---

## Fase 3: Ruta A - Fórmula analítica por mezcla

**Cubre:** Parte A, 20% de la nota.

### Qué construir

Implementar el precio europeo condicionado al régimen inicial como la suma del
átomo de “ningún cambio de régimen” y la integral de Black-Scholes contra la
densidad continua de la varianza integrada.

### Pasos

1. Implementar Black-Scholes usando **varianza total** \(a\), no únicamente una
   volatilidad anualizada.
2. Implementar:
   - soporte \(a_-=\sigma_0^2T\), \(a_+=\sigma_1^2T\);
   - \(\Delta_\sigma=\sigma_1^2-\sigma_0^2\);
   - \(\eta(a)\);
   - \(\Gamma(a)\);
   - densidades continuas \(g_0^A(a,T)\) y \(g_1^A(a,T)\);
   - masas atómicas \(e^{-\lambda_iT}\).
3. Implementar la tasa integrada
   \(R(a)=r_0T+(r_1-r_0)(a-\sigma_0^2T)/\Delta_\sigma\).
4. Evaluar dentro de Black-Scholes la tasa efectiva \(R(a)/T\).
5. Tratar de forma estable las funciones de Bessel modificadas.
6. Controlar las singularidades integrables en los extremos mediante cambio de
   variable o cuadratura adaptativa.
7. Implementar calls y puts, o justificar la obtención de puts mediante paridad
   cuando \(r_0=r_1\).
8. Definir explícitamente el comportamiento cuando
   \(\sigma_1-\sigma_0\) se aproxima a cero.

### Pruebas obligatorias

1. **Masa total**

   \[
   e^{-\lambda_iT}+\int_{a_-}^{a_+}g_i^A(a,T)\,da=1
   \]

   para ambos regímenes, con error objetivo menor o igual a \(10^{-6}\).

2. **Caso sin régimen efectivo**

   Cuando \(\sigma_0\to\sigma_1\), el precio converge a Black-Scholes plano.

3. **Cota de volatilidades**

   Para \(r_0=r_1\), el precio debe quedar entre los precios Black-Scholes
   correspondientes a \(a_-\) y \(a_+\).

4. **Sanidad financiera**

   Positividad, cotas de no arbitraje y monotonía básica respecto al strike.

### Criterios de aceptación

- [ ] La masa total cumple el error exigido en ambos regímenes.
- [ ] El caso singular tiene un tratamiento explícito y probado.
- [ ] La cota Black-Scholes se cumple para una batería de parámetros.
- [ ] La cuadratura no produce `NaN`, overflow ni advertencias ignoradas.
- [ ] Calls y puts satisfacen paridad cuando \(r_0=r_1\).

---

## Fase 4: Validación cruzada de las tres rutas

**Cubre:** Parte B, 20% de la nota.

### Qué construir

Demostrar numéricamente que la fórmula analítica, COS/FFT y la EDP calculan el
mismo precio.

### Caso base

\[
S_0=100,\quad T=0.5,\quad r=0.03,\quad
\sigma_0=0.15,\quad\sigma_1=0.40,\quad
\lambda_0=2,\quad\lambda_1=5.
\]

Evaluar \(K\in\{90,100,110\}\) y ambos regímenes iniciales.

### Pasos

1. Elegir un único payoff para la tabla, preferiblemente calls.
2. Convertir las puts de la EDP mediante paridad o usar directamente la EDP para
   calls.
3. Calcular los precios con:
   - Ruta A: mezcla analítica;
   - Ruta B: COS y, como control adicional, FFT;
   - Ruta C: Crank-Nicolson.
4. Refinar cuadratura, \(N\), intervalo COS y malla EDP hasta separar las fuentes
   de error.
5. Reportar \(|A-B|\), \(|A-C|\) y \(|B-C|\).
6. Repetir algunas pruebas con otros vencimientos y parámetros para evitar una
   validación basada en un único caso.
7. Medir tiempos de ejecución para justificar el uso de COS durante la
   calibración.
8. Documentar si cada discrepancia proviene de cuadratura, truncamiento espectral
   o discretización de la EDP.

### Criterios de aceptación

- [ ] La tabla contiene 3 strikes por 2 regímenes.
- [ ] Todas las diferencias principales son menores o cercanas a \(10^{-3}\).
- [ ] La EDP muestra convergencia al refinar la malla.
- [ ] COS permanece estable para los parámetros usados.
- [ ] El informe explica la fuente dominante de error numérico.

---

## Fase 5: Precio de mercado del modelo y objetivo en IV

**Cubre:** primera mitad de la Parte C.

### Qué construir

Convertir las funciones de valoración en un motor vectorizado que produzca
precios e IV del modelo para toda la cadena filtrada.

### Pasos

1. Calcular la distribución estacionaria:

   \[
   \pi_0=\frac{\lambda_1}{\lambda_0+\lambda_1},
   \qquad
   \pi_1=\frac{\lambda_0}{\lambda_0+\lambda_1}.
   \]

2. Formar el precio no condicionado:

   \[
   C^{\mathrm{mod}}=\pi_0C_0+\pi_1C_1.
   \]

3. Agrupar cotizaciones por vencimiento para reutilizar evaluaciones COS.
4. Vectorizar sobre strikes y evitar trabajo repetido dentro del optimizador.
5. Convertir precios del modelo a volatilidad implícita de manera robusta.
6. Penalizar precios inválidos sin interrumpir la optimización.
7. Implementar el RMSE en IV con al menos:
   - pesos uniformes;
   - pesos basados en vega o una normalización derivada de vega.
8. Definir claramente si los pesos se normalizan por vencimiento, globalmente o
   por observación.
9. Parametrizar las restricciones para garantizar positividad y
   \(\sigma_0<\sigma_1\), preferiblemente mediante transformaciones en vez de
   penalizaciones discontinuas.
10. Añadir opcionalmente regularización de Tikhonov hacia un prior documentado.

### Criterios de aceptación

- [ ] El objetivo devuelve siempre un escalar finito.
- [ ] Los parámetros producidos siempre pertenecen a la región factible.
- [ ] La mezcla estacionaria suma uno y responde correctamente a las lambdas.
- [ ] Los dos esquemas de ponderación están implementados y probados.
- [ ] El tiempo por evaluación permite ejecutar cientos o miles de iteraciones.

---

## Fase 6: Calibración con tres optimizadores

**Cubre:** núcleo de la Parte C, 30% total.

### Qué construir

Calibrar el modelo con las tres técnicas exigidas por Hirsa y comparar precisión,
tiempo y sensibilidad al punto inicial.

### Pasos

1. Definir cotas económicamente razonables para volatilidades e intensidades.
2. Elegir varios puntos iniciales, incluyendo uno razonable y otros perturbados.
3. Ejecutar una búsqueda exhaustiva en malla sobre una caja inicial.
4. Usar el mejor punto de la malla como inicio de Nelder-Mead.
5. Usar el mismo punto como inicio de BFGS.
6. Si BFGS trabaja sobre parámetros transformados, aplicar correctamente la
   transformación inversa al reportar resultados.
7. Registrar para cada corrida:
   - parámetros;
   - RMSE;
   - número de evaluaciones;
   - tiempo;
   - estado de convergencia;
   - punto inicial;
   - esquema de pesos.
8. Repetir la calibración para ambos esquemas de ponderación.
9. Considerar una ejecución opcional de `differential_evolution` seguida de
   refinamiento local como control, sin reemplazar las tres técnicas obligatorias.
10. Seleccionar la solución final usando calidad de ajuste, estabilidad y
    factibilidad, no sólo el menor RMSE observado.
11. Verificar entre 3 y 4 precios de la solución final usando la Ruta A.

### Tabla mínima de resultados

| Método | Pesos | Punto inicial | \(\hat\sigma_0\) | \(\hat\sigma_1\) | \(\hat\lambda_0\) | \(\hat\lambda_1\) | RMSE IV | Tiempo | Estado |
|---|---|---|---:|---:|---:|---:|---:|---:|---|

### Criterios de aceptación

- [ ] Se ejecutaron brute force, Nelder-Mead y BFGS.
- [ ] Los tres métodos usan exactamente el mismo conjunto de mercado.
- [ ] Se reporta sensibilidad al punto inicial.
- [ ] Se comparan al menos dos ponderaciones.
- [ ] La solución final satisface todas las restricciones.
- [ ] Entre 3 y 4 precios finales fueron verificados con la Ruta A.

---

## Fase 7: Diagnóstico del paisaje e identificabilidad

**Cubre:** Sección 6.3 y parte de las preguntas de la Parte D.

### Qué construir

Determinar si las soluciones de los optimizadores pertenecen a una misma cuenca
y qué combinaciones de parámetros están mal identificadas.

### Pasos

1. Seleccionar al menos dos pares de soluciones:
   - malla frente a BFGS;
   - Nelder-Mead frente a BFGS.
2. Evaluar

   \[
   \theta(\alpha)=\alpha\hat\theta_1+(1-\alpha)\hat\theta_2
   \]

   para \(\alpha\in[-0.5,1.5]\).
3. Recortar o marcar combinaciones que violen factibilidad.
4. Graficar RMSE contra \(\alpha\) y marcar \(\alpha=0,1\).
5. Interpretar forma en U, planicies, jorobas o mínimos separados.
6. Aproximar Hessiano o perfiles unidimensionales alrededor del óptimo.
7. Perturbar precios o subconjuntos del mercado y recalibrar para medir
   estabilidad.
8. Separar parámetros bien determinados de combinaciones débilmente
   identificadas.
9. Evaluar si una regularización de Tikhonov mejora estabilidad sin degradar de
   manera material el ajuste.

### Criterios de aceptación

- [ ] Hay al menos dos curvas de combinaciones afines.
- [ ] Las regiones no factibles están identificadas.
- [ ] Se distingue tolerancia numérica de óptimos locales genuinos.
- [ ] El análisis identifica direcciones planas o parámetros inestables.
- [ ] Las conclusiones están respaldadas por figuras o cálculos.

---

## Fase 8: Ajuste, comparación y análisis económico

**Cubre:** Parte D, 15% de la nota.

### Qué construir

Transformar los parámetros calibrados y los diagnósticos numéricos en respuestas
económicas y estadísticas concisas.

### Pasos

1. Graficar la sonrisa de IV de mercado y modelo por vencimiento.
2. Mostrar residuos por strike, moneyness y vencimiento.
3. Calibrar un único \(\sigma\) Black-Scholes sobre el mismo conjunto y con el
   mismo criterio.
4. Comparar RMSE de Black-Scholes contra el modelo de regímenes.
5. Evaluar si la mejora justifica los parámetros adicionales.
6. Calibrar por vencimiento separado y comparar contra la calibración conjunta.
7. Analizar estabilidad de \(\sigma_0,\sigma_1\) y de
   \(\lambda_0,\lambda_1\) a través del plazo.
8. Calcular:
   - duraciones esperadas \(1/\lambda_i\);
   - probabilidades estacionarias \(\pi_i\);
   - tiempo de mezcla aproximado \(1/(\lambda_0+\lambda_1)\).
9. Interpretar el régimen de baja y alta volatilidad.
10. Explicar por qué \(r_0\ne r_1\) no es identificable con opciones de un único
    subyacente y qué datos adicionales serían necesarios.
11. Redactar cada respuesta de la Parte D en uno o dos párrafos, como exige el
    enunciado.

### Criterios de aceptación

- [ ] Hay una figura de mercado frente a modelo por vencimiento.
- [ ] Existe una calibración Black-Scholes comparable.
- [ ] Se cuantifica la mejora de ajuste.
- [ ] Se comparan calibraciones separadas y conjunta.
- [ ] Se reportan duraciones, probabilidades y tiempo de mezcla.
- [ ] Todas las respuestas de la Parte D están sustentadas por resultados.

---

## Fase 9: Extensión opcional

**Cubre:** Parte E, hasta +10%.

### Decisión recomendada

Priorizar **E1: \(r_0\ne r_1\), fórmula analítica frente a EDP**, porque reutiliza
directamente las dos implementaciones centrales y demuestra la ventaja conceptual
de la mezcla sobre COS.

### Pasos para E1

1. Tomar \(\hat\theta\) calibrado con \(r_0=r_1\).
2. Elegir un par \(r_0\ne r_1\) claramente documentado.
3. Revalorar una opción con la fórmula analítica usando \(R(a)\).
4. Revalorar la misma opción con la EDP acoplada.
5. Mostrar coincidencia dentro de la tolerancia numérica.
6. Mostrar que COS con descuento factorizado no reproduce ese precio.
7. Explicar la dependencia del camino y la no identificabilidad de dos tasas con
   un solo subyacente.

### Alternativas

- **E2:** asiática o digital con parámetros calibrados y propagación de
  incertidumbre.
- **E3:** Delta y Gamma analíticas frente a bumping.

### Criterios de aceptación

- [ ] La extensión no retrasa ni sustituye componentes obligatorios.
- [ ] La comparación utiliza los parámetros calibrados.
- [ ] La conclusión se apoya en resultados numéricos reproducibles.

---

## Fase 10: Informe y entrega reproducible

**Cubre:** calidad del informe y reproducibilidad, 5%, además del criterio
transversal de toda la rúbrica.

### Qué construir

Generar el paquete final sin depender de pasos manuales ocultos.

### Estructura sugerida del informe

1. Introducción y modelo.
2. Datos de SPY y filtros.
3. Fórmula analítica y pruebas internas.
4. Validación cruzada A/B/C.
5. Metodología de calibración.
6. Resultados y diagnósticos.
7. Comparación con Black-Scholes.
8. Interpretación y respuestas de la Parte D.
9. Conclusiones.
10. Extensión opcional, si se realiza.

### Pasos

1. Seleccionar únicamente tablas y figuras que respondan preguntas de la
   rúbrica.
2. Mantener el cuerpo principal dentro de 12 páginas.
3. Mover detalles de implementación, tablas extensas y pruebas secundarias a
   apéndices.
4. Numerar y referenciar todas las figuras y tablas.
5. Incluir parámetros numéricos y tolerancias suficientes para reproducir cada
   resultado.
6. Crear un README con:
   - instalación;
   - procedencia de los datos;
   - orden de ejecución;
   - comandos para cada tabla y figura;
   - semillas;
   - tiempos aproximados;
   - limitaciones conocidas.
7. Ejecutar el proyecto desde un entorno limpio.
8. Regenerar todas las salidas finales.
9. Revisar el PDF visualmente para detectar ecuaciones cortadas, texto ilegible o
   referencias rotas.
10. Empaquetar informe, código, CSV y README.

### Criterios de aceptación

- [ ] El informe tiene máximo 12 páginas sin contar apéndices.
- [ ] Todas las figuras y tablas se regeneran desde el código entregado.
- [ ] El README permite reproducir el trabajo en orden.
- [ ] Las semillas están fijadas.
- [ ] El código no consulta datos en vivo durante la calibración.
- [ ] El PDF final fue revisado visualmente.
- [ ] No quedan resultados sin explicación de error o limitaciones.

## 6. Correspondencia con la rúbrica

| Componente | Peso | Fases |
|---|---:|---|
| Parte 0 - Datos | 10% | 2 |
| Parte A - Fórmula analítica | 20% | 3 |
| Parte B - Validación cruzada | 20% | 4 |
| Parte C - Calibración y diagnóstico | 30% | 5, 6 y 7 |
| Parte D - Análisis e interpretación | 15% | 7 y 8 |
| Calidad y reproducibilidad | 5% | 1 y 10 |
| Parte E - Extensión | +10% | 9 |

## 7. Orden de prioridad si el tiempo es limitado

1. Datos reproducibles.
2. Fórmula analítica y pruebas internas.
3. Validación A/B/C.
4. Calibración con los tres métodos.
5. Comparación de ponderaciones y verificación final con Ruta A.
6. Diagnóstico por segmentos.
7. Parte D y comparación con Black-Scholes.
8. Pulido del informe.
9. Extensión opcional.

No debe iniciarse la extensión mientras exista algún criterio obligatorio sin
cumplir.

## 8. Riesgos principales y mitigaciones

| Riesgo | Consecuencia | Mitigación |
|---|---|---|
| Datos de SPY ilíquidos o inconsistentes | IV inválida y calibración inestable | Filtros explícitos, cotas de arbitraje y reporte por vencimiento |
| Singularidades de la densidad analítica | Cuadratura inestable | Cambio de variable, cuadratura adaptativa y pruebas de masa |
| Caso \(\sigma_0\approx\sigma_1\) | División por un \(\Delta_\sigma\) pequeño | Rama degenerada explícita hacia Black-Scholes |
| COS inestable en regiones extremas | Objetivo discontinuo | Truncamiento validado, control de precios y comparación puntual con Ruta A |
| Inversión repetida de IV demasiado lenta | Calibración impráctica | Agrupación por vencimiento, vectorización y tolerancias adecuadas |
| Simetría de etiquetas | Soluciones duplicadas | Imponer \(\sigma_0<\sigma_1\) mediante parametrización |
| Superficies de error planas | Lambdas inestables | Múltiples inicios, perfiles, regularización y reporte honesto |
| EDP por encima de \(10^{-3}\) | Incumplimiento de Parte B | Refinar malla y presentar estudio de convergencia |
| Exceso de resultados | Informe mayor de 12 páginas | Diseñar el informe alrededor de la rúbrica y usar apéndices |

## 9. Lista maestra de entregables

- [ ] Snapshot crudo de SPY.
- [ ] CSV filtrado usado en calibración.
- [ ] Registro de fecha, hora, spot, tasas y dividendos.
- [ ] Código reutilizado de Taller 2 y Taller 3/4, integrado y documentado en el notebook.
- [ ] Fórmula analítica por mezcla.
- [ ] Pruebas de masa, degeneración y cota.
- [ ] Tabla de validación A/B/C.
- [ ] Motor COS vectorizado.
- [ ] Objetivos con dos ponderaciones.
- [ ] Brute force.
- [ ] Nelder-Mead.
- [ ] BFGS.
- [ ] Tabla comparativa de calibraciones.
- [ ] Verificación final con Ruta A.
- [ ] Curvas de RMSE sobre combinaciones afines.
- [ ] Comparación contra Black-Scholes.
- [ ] Calibración conjunta y por vencimiento.
- [ ] Interpretación económica.
- [ ] Figuras finales.
- [ ] Informe PDF.
- [ ] README de reproducción.
- [ ] Extensión opcional, sólo si lo obligatorio está completo.
