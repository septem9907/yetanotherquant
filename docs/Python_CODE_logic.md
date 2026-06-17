# Python Code Logic

This document describes the Python port of the book's R code. The package is `yetanotherquant`, installed via `uv sync`. Each chapter's R scripts map to one or two Python modules under `src/yetanotherquant/`.

For a description of **what each algorithm does**, see [R_CODE_logic.md](R_CODE_logic.md). This document focuses on **how the Python code is structured** and where it differs from the R originals.

---

## Library Choices

| Task | Library | Why |
|------|---------|-----|
| Data download | `yfinance` | Drop-in replacement for R's `quantmod::getSymbols` |
| Data manipulation | `polars` | Fast, expressive; used for groupby/filter/join operations |
| Time series | `pandas` | yfinance returns pandas; used where DatetimeIndex slicing is natural |
| Numerical arrays | `numpy` | All Monte Carlo loops operate on numpy arrays |
| Statistics | `scipy` | Binomial CDF, normal distribution, Spearman/Kendall correlation |
| ACF / runs test | `statsmodels` | `runstest_1samp`, `plot_acf` |
| Plotting | `matplotlib` | All visualisations; functions return `Figure` objects for flexibility |

**Polars vs pandas split:** `fetch_prices()` downloads via yfinance (pandas), then immediately converts to a Polars DataFrame. All downstream analysis uses Polars for tabular operations and numpy arrays for numerical computations. Pandas is only re-used in `strategies.py` for `Series.rolling().mean()`.

---

## Package Layout

```
src/yetanotherquant/
├── data/
│   └── loader.py          # Data download and return computation
├── chapter1/
│   └── probability.py     # Coin-flip probability
├── chapter2/
│   └── clt.py             # Central Limit Theorem demos
├── chapter3/
│   ├── returns.py         # Return distributions and wealth simulation
│   └── kelly.py           # Kelly criterion (analytical + simulated)
├── chapter4/
│   ├── randomness.py      # Runs test and ACF
│   └── strategies.py      # MA strategies, seasonality, trading system
├── chapter5/
│   ├── portfolio.py       # Nekrasov formula and portfolio optimisation
│   ├── simulation.py      # Portfolio MC with TP/SL
│   └── copula.py          # Gaussian and Clayton copula simulation
└── chapter6/
    └── options.py         # Black-Scholes pricing and Greeks

scripts/                   # Runnable entry points (one per chapter group)
benchmarks/                # Numerical comparisons against R expected outputs
```

All modules export pure functions. Plotting functions return `matplotlib.Figure` so the caller decides whether to display or save. No global state is used.

---

## `data/loader.py`

**R equivalent:** `quantmod::getSymbols`, `ROC()`, `periodReturn()`

### `fetch_prices(ticker, start, end) → pl.DataFrame`

Downloads OHLCV data from Yahoo Finance. Columns: `date, open, high, low, close, volume`.

- Uses `yf.download(..., auto_adjust=True)` so prices are already split/dividend adjusted.
- Handles the MultiIndex columns yfinance returns when downloading a single ticker.
- Converts the pandas result to Polars immediately.

### `daily_returns(df, price_col) → pl.Series`

`r_t = P_t / P_{t-1} - 1`. First element is `null` (no prior day). Mirrors R's `ROC(prices, type='discrete')`.

### `period_returns(df, period, price_col) → pl.DataFrame`

Aggregates to monthly or weekly returns using the **last close of each period**. Mirrors R's `periodReturn(data, period='monthly')`.

- Uses `pl.Expr.dt.truncate("1mo")` to group dates into calendar months.
- Returns a DataFrame with `period` (Date) and `return` columns.

### `to_numpy_returns(series) → np.ndarray`

Drops nulls and converts a Polars Series to a plain float numpy array. Used as a bridge between the Polars data layer and the numpy computation layer.

---

## `chapter1/probability.py`

**R equivalent:** `1_1.r`

### `exact_tail_prob(n, k, p) → float`

`P(X ≥ k)` for `X ~ Binomial(n, p)`. Uses `scipy.stats.binom.sf(k-1, n, p)` (survival function = `1 - CDF`). Matches R's `1 - pbinom(k-1, n, p)` exactly.

### `monte_carlo_tail_prob(n, k, p, n_sim, seed) → float`

Draws `n_sim` binomial samples and counts the fraction ≥ k. Accepts a `seed` for reproducibility. Uses `numpy.random.default_rng` (the modern numpy RNG API).

---

## `chapter2/clt.py`

**R equivalent:** `forFig2_1.r`, `forFig2_2.r`

### `simulate_coin_tosses(n_tosses, n_sim, p, seed) → np.ndarray`

