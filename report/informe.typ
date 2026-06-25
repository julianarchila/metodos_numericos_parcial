// ============================================================================
//  Informe — Parcial: Calibración del modelo Markov-modulado a opciones de SPY
//  Métodos Numéricos en Finanzas — Universidad Nacional de Colombia
//  Compilar (desde la raíz del repositorio):
//     typst compile --root . report/informe.typ report/Informe_Parcial.pdf
// ============================================================================

#set page(
  paper: "a4",
  margin: (x: 2.4cm, y: 2.5cm),
  numbering: "1",
  number-align: center,
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 8.5pt, fill: rgb(40, 40, 40))
      #grid(columns: (1fr, 1fr),
        align(left)[Métodos Numéricos en Finanzas],
        align(right)[Calibración del modelo Markov-modulado · SPY],
      )
      #line(length: 100%, stroke: 0.4pt + rgb(150, 150, 150))
    ]
  },
)

#set text(font: ("Libertinus Serif", "New Computer Modern", "DejaVu Serif"), size: 10.5pt, lang: "es")
#set par(justify: true, leading: 0.62em, spacing: 0.95em)
#show math.equation: set text(size: 10pt)

// Encabezados de sección con numeración
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  set text(size: 13pt, weight: "bold")
  v(0.6em)
  block[#counter(heading).display() #h(0.4em) #it.body]
  v(0.2em)
}
#show heading.where(level: 2): it => {
  set text(size: 11pt, weight: "bold")
  v(0.3em)
  block[#counter(heading).display() #h(0.3em) #it.body]
}

// Estilo de tablas
#set table(stroke: none, inset: (x: 6pt, y: 3.5pt), align: horizon)
#show table.cell.where(y: 0): strong

// Numeración de figuras y tablas
#show figure.where(kind: image): set figure(supplement: "Figura")
#show figure.where(kind: table): set figure(supplement: "Tabla")
#show figure.caption: set text(size: 9pt)

// ============================ PORTADA ======================================

#align(center)[
  #v(0.4em)
  #text(size: 9.5pt, tracking: 0.5pt)[UNIVERSIDAD NACIONAL DE COLOMBIA]\
  #text(size: 9pt, fill: rgb(70,70,70))[Departamento de Matemáticas · Métodos Numéricos en Finanzas]
  #v(1.0em)
  #line(length: 70%, stroke: 0.6pt)
  #v(0.6em)
  #text(size: 17pt, weight: "bold")[Informe del parcial]\
  #v(0.2em)
  #text(size: 13pt)[Calibración del modelo Markov-modulado a opciones de SPY]
  #v(0.5em)
  #line(length: 70%, stroke: 0.6pt)
  #v(0.8em)
  #text(size: 11pt, weight: "bold")[Julián Alejandro Archila Caro]\
  #v(0.2em)
  #text(size: 9.5pt, fill: rgb(70,70,70))[Snapshot de mercado: 24 de junio de 2026]
]
#v(1.2em)

// ============================ 1. INTRODUCCIÓN ==============================

= Introducción y modelo

La volatilidad de SPY se modela con una cadena de Markov $epsilon(t)$ de dos estados, con
parámetros $theta = (sigma_0, sigma_1, lambda_0, lambda_1)$. El objetivo es estimar $theta$ a
partir de una cadena real de opciones (el problema inverso). La dinámica bajo la medida
martingala $QQ$ es
$ dif S_t = S_t thin r thin dif t + S_t thin sigma_(epsilon(t)) thin dif W_t^QQ, wide
  Q = mat(-lambda_0, lambda_0; lambda_1, -lambda_1), $
con distribución estacionaria $pi_0 = lambda_1 \/ (lambda_0 + lambda_1)$, $pi_1 = 1 - pi_0$.

Se calibra con una *tasa común* $r_0 = r_1 = r$: un solo subyacente da una sola curva de
tasa, así que el régimen modula la volatilidad, no la tasa. Con $r_0 = r_1$ el descuento es
$e^(-r T)$ y las tres rutas de valoración coinciden, lo que permite validarlas entre sí. Se
usan tres: la fórmula analítica por mezcla sobre la varianza integrada (Ruta A,
@sec-analitica), Fourier/COS (Ruta B) y la EDP acoplada (Ruta C). COS es el motor de la
calibración (@sec-calibracion).

