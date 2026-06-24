# Guía del proyecto para agentes

## Objetivo

Completar el parcial individual de Métodos Numéricos en Finanzas sobre la
calibración de un modelo de volatilidad Markov-modulado con dos regímenes a
precios reales de opciones de **SPY**.

Los parámetros por estimar son:

\[
\theta=(\sigma_0,\sigma_1,\lambda_0,\lambda_1),
\]

con las restricciones \(0<\sigma_0<\sigma_1\) y
\(\lambda_0,\lambda_1>0\). Durante la calibración principal se usa una tasa
común \(r_0=r_1=r\).

## Estructura

El desarrollo completo debe mantenerse en un solo archivo:

- `parcial_calibracion_markov.ipynb`

Archivos y carpetas auxiliares:

- `data/`: snapshots y datos filtrados de opciones de SPY;
- `output/`: tablas y figuras regenerables; está ignorado por Git;
- `plans/plan-parcial-calibracion-markov.md`: plan detallado;
- `README.md`: preparación y ejecución del entorno.

No crear módulos Python, notebooks adicionales ni una arquitectura de paquete
salvo que el usuario lo solicite explícitamente.

## Referencias obligatorias

Leer antes de implementar:

1. `Julian Alejandro Archila Caro - Parcial Calibracion Markov Modulado.pdf`
   - Es el enunciado oficial y prevalece ante cualquier otra referencia.
2. `plans/plan-parcial-calibracion-markov.md`
   - Contiene las fases, criterios de aceptación y correspondencia con la
     rúbrica.
3. `reference/taller2/Taller_2_Metodos.ipynb`
   - Fuente de la función característica, Carr-Madan FFT, COS,
     Black-Scholes y volatilidad implícita.
4. `reference/taller3/Taller3.ipynb`
   - Fuente de la EDP acoplada y el esquema Crank-Nicolson.

Los notebooks anteriores son material de referencia: no modificarlos.

## Alcance funcional

El notebook final debe cubrir, en este orden:

1. configuración reproducible;
2. descarga, congelación y filtrado de la cadena de opciones de SPY;
3. fórmula analítica por mezcla sobre la varianza integrada;
4. rutas COS/FFT y EDP reutilizadas de los talleres;
5. validación cruzada de las tres rutas;
6. calibración con brute force, Nelder-Mead y BFGS;
7. diagnóstico de identificabilidad y óptimos locales;
8. comparación con Black-Scholes e interpretación económica;
9. generación de tablas y figuras para el informe.

## Convenciones de trabajo

- Usar Python 3.12 mediante `uv`.
- Preparar el entorno con `uv sync`.
- Ejecutar el notebook desde la raíz del repositorio.
- Fijar todas las semillas aleatorias.
- La calibración debe leer un CSV congelado, nunca depender de una descarga en
  vivo.
- Documentar fecha, hora, zona horaria, spot, tasas, dividendos y filtros del
  snapshot.
- Mantener celdas pequeñas, ordenadas y ejecutables secuencialmente.
- Explicar decisiones numéricas y financieras en celdas Markdown.
- No ocultar fallos numéricos: registrar advertencias, tolerancias y
  limitaciones.
- Evitar duplicar funciones con nombres distintos.
- No incluir secretos, tokens ni credenciales en el notebook o los datos.

## Verificación

Después de cambios relevantes:

```bash
uv run jupyter nbconvert \
  --to notebook \
  --execute parcial_calibracion_markov.ipynb \
  --output executed.ipynb \
  --output-dir tmp/notebook-smoke \
  --ExecutePreprocessor.timeout=300
```

Además, verificar:

- que el notebook parte de un kernel reiniciado;
- que no depende de variables creadas fuera de orden;
- que los archivos generados van a `data/` u `output/`;
- que `git status` no incluye temporales ni el entorno virtual.

## Criterio para la primera parte

La primera parte del notebook corresponde a los datos de mercado de SPY. Debe
producir un snapshot crudo y un CSV filtrado reproducible para al menos 5 o 6
vencimientos entre aproximadamente un mes y un año.

El conjunto filtrado debe incluir, como mínimo:

- fecha del snapshot y vencimiento;
- tipo de opción;
- \(S_0\), \(K\), \(T\);
- bid, ask, mid y spread;
- volumen e interés abierto;
- tasa \(r\), dividendo \(q\) y forward;
- volatilidad implícita, vega y moneyness.

Los filtros deben cubrir liquidez, spreads, cotas de no arbitraje y el intervalo
sugerido \(0.8\le K/S_0\le1.2\). También debe generarse una tabla de conteos por
vencimiento.