Returns an array of head counts of shape `(n_sim,)`.

### `plot_histogram_with_normal(tosses) → Figure`

Histogram of head counts with a fitted normal density scaled to histogram bin counts. Mirrors R's `hist(...) + lines(dnorm(...))`.

### `plot_density_comparison(tosses) → Figure`

Kernel density estimate (via `scipy.stats.gaussian_kde`) overlaid with the fitted normal. Mirrors R's `plot(density(...)) + lines(density(normalRV))`.

---

## `chapter3/returns.py`

**R equivalent:** `3_1.r` – `3_5.r`, `3_7.r`

### `fit_normal(returns) → (mu, sigma)`

Returns sample mean and standard deviation.

### `plot_density_vs_normal(returns) → Figure`

KDE of empirical returns + fitted normal, mirroring R's density/lines pattern.

### `plot_qq_normal(returns) → Figure`

Uses `scipy.stats.probplot` to draw a normal QQ-plot with a reference line.

### `filter_outliers(returns, n_sigma) → np.ndarray`

Removes returns outside ±n_sigma × std. Mirrors R's `3_2b.r` 3-sigma cap.

### `compare_normal_binomial_models(monthly_returns, seed) → dict`

Builds three compounded wealth series from the same mu/sigma:
- `"empirical"`: actual historical returns compounded
- `"normal"`: Gaussian draws
- `"binomial"`: binary ±sigma draws with equal probability

Returns a dict of numpy arrays. Mirrors R's `3_4.r`.

### `simulate_wealth_paths(mu, sigma, n_sim, n_months, seed) → np.ndarray`

Shape `(n_sim, n_months)`. Uses `np.cumprod` along the time axis — vectorised, no Python loop over paths. Mirrors R's `3_2d.r`.

### `max_drawdown(wealth) → float`

`min(wealth / cummax(wealth)) - 1`. Returns a negative number. Mirrors R's `fTrading::maxDrawDown` / `tseries::maxdrawdown`.

### `simulate_terminal_wealth_and_mdd(monthly_returns, n_sim, seed) → dict`

Runs `n_sim` paths for both the normal and binomial return models and returns terminal wealth and MDD arrays for each. Mirrors R's `3_5.r`.

### `rolling_volatility(returns, windows) → dict`

Given a dict of `{label: lookback_days}`, computes `std(returns[-lookback:])` for each window. Mirrors R's `3_7.r`.

---

## `chapter3/kelly.py`

**R equivalent:** `3_3a.r` – `3_3c.r`, `3_6a.r` – `3_6b.r`, `forFig3_2.r`, `forFig3_3.r`

### `analytical_kelly_coin(p_win, win_mult, loss_mult) → float`

Closed-form Kelly fraction for a binary bet: `f* = p/loss - q/win`. For the book's example (p=0.5, win=1.7, loss=0.7): f* ≈ 0.4202.

**Note:** R's `forFig3_2.r` uses `which.max()` on a 1%-step grid, returning 42 (→ 0.42). The continuous formula gives 0.4202 — a difference of 0.02% due to grid discretisation.

### `expected_growth_rate(fractions, p_win, win_mult, loss_mult) → np.ndarray`

`g(f) = p·log(1 + win·f) + q·log(1 - loss·f)` for each fraction in the array.

### `kelly_simulation(mu, sigma, r_f, n_steps, n_sim, n_periods, seed) → np.ndarray`

**Key improvement over R:** The R code uses three nested `for` loops (fractions × simulations × periods). This implementation vectorises the inner two loops using numpy:

```python
# R (slow):
for u in 1:N_STEPS:
  for i in 1:N_SIM:
    for m in 1:N_MONTHS: ...

# Python (fast):
rets = rng.normal(mu, sigma, size=(n_sim, n_periods))   # one draw
terminal = np.prod(frac * (rets - r_f) + (1 + r_f), axis=1)
```

Returns `mean_log_wealth` array of length `n_steps`. Call `optimal_kelly_fraction(result)` to get the fraction.

### `optimal_kelly_fraction(mean_log_wealth, n_steps) → float`

Returns the fraction (0–1) at the array maximum.

### `kelly_sensitivity(monthly_returns, r_f, n_iterations, ...) → list[dict]`

Runs the Kelly search `n_iterations` times, each with fresh estimated mu/sigma from a sample of size `n`. Shows how estimation error moves the optimal fraction. Mirrors R's `3_3c.r`.

### `backtest_kelly_fractions(monthly_returns, r_f, fracs) → dict[str, np.ndarray]`