// ============================ 2. DATOS ====================================

= Datos de mercado (Parte 0) <sec-datos>

*Snapshot congelado.* La cadena de opciones de SPY se descargó *una sola vez* con
`yfinance` el 24 de junio de 2026 (22:34 UTC) y se almacenó en `data/spy_options_raw.csv`;
toda la calibración corre contra ese archivo, nunca contra una descarga en vivo. El spot fue
$S_0 = 733","24$. Se fijó la tasa libre de riesgo $r = 3","69%$ (#box[T-bill] a 13 semanas `^IRX`,
usado como curva plana coherente con $r_0 = r_1$) y la tasa de dividendos $q = 1","27%$
(dividendos de los últimos 365 días sobre el spot). Se trabaja con el forward
$F = S_0 e^((r-q)T)$ y conteo de días *ACT/365*; el dividendo se absorbe en el spot ajustado
$S_0 e^(-q T)$ dentro del motor de valoración. Se usa el precio `mid` $= ("bid"+"ask")\/2$.

*Filtrado determinista.* Partiendo de $2497$ cotizaciones crudas (calls y puts en siete
vencimientos entre $30$ y $358$ días), se aplican en cascada filtros de liquidez y no
arbitraje: `bid`/`ask` válidos ($2472$), `mid` $gt.eq 0","05$ ($2395$), spread relativo
$lt.eq 0","5$ ($2389$), volumen $gt.eq 1$ ($2286$), interés abierto $gt.eq 10$ ($1996$),
moneyness $0","8 lt.eq K\/S_0 lt.eq 1","2$ ($1229$) y cotas de no arbitraje ($1217$). Las
$1217$ observaciones finales tienen volatilidad implícita y vega Black–Scholes finitas. La
@tab-conteos reporta el número de cotizaciones por vencimiento tras el filtrado.

#figure(
  caption: [Cotizaciones por vencimiento y tipo tras el filtrado ($1217$ en total).],
  table(
    columns: 9,
    align: (left,) + (center,) * 8,
    table.header[Vencimiento][30 d][58 d][86 d][114 d][177 d][268 d][358 d][Total],
    [Calls], [107], [143], [140], [52], [58], [58], [58], [*616*],
    [Puts],  [119], [144], [158], [42], [45], [46], [47], [*601*],
    [*Total*], [226], [287], [298], [94], [103], [104], [105], [*1217*],
  ),
) <tab-conteos>

La @fig-explora resume el conjunto: los precios `mid` decaen con el strike, el spread
relativo se mantiene controlado por el filtro salvo en las alas, y la volatilidad implícita
de mercado muestra el *skew* característico de los índices de renta variable (más cara la
protección a la baja) y se aplana al aumentar el plazo.

#figure(
  image("/output/spy_exploratorio.png", width: 100%),
  caption: [Exploratorio del snapshot de SPY (calls): precio `mid`, spread relativo e
    IV de mercado frente a la moneyness $K\/S_0$, por vencimiento.],
) <fig-explora>

// ============================ 3. FÓRMULA ANALÍTICA =========================

= Fórmula analítica por mezcla (Parte A) <sec-analitica>

Condicionando en la varianza integrada $A_(0,T) = integral_0^T sigma_(epsilon(s))^2 dif s$,
el log-precio es gaussiano y el precio de la call es exactamente Black–Scholes con varianza
total $a$ y tasa integrada $R(a)$. El precio condicionado al régimen inicial $i$ es la
mezcla del átomo de "ningún cambio de régimen" y la integral contra la densidad continua:
$ C_i (0,s) = e^(-lambda_i T) "BS"(s,K,T,r(a_i^*); a_i^*)
  + integral_(a_-)^(a_+) "BS"(s,K,T,r(a); a) thin g_i^A (a,T) thin dif a, $
con soporte $a_- = sigma_0^2 T$, $a_+ = sigma_1^2 T$, $a_0^* = a_-$, $a_1^* = a_+$ y
$R(a) = r_0 T + (r_1 - r_0)(a - a_-)\/Delta_sigma$, $Delta_sigma = sigma_1^2 - sigma_0^2$.
Con $r_0 = r_1 = r$ se recupera $R(a) = r T$.

