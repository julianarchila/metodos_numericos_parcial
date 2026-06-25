# Calibración del modelo Markov-modulado a opciones de SPY

Proyecto reproducible para el parcial de Métodos Numéricos en Finanzas
(calibración de un modelo de volatilidad Markov-modulado de dos regímenes,
`θ = (σ₀, σ₁, λ₀, λ₁)`). El subyacente asignado es **SPY**. Todo el desarrollo
—datos, fórmula analítica, validación cruzada, calibración, diagnóstico e
interpretación— vive en un único notebook: `parcial_calibracion_markov.ipynb`.

## Preparación del entorno

```bash
uv sync                      # crea .venv con Python 3.12 e instala dependencias
uv run jupyter lab           # abrir parcial_calibracion_markov.ipynb
```

Para una ejecución completa, no interactiva, desde un kernel reiniciado:

```bash
mkdir -p tmp/notebook-smoke
uv run jupyter nbconvert --to notebook --execute parcial_calibracion_markov.ipynb \
  --output executed.ipynb --output-dir tmp/notebook-smoke \
  --ExecutePreprocessor.timeout=300
```

## Procedencia de los datos

- **Fuente:** `yfinance` (cadena de opciones y spot de SPY; T-bill 13 semanas
  `^IRX` para `r`; dividendos de SPY para `q`).
- **Snapshot congelado:** la descarga se ejecuta **una sola vez** y se guarda en
  `data/`. La calibración corre **siempre contra el CSV congelado**, nunca contra
  una descarga en vivo.
  - `data/spy_options_raw.csv` — cadena cruda (calls y puts, 7 vencimientos).
  - `data/spy_options_filtered.csv` — conjunto calibrable filtrado.
  - `data/spy_snapshot_meta.json` — fecha/hora UTC, spot, `r`, `q`, fuentes y
    vencimientos del snapshot.
- **Snapshot incluido:** 2026-06-24, `S₀ = 733.24`, `r = 3.69%` (`^IRX`,
  usado como proxy plana), `q = 1.27%` (dividendos TTM / spot), 7 vencimientos
  (~30 a ~360 días), 1217 cotizaciones filtradas.
- **Regenerar el snapshot (opcional):** poner `FORCE_DOWNLOAD = True` en la celda
  `datos-config` y ejecutar. Los resultados cambiarán según la fecha de descarga;
  para reproducir el informe, usar el CSV congelado entregado.

### Convenciones de mercado

- Conteo de días **ACT/365**: `T = días naturales hasta el vencimiento / 365`.
- `r` plana (T-bill 13 semanas) y `q` plana (dividendos TTM), coherentes con la
  decisión del parcial de calibrar con `r₀ = r₁ = r`.
- Forward `F = S₀·e^{(r−q)T}`; precio de mercado `mid = (bid + ask)/2`.
- Filtros deterministas: `bid/ask` válidos, `mid ≥ 0.05`, spread relativo ≤ 0.5,
  `volume ≥ 1`, `open interest ≥ 10`, moneyness `0.8 ≤ K/S₀ ≤ 1.2` y cotas
  de no arbitraje.

## Orden de ejecución

El notebook se ejecuta **de arriba abajo** desde un kernel reiniciado. Secciones:

0. **Configuración reproducible** — semillas, rutas, versiones.
1. **Datos de mercado de SPY** — snapshot, filtros, IV/vega, tabla de conteos.
2. **Ruta A** — fórmula analítica por mezcla y pruebas internas (masa, cota, caso singular).
3. **Rutas B y C** — COS/FFT y EDP Crank-Nicolson (código reutilizado de los Talleres).
4. **Validación cruzada A/B/C** — tabla de diferencias en el caso base.
5. **Motor de precios y objetivo** — mezcla estacionaria, RMSE en IV, dos ponderaciones.
6. **Calibración** — brute force, Nelder-Mead y BFGS; tabla comparativa.
7. **Diagnóstico** — dos cortes afines y perfiles 1D de identificabilidad.
8. **Parte D** — sonrisa mercado vs. modelo, Black-Scholes plano, estructura a plazo,
   interpretación económica y respuestas a las seis preguntas.

## Tablas y figuras (regeneradas al ejecutar el notebook)

Todas las salidas regenerables van a `output/` (carpeta no versionada).

| Salida | Celda | Archivo |
|---|---|---|
| Exploratorio de datos | `datos-graficos` | `output/spy_exploratorio.png` |
| Tabla de calibración (3 métodos × 2 pesos) | `f6-tabla` | `output/f6_tabla_calibracion.csv` |
| RMSE vs α (cortes afines) | `f7-fig-segment` | `output/f7_rmse_segmentos.png` |
| Perfiles 1D alrededor del óptimo | `f7-fig-profiles` | `output/f7_perfiles_1d.png` |
| Sonrisa IV mercado vs. modelo | `f8-fig-sonrisa` | `output/f8_sonrisa_iv_mercado_vs_modelo.png` |
| Residuos de IV | `f8-fig-residuos` | `output/f8_residuos_iv.png` |
| BS plano vs. régimenes | `f8-bs-plano` | `output/f8_comparacion_bs_vs_regimenes.csv` |
| Calibración por vencimiento | `f8-plazo` | `output/f8_calibracion_por_vencimiento.csv` |
| Estabilidad a plazo | `f8-fig-plazo` | `output/f8_estabilidad_plazo.png` |
| Interpretación económica | `f8-economia` | `output/f8_interpretacion_economica.csv` |

## Reproducibilidad

- **Semilla global** `SEED = 42` (fijada en la celda de configuración y re-fijada
  antes de la calibración). `numpy` y `random` quedan sembrados.
- La calibración lee el CSV congelado; no depende de ninguna descarga en vivo.
- `data/` (snapshots) se versiona; `.venv/`, `tmp/` y `output/` están en
  `.gitignore`.

## Tiempos aproximados

- `uv sync`: ~1 min (primera vez).
- Ejecución completa del notebook: varios minutos (la calibración domina; malla
  5×5×4×4, optimizadores locales para dos ponderaciones y calibraciones por
  vencimiento).

## Limitaciones conocidas

- **`σ₁` débilmente identificado por arriba.** El objetivo es casi plano en `σ₁`
  por encima de ~0.6; una calibración sin restricción se escapa a `σ₁≈1.44`
  (144% de vol, no creíble). La parametrización impone un techo económico
  `SIGMA1_CEIL = 0.90` (nivel de crisis histórico del SPY) y `σ̂₁` se apoya en/cerca
  de él. Los datos fijan la *existencia* de un segundo régimen más volátil, no su
  nivel exacto (ver diagnóstico de la Fase 7 y respuesta D1).
- **EDP (Ruta C):** error ~`5×10⁻⁴` frente a la fórmula analítica en el caso base
  (dentro de la tolerancia `≤10⁻³`), limitado por la discretización de la malla.
- **Tasa y dividendos planos.** `r` y `q` se toman constantes del snapshot; no se
  construye una curva por plazo (coherente con `r₀ = r₁ = r`).
- **Snapshot dependiente de la fecha.** Regenerar con `FORCE_DOWNLOAD = True`
  produce datos distintos; el informe corresponde al snapshot congelado entregado.

## Referencias

- Enunciado: `Julian Alejandro Archila Caro - Parcial Calibracion Markov Modulado.pdf`
- Plan: `plans/plan-parcial-calibracion-markov.md`
- Taller 2 (Fourier/COS/FFT): `reference/taller2/Taller_2_Metodos.ipynb`
- Taller 3/4 (EDP): `reference/taller3/Taller3.ipynb`