Applies `portfolio_ret = frac × (r - r_f) + (1 + r_f)` to historical returns for each fraction and compounds. Returns wealth arrays for plotting. Mirrors R's `3_3b.r`.

### `simulate_betting_strategies(n_trades, p_win, win_mult, loss_mult, kelly_frac, seed) → dict`

Simulates full / Kelly / half-Kelly strategies over a coin-toss sequence. Returns wealth arrays. Mirrors R's `forFig3_3.r`.

### `drawdown_risk_at_fraction(mu, sigma, kelly_frac, r_f, n_days, n_sim, dd_thresholds, seed) → dict`

Vectorised simulation: all `n_sim × n_days` returns drawn at once with `rng.normal(..., size=(n_sim, n_days))`. Reports P(MDD < threshold) and terminal log-wealth stats. Mirrors R's `3_6b.r`.

---

## `chapter4/randomness.py`

**R equivalent:** `4_1.r`

### `runs_test(returns) → dict`

Converts returns to binary (1 if above median, 0 otherwise) and applies the Wald-Wolfowitz runs test via `statsmodels.sandbox.stats.runs.runstest_1samp`. Returns `{statistic, p_value}`. Mirrors R's `lawstat::runs.test`.

### `runs_test_report(returns, sub_ranges) → pl.DataFrame`

Runs the test over multiple slices of the return series. Returns a Polars DataFrame with `period`, `statistic`, `p_value` — useful for comparing randomness across sub-periods.

### `plot_acf_grid(returns, sub_ranges, lags) → Figure`

Plots ACF for the full series and each sub-period in a 2×n_cols grid. Uses `statsmodels.graphics.tsaplots.plot_acf`. Mirrors R's `par(mfrow=c(2,2)); acf(...)`.

---

## `chapter4/strategies.py`

**R equivalent:** `4_2.r`, `4_2a_dj30.r`, `4_3.r`, `4_4.r`, `4_5.r`

### `simple_ma_strategy(prices, ma_days) → dict`