*Implementación.* Se programa `price_analytic_markov` integrando el término continuo con
cuadratura adaptativa (`scipy.integrate.quad`). La densidad $g_i^A$ tiene una singularidad
integrable $tilde.op a^(minus.plus 1\/2)$ en los extremos (vía $I_1(eta(a))\/sqrt(dot.c)$);
se estabiliza con la sustitución $a = c - h cos t$, que distribuye los nodos hacia los bordes,
y se usa `scipy.special.ive` (Bessel escalada) para evitar overflow. El caso singular
$sigma_0 arrow.r sigma_1$ ($Delta_sigma arrow.r 0$) se trata con una rama explícita que
devuelve Black–Scholes plano. Las puts se obtienen por paridad por régimen.

*Pruebas internas.* Se verifican cuatro pruebas (@tab-pruebasA). La *masa
total* $e^(-lambda_i T) + integral_(a_-)^(a_+) g_i^A dif a = 1$ se cumple con error máximo
$2","2 times 10^(-16)$ sobre tres juegos de parámetros y ambos regímenes — muy por debajo
del objetivo $10^(-6)$. En el *caso singular*, al reducir $sigma_1 - sigma_0$ el precio
converge monótonamente a la BS plana ($|C_0 - "BS"| = 1","4 times 10^(-8)$ para
$sigma_1 - sigma_0 = 10^(-9)$) y la rama explícita $sigma_0 = sigma_1$ coincide
exactamente; además el código rechaza con `ValueError` el caso degenerado con $r_0 eq.not r_1$,
donde la cota deja de valer. La *cota* $"BS"(dot.c; a_-) lt.eq C_i lt.eq "BS"(dot.c; a_+)$
se cumple en toda una batería de seis casos (calls y puts). La *sanidad financiera*
(positividad, no arbitraje, monotonía en $K$, ausencia de `NaN`) se satisface, y la paridad
call–put por régimen se cumple con residuo $5","3 times 10^(-15)$.

#figure(
  caption: [Pruebas internas de la Ruta A (resumen). Todas dentro de tolerancia.],
  table(
    columns: (auto, 1fr, auto),
    align: (left, left, center),
    table.header[Prueba][Resultado][Veredicto],
    [Masa total ($lt.eq 10^(-6)$)], [error máx. $= 2","2 times 10^(-16)$], [OK],
    [Caso singular $sigma_0 arrow.r sigma_1$], [$arrow.r$ BS plano; rama explícita exacta], [OK],
    [Cota $"BS"(a_-) lt.eq C_i lt.eq "BS"(a_+)$], [se cumple (6 casos, call+put)], [OK],
    [Sanidad (positividad, arbitraje, monotonía)], [sin `NaN`; paridad $C\-P = 5","3 times 10^(-15)$], [OK],
  ),
) <tab-pruebasA>

// ============================ 4. VALIDACIÓN ===============================

= Validación cruzada de las tres rutas (Parte B) <sec-validacion>

Para confirmar que las tres rutas dan el mismo precio se comparan calls (la EDP, escrita para
puts, se pasa a call por paridad). En un caso de prueba ($S_0 = 100$, $T = 0","5$,
$r = 0","03$, $sigma_0 = 0","15$, $sigma_1 = 0","40$, $lambda_0 = 2$, $lambda_1 = 5$) se
valoran $K in {90, 100, 110}$ y ambos regímenes con COS ($N = 1024$, $L = 12$), FFT de
control ($N = 2^16$, $alpha = 1","5$, $eta = 0","05$) y la EDP Crank–Nicolson
($M = N_t = 800$, $theta = 1\/2$). La @tab-validacion muestra coincidencia total.

#figure(
  caption: [Validación A/B/C, caso base. Precios call y diferencias absolutas máximas.
    Tolerancia objetivo $10^(-3)$.],
  table(
    columns: 7,
    align: (center, center, right, right, right, right, right),
    table.header[Rég.][$K$][Ruta A][B (COS)][C (EDP)][$|A\-B|$][$|A\-C|$],
    [0], [90],  [13,198930], [13,198930], [13,198416], [$3","0 times 10^(-14)$], [$5","2 times 10^(-4)$],
    [0], [100], [6,776006],  [6,776006],  [6,775109],  [$4","7 times 10^(-14)$], [$9","0 times 10^(-4)$],
    [0], [110], [3,051285],  [3,051285],  [3,051190],  [$1","8 times 10^(-13)$], [$9","5 times 10^(-5)$],
    [1], [90],  [14,725176], [14,725176], [14,724686], [$2","0 times 10^(-12)$], [$4","9 times 10^(-4)$],
    [1], [100], [8,865638],  [8,865638],  [8,865001],  [$1","0 times 10^(-13)$], [$6","4 times 10^(-4)$],
    [1], [110], [5,002082],  [5,002082],  [5,001940],  [$1","5 times 10^(-13)$], [$1","4 times 10^(-4)$],
  ),
) <tab-validacion>

