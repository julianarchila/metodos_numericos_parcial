# Calibración del modelo Markov-modulado a opciones de SPY

Estimación de los parámetros `θ = (σ₀, σ₁, λ₀, λ₁)` de un modelo de volatilidad
Markov-modulado de dos regímenes a partir de la cadena de opciones del ETF **SPY**
(el *problema inverso*). Todo el desarrollo —datos, fórmula analítica, validación
cruzada, calibración, diagnóstico e interpretación— vive en un único notebook
reproducible.

## Estructura del repositorio

```
parcial_calibracion_markov.ipynb   Notebook principal (todo el desarrollo)
data/                              Snapshot congelado de opciones de SPY
  spy_options_raw.csv                cadena cruda descargada
  spy_options_filtered.csv           conjunto filtrado que alimenta la calibración
  spy_snapshot_meta.json             metadatos: fecha, spot, r, q, vencimientos
requirements.txt                  Dependencias para pip
pyproject.toml                    Dependencias para uv
```

## Requisitos

Python 3.12.

## Instalación

**Opción A — pip + entorno virtual:**

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

**Opción B — uv:**

```bash
uv sync                          # crea .venv e instala dependencias
```

## Ejecución

Abrir el notebook y ejecutarlo **de arriba abajo** desde un kernel reiniciado:

```bash
jupyter lab                      # con uv: uv run jupyter lab
```

O ejecutarlo de forma no interactiva:

```bash
jupyter nbconvert --to notebook --execute --inplace parcial_calibracion_markov.ipynb
# con uv: anteponer "uv run"
```

La calibración domina el tiempo (varios minutos): malla 5×5×4×4, optimizadores
locales para dos ponderaciones y calibraciones por vencimiento.

## Datos y reproducibilidad

- El snapshot está **congelado** en `data/`. La calibración corre siempre contra el
  CSV filtrado, nunca contra una descarga en vivo.
- Snapshot incluido: 24 de junio de 2026, `S₀ = 733.24`, `r = 3.69%` (T-bill 13
  semanas `^IRX`), `q = 1.27%`, 7 vencimientos (~30 a ~360 días), 1217 cotizaciones
  filtradas.
- Semilla global fija `SEED = 42`.
- Para **regenerar el snapshot** (cambia los resultados según la fecha): poner
  `FORCE_DOWNLOAD = True` en la celda de configuración de datos y ejecutar (requiere
  internet; usa `yfinance`).
