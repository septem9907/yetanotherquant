# yetanotherquant

A Python port of quantitative finance examples from a six-chapter book on probability, Kelly criterion, portfolio construction, and options pricing. The original code is in R (see `resources/R_CODE/`); this package re-implements every example in Python using **polars**, **pandas**, and **numpy**.

## Requirements

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) package manager

## Setup

```bash
uv sync
```

That installs all dependencies into an isolated virtual environment.

## Project Structure

```
src/yetanotherquant/
├── data/           # Market data download and return computation
├── chapter1/       # Binomial probability (exact and Monte Carlo)
├── chapter2/       # Central Limit Theorem demonstrations
├── chapter3/       # Return distributions, wealth simulation, Kelly criterion
├── chapter4/       # Market randomness tests and moving-average strategies
├── chapter5/       # Portfolio optimisation (Nekrasov), copula simulation
└── chapter6/       # Black-Scholes option pricing and Greeks

scripts/            # Runnable entry points, one per topic
benchmarks/         # Numerical verification against analytical reference values
resources/R_CODE/   # Original R scripts (35 files, with added comments)
docs/               # Documentation
```

## Running Scripts

Each script downloads live market data (DAX, DOW components, or uses synthetic data) and produces plots.

```bash
uv run python scripts/ch1_coin_flip.py
uv run python scripts/ch2_clt.py
uv run python scripts/ch3_returns.py
uv run python scripts/ch3_kelly.py
uv run python scripts/ch4_randomness.py
uv run python scripts/ch4_ma_strategy.py
uv run python scripts/ch5_portfolio.py
uv run python scripts/ch5_copula.py
uv run python scripts/ch6_options.py
```

Pass `--save` to write PNG files to disk instead of opening an interactive window:

```bash
uv run python scripts/ch3_kelly.py --save
```

## Running Benchmarks

Benchmarks verify the Python implementation against independently derived analytical results (not against R output directly).

```bash
uv run python benchmarks/compare_ch1.py
uv run python benchmarks/compare_ch3_kelly.py
uv run python benchmarks/compare_ch4_ma.py
uv run python benchmarks/compare_ch5_portfolio.py
uv run python benchmarks/compare_ch6_options.py
```

All benchmarks exit with code 0 on success and 1 on failure, so they can be used in CI.

## What Each Chapter Covers

| Chapter | Topic | Key algorithms |
|---------|-------|----------------|
| 1 | Probability | Binomial tail probability, Monte Carlo estimation |
| 2 | Central Limit Theorem | Coin-toss simulation, histogram vs. normal fit |
| 3 | Return Distributions & Kelly | Normal/binary wealth models, MDD, analytical and simulated Kelly fraction |
| 4 | Market Randomness | Wald-Wolfowitz runs test, ACF, moving-average crossover strategies, seasonality |
| 5 | Portfolio Optimisation | Nekrasov Kelly fractions, Gaussian and Clayton copula simulation, TP/SL paths |
| 6 | Options | Black-Scholes pricing, Delta/Gamma/Vega, vol-price inverse relationship |

## Documentation

- [`docs/R_CODE_logic.md`](docs/R_CODE_logic.md) — description of each original R script
- [`docs/Python_CODE_logic.md`](docs/Python_CODE_logic.md) — description of each Python module, function signatures, and differences from the R code

## Dependencies

| Library | Purpose |
|---------|---------|
| `yfinance` | Market data download (replaces R's `quantmod`) |
| `polars` | Fast tabular data manipulation |
| `pandas` | Interface layer with yfinance; rolling statistics |
| `numpy` | All Monte Carlo simulation (vectorised) |
| `scipy` | Binomial/normal distributions, correlation tests |
| `statsmodels` | Runs test, ACF plots |
| `matplotlib` | All visualisations |