Los máximos son $max|A\-B| = 2","0 times 10^(-12)$ y
$max|A\-C| = max|B\-C| = 9","0 times 10^(-4)$: todas las diferencias quedan
$lt.eq 10^(-3)$. La validación se repitió en un segundo caso ($T = 1","0$, $r = 0","05$,
$sigma_0 = 0","20$, $sigma_1 = 0","55$, $lambda_0 = 3$, $lambda_1 = 1","5$), con
$max|A\-C| = 3","0 times 10^(-4)$, para no validar sobre un único punto.

*Diagnóstico de error.* La concordancia A–B a nivel de $10^(-12)$ confirma que la fórmula
analítica y COS comparten la misma función característica (verificada además contra la
exponencial matricial, error $3","9 times 10^(-16)$). La fuente *dominante* de discrepancia
es la *discretización de la EDP*: un estudio de convergencia ($M = N_t in {50, ..., 800}$)
muestra que el error frente a la Ruta A cae de $2","3 times 10^(-1)$ a
$9","0 times 10^(-4)$ con razón $approx 4$ al duplicar la malla, es decir orden $2$ en
espacio/tiempo, consistente con Crank–Nicolson. COS, en cambio, es estable: al refinar $N$
el precio no cambia más de $1","2 times 10^(-7)$. La cuadratura de A y el truncamiento
espectral de B/COS aportan errores varios órdenes por debajo.

*Elección del motor.* Los tiempos por evaluación (tres strikes) son COS $0","54$ ms, Ruta A
$20","1$ ms y EDP $109","9$ ms: COS es $approx 37times$ más rápido que A y $approx 202times$
más rápido que la EDP. Por velocidad y estabilidad, *COS es el motor dentro del bucle de
calibración*, reservando A y la EDP para verificaciones puntuales del ajuste final.

// ============================ 5. CALIBRACIÓN ==============================

= Calibración a datos reales (Parte C) <sec-calibracion>

*Precio del modelo y objetivo.* Como el régimen inicial $epsilon(0)$ no se observa, el
precio de mercado se modela con la mezcla estacionaria
$C^("mod") = pi_0 C_0 + pi_1 C_1$. El objetivo es el *RMSE en volatilidad implícita*, más
estable que en precios porque homogeneiza escalas a través de strikes y vencimientos. Se
comparan dos esquemas de *ponderación*: uniforme y por *vega* (privilegia las cotizaciones
con mayor contenido informativo). La cadena se agrupa por vencimiento para reutilizar
evaluaciones COS y la IV del modelo se invierte con un Newton vectorizado (error
$lt.eq 2","4 times 10^(-9)$ frente a Brent).

*Simetría y restricciones.* La simetría de etiqueta $(sigma_0, lambda_0) <-> (sigma_1, lambda_1)$
se rompe con una *reparametrización logística acotada* $theta(u)$, $u in RR^4$, que garantiza
por construcción $0 < sigma_0 < sigma_1$ y $lambda_i > 0$ sin penalizaciones discontinuas
(round-trip $theta arrow.r u arrow.r theta$ con error $9 times 10^(-16)$). Los techos
$sigma_0 < 0","60$, $sigma_1 < 0","90$ y $0","05 < lambda_i < 20$ son económicos:
$sigma_1 = 90%$ es un nivel de estrés histórico del SPY.

*Tres optimizadores.* (i) *Búsqueda exhaustiva en malla* $5 times 5 times 4 times 4 = 400$
nodos sobre una caja; (ii) *Nelder–Mead* (sin gradiente); y (iii) *BFGS* (gradiente por
diferencias finitas). Los métodos locales parten del mejor nodo de la malla. La @tab-calib
reporta las seis corridas (tres técnicas $times$ dos ponderaciones).