Buys when `price > MA`, sells when `price < MA` or at the end. Uses `pd.Series.rolling().mean()` for the moving average (same algorithm as R's `SMA()`). Returns `{ma_wealth, bh_wealth, n_trades}`. Mirrors R's `4_2.r`.

### `dual_ma_crossover(prices, short_days, long_days) → dict`

Golden cross / death cross signal. Buy when `MA_short > MA_long`, sell on reversal. Mirrors R's `4_3.r`.

### `backtest_universe(tickers, price_data, strategy_fn, **kwargs) → pl.DataFrame`

Applies a strategy function to multiple tickers, collecting results in a Polars DataFrame with `ticker`, `ma_wealth`, `bh_wealth`, `wealth_diff` columns. Gracefully skips tickers with errors.

### `monthly_seasonality(monthly_returns, return_col) → pl.DataFrame`

Groups returns by calendar month using Polars `group_by` + `agg`. Returns mean, median, and std return per month. Mirrors R's `4_4.r` grouping logic.

### `plot_seasonality_boxplot(monthly_returns) → Figure`

Box plot of returns by month. Mirrors R's `boxplot(Return~Month, data=tmp)`.

### `simulate_trading_system(n_trades, win_prob, ret_per_trade, n_sim, seed) → dict`

Vectorises the inner simulation: all outcomes drawn as `rng.binomial(1, win_prob, size=(n_sim, n_trades))`. Computes cumulative wealth with `np.cumprod`. Returns `{terminal_wealth, max_drawdown, mean_terminal_wealth, mean_mdd}`. Mirrors R's `4_5.r`.

---

## `chapter5/portfolio.py`

**R equivalent:** `5_1.r`, `5_2.r`, `5_2a.r`, `5_3.r`, `5_4.r`

### `correlation_matrix(returns_dict) → pl.DataFrame`

Wraps `np.corrcoef` and returns a labelled Polars DataFrame.

### `estimate_sigma(returns_matrix, r_f) → np.ndarray`

Computes the **non-central second moment matrix of excess returns**:

```
Sigma[i,j] = E[(r_i - r_f)(r_j - r_f)]
```

This is **not** the standard covariance matrix. It includes the outer product of mean excess returns:

```
Sigma = Cov(r) + (mu - r_f)(mu - r_f)^T
```

The distinction matters for the Kelly formula. Mirrors R's `estimateSigma()` in `5_2.r`.

### `nekrasov_optimal(mu, sigma, r_f) → np.ndarray`

Nekrasov's closed-form Kelly fractions:

```
u = (1 + r_f) × Sigma⁻¹ × (mu - r_f)
```

Uses `np.linalg.pinv` (Moore-Penrose pseudo-inverse) for numerical stability. Can return fractions > 1 (leverage) or < 0 (shorting), consistent with the mathematical optimum. Mirrors R's `ginv(Sigma) %*% (expRets - riskFreeReturn)`.

### `brute_force_two_asset(mu, cov, r_f, path_len, n_sim, seed) → dict`

Enumerates all (f1%, f2%) pairs with f1 + f2 ≤ 100% (5151 combinations), draws `n_sim × path_len` correlated returns at once, and computes mean log-terminal-wealth for each. Returns the optimal fractions and the full grid. Mirrors R's `allFracs()` in `5_2.r`.

**Python vs R speed:** R uses nested for loops; Python draws all returns in a single `rng.multivariate_normal(..., size=(n_sim, path_len))` call and uses vectorised product, making it substantially faster.

### `implied_drift(buy_price, tp, sl, tp_prob, sl_prob, n_days, vola, ...) → dict`

Searches for the daily drift that makes simulated TP/SL hit rates match target probabilities. Key implementation detail: rather than a Python loop per path (as in R), returns all `n_sim × n_days` paths at once with `np.cumprod`, then uses `np.argmax` to find first-hit indices. Mirrors R's `impliedDrift()` in `5_4.r`.

---

## `chapter5/simulation.py`

**R equivalent:** `5_5a.r`, `5_5b.r`

### `simulate_portfolio_tpsl(drifts, cov_matrix, start_weights, cash_weight, tp_levels, sl_levels, n_days, n_sim, seed) → dict`

Simulates a multi-asset portfolio where each position is closed into cash when it hits its TP or SL level.

**Design note:** The TP/SL check requires path-dependent logic (the closing day changes the cash balance for all subsequent days), so a Python loop over days is unavoidable here. The outer `n_sim` loop is the main bottleneck — this is the primary candidate for optimisation in the next stage (e.g. numba JIT or Cython).

Returns `{terminal_wealth, max_drawdown, mean_terminal_wealth, std_terminal_wealth, mean_mdd, std_mdd}`. Mirrors R's `5_5a.r` and `5_5b.r`.

---

## `chapter5/copula.py`

**R equivalent:** `5_6a.r`, `5_6b.r`, `5_7.r`

### `gaussian_copula_binary(corr, n_assets, ret_up, ret_dn, p_up, n_sim, seed) → np.ndarray`

Three-step process matching R's `copula::rcopula` + `qbinom`:
1. Sample from multivariate normal with uniform pairwise correlation `corr`
2. Apply `Φ` (standard normal CDF) to get uniform marginals
3. Map uniforms > `(1 - p_up)` to `ret_up`, the rest to `ret_dn`

Returns shape `(n_sim, n_assets)`.

**Note on binary correlation shrinkage:** The resulting Pearson correlation between binary outcomes is lower than `corr` (the copula parameter). This is expected — binary marginals with equal probability cap the achievable linear correlation at the copula correlation. The benchmark verifies the direction and positivity, not the exact magnitude.

### `sequential_trading_simulation(returns, n_trades_per_block) → dict`

Groups the flat 1D return array into blocks of `n_trades_per_block` and computes terminal wealth and MDD per block. Mirrors R's `5_6b.r`.

### `sample_clayton_copula(theta, n_sim, seed) → np.ndarray`

Samples from the bivariate Clayton copula using the conditional inverse CDF algorithm:
1. Draw `u ~ Uniform(0,1)`
2. Draw `t ~ Uniform(0,1)` independent of `u`
3. Invert `C_{V|U}(v|u) = t` analytically:
   `v = (u^{-θ} × (t^{-θ/(θ+1)} - 1) + 1)^{-1/θ}`

Returns uniform marginals of shape `(n_sim, 2)`.

**Verification:** Kendall's τ for the Clayton copula is `θ/(θ+2)` (exact analytical result). The benchmark confirms `kendalltau(u, v) ≈ 0.5` for θ=2.

### `gaussian_copula_normal_margins` / `clayton_copula_normal_margins`

Wrap the sampling routines and apply `norm.ppf` to convert uniform marginals to normal marginals with specified mean and standard deviation. Used to compare scatter plot shapes between the two copulas (5_7.r).

---

## `chapter6/options.py`

**R equivalent:** `6_1.r`

### `bs_call_price(S, K, T, r, sigma) → float`

Standard Black-Scholes formula: `C = S·Φ(d1) - K·e^{-rT}·Φ(d2)`. Handles boundary cases `T=0` and `sigma=0` by returning intrinsic value.

### `bs_greeks(S, K, T, r, sigma) → dict`

Returns `{value, delta, gamma, vega}`:
- `delta = Φ(d1)` — sensitivity to underlying price
- `gamma = φ(d1) / (S·σ·√T)` — rate of change of delta
- `vega = S·φ(d1)·√T` — sensitivity to implied volatility (per unit σ, not per 1%)

**Matches R's RQuantLib sign convention.**

### `option_scenario_sweep(S0, K, T, r, sigma0, price_range_cents, vol_sensitivity) → pl.DataFrame`

Sweeps the underlying price from `S0 - range` to `S0 + range` in 1-cent steps, simultaneously adjusting implied vol by `-vol_sensitivity` per cent (modelling the observed inverse vol-price relationship / leverage effect). Returns a Polars DataFrame with all Greeks at each price point. Mirrors R's inner `for(i in -200:200)` loop in `6_1.r`.

### `plot_greeks_comparison(df_now, df_later) → Figure`

2×2 panel showing price, delta, gamma, and vega at two maturities. Mirrors R's `par(mfrow=c(2,2))` plots.

---

## Scripts (`scripts/`)

Each script is runnable standalone: `uv run python scripts/ch1_coin_flip.py`.

All scripts accept `--save` to write PNG files instead of calling `plt.show()`:
```
uv run python scripts/ch3_returns.py --save
```

| Script | Content |
|--------|---------|
| `ch1_coin_flip.py` | Exact and Monte Carlo binomial probability |
| `ch2_clt.py` | Coin-toss histogram and density plots |
| `ch3_returns.py` | DAX return distribution, outlier cap, monthly analysis, MDD comparison |
| `ch3_kelly.py` | Kelly curve, DAX Kelly fraction, sensitivity, backtest, drawdown risk |
| `ch4_randomness.py` | DAX runs test and ACF grid |
| `ch4_ma_strategy.py` | MA200 on DAX/DOW, dual MA crossover, seasonality, trading system |
| `ch5_portfolio.py` | Correlation, Nekrasov formula, implied drift, 2-asset portfolio sim |
| `ch5_copula.py` | Gaussian copula binary, sequential trading, Clayton vs Gaussian |
| `ch6_options.py` | B-S Greeks and scenario sweep for the SG32QT warrant |

---

## Benchmarks (`benchmarks/`)

Each benchmark compares Python outputs to R expected values. Run with:
```
uv run python benchmarks/compare_ch1.py
```

| File | What is verified | Tolerance type |
|------|-----------------|----------------|
| `compare_ch1.py` | `P(X≥60 \| Bin(100,0.5))` exact and MC | Exact: 1e-8; MC: 3× SE |
| `compare_ch3_kelly.py` | Analytical Kelly f*, growth rates, simulated f* | Analytical: 5e-3 (grid rounding); MC: ±10% |
| `compare_ch4_ma.py` | MA strategy invariants on synthetic series | Logical checks (not hardcoded numbers) |
| `compare_ch5_portfolio.py` | Nekrasov Σ formula, copula Kendall's τ=θ/(θ+2) | Exact for closed forms; MC: ±5% |
| `compare_ch6_options.py` | B-S price, greeks, put-call parity, boundary conditions | Machine precision (1e-8) |

### Benchmark philosophy

- **Deterministic outputs** (exact probability, Black-Scholes): compared to independently derived analytical values, not to R's text output. This avoids treating R as an oracle and instead verifies mathematical correctness.
- **Stochastic outputs** (Monte Carlo): verified against their statistical properties (mean within N standard errors, or known analytical moments).
- **Market-data-dependent outputs** (MA strategy): verified against logical invariants (positive wealth, boundary conditions) rather than hardcoded historical results which change as data updates.

---

## Key Differences from R Code

| Aspect | R | Python |
|--------|---|--------|
| Loops over MC paths | Nested `for` loops | Vectorised numpy (`size=(n_sim, n_periods)`) |
| Random numbers | `rnorm`, `rbinom`, `rmvnorm` | `np.random.default_rng` (seeded, reproducible) |
| Data format | `xts` time series | Polars DataFrame + numpy arrays |
| Covariance for simulation | `rmvnorm` from `mvtnorm` | `rng.multivariate_normal` from numpy |
| Matrix inverse | `MASS::ginv` | `np.linalg.pinv` |
| Option pricing | `RQuantLib::EuropeanOption` | Implemented from scratch with `scipy.stats.norm` |
| Copula sampling | `copula::rcopula` + `qbinom` | Manual: Φ⁻¹ transform + binary quantile |
| JIT acceleration | `compiler::cmpfun` + `enableJIT(3)` | Not needed — numpy vectorisation suffices |
| Output directory hardcoding | `D:\BOOK\images\...` | `--save` flag writes to current directory |