#figure(
  caption: [Calibración: tres técnicas $times$ dos ponderaciones. RMSE en IV.
    La solución final se resalta.],
  table(
    columns: 8,
    align: (left, left, right, right, right, right, right, left),
    table.header[Método][Pesos][$hat(sigma)_0$][$hat(sigma)_1$][$hat(lambda)_0$][$hat(lambda)_1$][RMSE][Estado],
    [Malla], [unif.], [0,1125], [0,7250], [0,500], [8,000], [0,05127], [malla],
    [Nelder–Mead], [unif.], [0,1054], [0,9000], [0,364], [6,701], [0,05007], [conv.],
    [BFGS], [unif.], [0,1054], [0,9000], [0,363], [6,687], [0,05007], [conv.],
    [Malla], [vega], [0,0500], [0,9000], [0,500], [5,500], [0,04262], [malla],
    [Nelder–Mead], [vega], [0,0852], [0,9000], [0,315], [3,931], [0,04111], [conv.],
    table.cell(fill: rgb(232, 242, 232))[*BFGS*],
    table.cell(fill: rgb(232, 242, 232))[*vega*],
    table.cell(fill: rgb(232, 242, 232))[*0,0852*],
    table.cell(fill: rgb(232, 242, 232))[*0,9000*],
    table.cell(fill: rgb(232, 242, 232))[*0,315*],
    table.cell(fill: rgb(232, 242, 232))[*3,931*],
    table.cell(fill: rgb(232, 242, 232))[*0,04111*],
    table.cell(fill: rgb(232, 242, 232))[*conv.*],
  ),
) <tab-calib>

*Sensibilidad al punto inicial.* Para cada técnica y ponderación se probaron arranques
adicionales (malla y un punto "razonable"). El RMSE final coincide entre arranques con
dispersión $lt.eq 10^(-7)$ y $max|theta - macron(theta)| lt.eq 8 times 10^(-3)$ en las
intensidades: dentro de cada cuenca el óptimo es robusto al inicio.

*Solución final.* La ponderación primaria (*vega*) se fija _ex ante_ — no es válido elegir
entre objetivos distintos comparando sus RMSE. Entre los candidatos factibles, BFGS y
Nelder–Mead coinciden; se reporta
$ hat(theta) = (hat(sigma)_0, hat(sigma)_1, hat(lambda)_0, hat(lambda)_1)
  = (0","0852, thin 0","9000, thin 0","3151, thin 3","9308),
  wide "RMSE"_("IV") = 0","0411, $
con mezcla estacionaria $pi_0 = 0","926$, $pi_1 = 0","074$. *Verificación con la Ruta A:*
recalculando cuatro precios del ajuste final con la fórmula analítica frente a COS, la
diferencia absoluta máxima es $2","6 times 10^(-3)$ y la relativa $1","8 times 10^(-4)$,
confirmando la consistencia del motor de calibración.

== Diagnóstico e identificabilidad

Para distinguir tolerancia del optimizador de cuencas distintas se evalúa el RMSE sobre la
recta $theta(alpha) = alpha hat(theta)_1 + (1-alpha) hat(theta)_2$, $alpha in (-0","5, 1","5)$
(@fig-segmentos). El corte *malla vs. BFGS* es una U suave con un único mínimo en el extremo
$alpha = 0$ (BFGS), y *Nelder–Mead vs. BFGS* es plano entre ambos (coinciden): no hay
mínimos separados, de modo que las soluciones viven en una *cuenca común* y difieren sólo por
tolerancia. La caída abrupta a la izquierda en el panel derecho marca la frontera de
factibilidad ($sigma_0 < sigma_1$ violado), correctamente recortada.

#figure(
  image("/output/f7_rmse_segmentos.png", width: 100%),
  caption: [RMSE(IV) sobre cortes afines $theta(alpha)$ entre pares de soluciones. U suave y
    tramo plano $arrow.r$ cuenca común; el escalón marca la región infactible recortada.],
) <fig-segmentos>

Los *perfiles 1D* alrededor del óptimo (@fig-perfiles) precisan qué direcciones están bien
determinadas. $sigma_0$, $lambda_0$ y $lambda_1$ exhiben mínimos interiores claros (bien
identificados localmente), mientras que el perfil de $sigma_1$ es *monótonamente
decreciente* hasta la cota $0","90$: el objetivo es casi plano en $sigma_1$ por arriba y el
óptimo se apoya en el techo. En consecuencia, no se reporta un Hessiano centrado (la cota
está activa) y *$sigma_1$ se interpreta como dirección no identificada por arriba*: los datos
fijan la _existencia_ de un segundo régimen más volátil, no su nivel exacto.

#figure(
  image("/output/f7_perfiles_1d.png", width: 92%),
  caption: [Perfiles 1D del RMSE alrededor del óptimo. $sigma_0$, $lambda_0$, $lambda_1$ con
    mínimo interior; $sigma_1$ monótono hasta la cota (dirección débilmente identificada).],
) <fig-perfiles>

// ============================ 6. BS Y ECONOMÍA ============================

= Comparación con Black–Scholes y análisis económico (Parte D)

*Sonrisa y residuos.* La @fig-sonrisa superpone la IV de mercado y la del modelo por
vencimiento. El modelo de mezcla reproduce el *nivel* y la *curvatura* (forma de U) de la
sonrisa, pero al combinar dos volatilidades con drift puro genera una sonrisa casi simétrica
y no captura del todo el *skew asimétrico* de la renta variable. Los residuos
(@fig-residuos) muestran un patrón en S frente a la moneyness que se atenúa con el plazo: el
RMSE por vencimiento baja de $0","061$ (30 d) a $0","038$ (358 d) y el sesgo medio pasa de
$+0","024$ a $-0","007$, coherente con que a horizontes largos domina la mezcla estacionaria.

#figure(
  image("/output/f8_sonrisa_iv_mercado_vs_modelo.png", width: 100%),
  caption: [Sonrisa de IV: mercado (puntos) vs. modelo de regímenes (línea), por vencimiento.],
) <fig-sonrisa>

#figure(
  image("/output/f8_residuos_iv.png", width: 100%),
  caption: [Residuos de IV (modelo $-$ mercado) por moneyness (color $=T$) y distribución por
    vencimiento. El patrón en S se atenúa al crecer $T$.],
) <fig-residuos>

*Régimen vs. Black–Scholes plano.* Calibrado un único $sigma$ de BS sobre la misma cadena y
criterio, con ponderación vega se obtiene $sigma^* = 0","196$ y $"RMSE" = 0","0565$, frente a
$0","0411$ del modelo de regímenes: una *mejora del $27","2%$* en RMSE de IV. Los dos
parámetros efectivos extra (dado que $sigma_1$ y una de las $lambda$ están débilmente
fijados) se justifican porque BS plano produce una IV constante incapaz de reproducir
cualquier curvatura, mientras que la mezcla sí la genera.

*Estructura a plazo.* Recalibrando cada vencimiento por separado (@fig-plazo), $sigma_0$ es
estable (CV $approx 12%$, suave descenso de $0","115$ a $0","079$) pero $sigma_1$ se pega a
la cota en _todos_ los plazos y $lambda_0$ al piso, mientras $lambda_1$ decae de $0","85$ a
$0","37$. La calibración conjunta usa más información y promedia estas tensiones, pero sigue
siendo un compromiso de parámetros constantes; que las cotas estén activas en todos los
plazos confirma la identificación débil más que un verdadero cambio temporal.

#figure(
  image("/output/f8_estabilidad_plazo.png", width: 100%),
  caption: [Estabilidad a plazo: calibración separada (puntos) vs. conjunta (líneas) para
    volatilidades (izq.) e intensidades (der.).],
) <fig-plazo>

*Interpretación económica.* El óptimo describe un mercado que pasa la mayor parte del tiempo
en calma: $sigma_0 = 8","5%$ frente a $sigma_1 = 90%$ de estrés, con probabilidades
estacionarias $pi_0 = 92","6%$ y $pi_1 = 7","4%$. Las duraciones esperadas son
$1\/lambda_0 = 3","17$ años en calma y $1\/lambda_1 = 0","25$ años ($approx 64$ días
hábiles) en crisis: episodios de estrés cortos e infrecuentes pero intensos, razonable para
SPY. El segundo autovalor de $Q$ es $-(lambda_0 + lambda_1) = -4","25$,
con *tiempo de mezcla* $1\/(lambda_0+lambda_1) = 0","24$ años ($approx 59$ días hábiles); más
allá de $approx 3 t_("mix") = 0","71$ años el peso del régimen inicial decae a $tilde.op 5%$
y la valoración queda gobernada por la mezcla estacionaria.

== Respuestas a las preguntas de la Parte D

#set enum(numbering: "1.", spacing: 0.9em)

+ *Identificabilidad.* $sigma_0$ es la dirección mejor determinada porque fija el nivel
  principal de la sonrisa (perfil con mínimo agudo). Las intensidades identifican mejor el
  cociente estacionario $pi_0 = lambda_1\/(lambda_0+lambda_1)$ que $lambda_0, lambda_1$ por
  separado. $sigma_1$ está mal determinado por arriba: su perfil es monótono hasta la cota
  (@fig-perfiles) y el óptimo se apoya en ella, síntoma del mal condicionamiento del problema
  inverso (superficie casi plana).

+ *Por qué $r_0 = r_1$.* Las opciones ven el descuento sólo a través del bono
  $EE_i [e^(-integral_0^T r)]$, que un único subyacente fija como una sola curva. Con
  $r_0 = r_1$ el descuento se factoriza como $e^(-r T)$ y las tres rutas aplican; con
  $r_0 eq.not r_1$ el descuento depende del camino (de los tiempos de ocupación) y no se
  factoriza, por lo que COS deja de valer. Aun cuando la fórmula cerrada y la EDP admiten
  dos tasas, éstas no son identificables a partir de un solo subyacente: harían falta
  instrumentos sensibles a la tasa por régimen (renta fija o derivados de tasas).

+ *Régimen vs. Black–Scholes plano.* El modelo de regímenes reduce el RMSE de IV un $27%$
  frente a BS plano ($0","0411$ vs. $0","0565$). La mejora es material y justifica el modelo,
  con la salvedad de que parte de la ganancia proviene de $sigma_0$ y del cociente
  estacionario, no de un $sigma_1$ identificado con precisión.

+ *Estructura a plazo.* $sigma_0$ permanece estable a través de los plazos; $sigma_1$ y una
  intensidad tocan sus cotas en todos los vencimientos (@fig-plazo). La calibración conjunta
  es un compromiso razonable, pero los parámetros constantes no absorben por completo la
  variación del skew con el plazo (residuos decrecientes en $T$).

+ *Interpretación económica.* $sigma_0 = 8","5%$ (calma) y $sigma_1 = 90%$ (estrés);
  $1\/lambda_i$ son las duraciones medias ($3","17$ y $0","25$ años) y $pi_i$ las frecuencias
  de largo plazo ($92","6%$ / $7","4%$). $sigma_1$ se acerca a niveles de crisis observados,
  pero al ser una cota activa debe leerse como cota, no como nivel estimado con precisión.

+ *Horizonte de mezcla.* El efecto del régimen inicial decae como
  $e^(-(lambda_0+lambda_1)T)$, con $t_("mix") = 1\/(lambda_0+lambda_1) = 0","24$ años. Cerca de
  $3 t_("mix") approx 0","71$ años queda $tilde.op 5%$ del efecto inicial; a partir de ese
  horizonte el modelo «olvida» el régimen de arranque y domina la mezcla estacionaria.

// ============================ 7. CONCLUSIONES =============================

= Conclusiones

La fórmula analítica por mezcla pasa las cuatro pruebas internas (masa con error $10^(-16)$,
caso singular, cota y sanidad), coincide con COS a nivel de $10^(-12)$ y con la EDP dentro de
$10^(-3)$, con el error dominado por la discretización de Crank–Nicolson (orden $2$). La
calibración a $1217$ opciones de SPY con los tres optimizadores converge a una misma cuenca y
reduce el RMSE de IV un $27%$ frente a Black–Scholes plano. La lectura económica es coherente:
calma persistente interrumpida por crisis cortas e intensas.

La limitación principal es que el objetivo es casi plano en $sigma_1$, que se apoya en la cota
de $90%$. Los datos fijan la existencia de un segundo régimen volátil, no su nivel exacto, y
$lambda_1$ es la dirección menos estable. El modelo reproduce el nivel y la curvatura de la
sonrisa, pero no su asimetría: es lo esperable de un modelo de volatilidad con drift puro
frente al skew de la renta variable.
