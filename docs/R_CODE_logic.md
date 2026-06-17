# R Code Logic Summary

These scripts accompany a quantitative trading book covering probability, Kelly betting, market microstructure, technical analysis, portfolio optimisation, and options. The code is structured by chapter, with `forFigX_Y.r` scripts generating specific book figures.

All files have been made self-contained (data loaded internally). One bug was fixed in `5_2a.r` (see §5).

---

## Chapter 1 — Probability Foundations

### `1_1.r`
**Topic:** Coin-flip tail probability.

Computes P(X ≥ 60 | X ~ Binomial(100, 0.5)) two ways:
- **Exact:** `1 - pbinom(59, 100, 0.5)` ≈ 2.8%
- **Monte Carlo:** 100,000 simulated experiments, count frequency of ≥60 heads

Illustrates that analytical and simulation results converge.

---

## Chapter 2 Figures — Central Limit Theorem

### `forFig2_1.r`
**Topic:** Histogram of biased coin outcomes with normal overlay.

Simulates 1,000 experiments of 10 biased coin tosses (p=0.55). Overlays a scaled normal density on the histogram to demonstrate CLT convergence.

### `forFig2_2.r`
**Topic:** Kernel density comparison: binomial vs. normal.

Smaller sample (N=200) version — shows how a binomial density resembles a normal for moderate N but retains discrete character with fewer observations.

---

## Chapter 3 — Return Distributions, Kelly Criterion, Simulation

### `3_1.r`
**Topic:** DAX data download and visualization.

Downloads DAX (`^GDAXI`) from Yahoo Finance via `quantmod`. Plots close price and discrete daily returns side-by-side.

### `3_2a.r`
**Topic:** DAX daily return distribution vs. normal.

Estimates empirical mu and sigma from DAX daily returns (dropping the first NA). Overlays empirical kernel density and a fitted normal density, then shows a QQ-plot. **Key finding:** fat tails — the QQ-plot shows S-curve deviation from the normal reference line.

### `3_2b.r`
**Topic:** DAX returns after 3-sigma outlier removal.

Caps returns outside ±3σ and re-runs the QQ-plot. The capped series is nearly normal, confirming that fat tails are driven by a small fraction of extreme events. Prints the fraction of returns that survive the filter.

### `3_2c.r`
**Topic:** Monthly DAX returns — CLT in action.

Aggregates daily returns to monthly frequency. Plots time series, QQ-plot, and density vs. normal. Monthly returns are visibly closer to normal than daily returns (fewer extreme outliers).

### `3_2d.r`
**Topic:** Monte Carlo wealth path simulation.

Uses hardcoded DAX monthly parameters (mu=0.0085, sigma=0.0605) to simulate 10,000 portfolio paths over 120 months. Plots three sample paths and the terminal wealth distribution.

### `3_3a.r`
**Topic:** Numerical Kelly fraction for DAX (monthly).

Iterates over 100 candidate fractions (1%–100% in DAX, remainder in 3%-annual cash). Simulates 10,000 paths × 120 months for each fraction, computing mean log-wealth. The maximising fraction is the Kelly-optimal allocation (~93% for DAX historical data).

### `3_3b.r`
**Topic:** Historical backtest of 30%, 50%, 93%, 100% DAX allocations.

Applies each fraction to actual DAX monthly returns (leveraged/de-leveraged via the portfolio return formula). Plots the four wealth curves. The ~Kelly fraction (93%) outperforms buy-and-hold (100%) over long horizons due to smaller drawdowns.

### `3_3c.r`
**Topic:** Kelly sensitivity to parameter estimation error.

Repeats the Kelly search three times, each time drawing a fresh sample of size n from the true DAX distribution. The optimal fraction fluctuates significantly across iterations, illustrating that Kelly is highly sensitive to input error and should be scaled down (fractional Kelly) in practice. Uses `compiler::cmpfun` for JIT acceleration.

### `3_4.r`
**Topic:** Normal vs. binomial return model comparison.

Builds three wealth series from DAX monthly data:
1. Empirical DAX
2. Normal-distributed returns (same mu/sigma)
3. Binary returns (mu ± sigma with equal probability)

Despite very different distributional shapes, all three produce similar-looking wealth paths — the first two moments dominate long-run outcomes.

### `3_5.r`
**Topic:** Terminal wealth and max drawdown: normal vs. binomial.

Repeats 3_4.r's comparison across 1,000 simulated paths, recording terminal wealth and maximum drawdown for each model. Uses `fTrading::maxDrawDown`. Shows distributions of both metrics — the normal model generates heavier MDD tails than the binomial model.

### `3_6a.r` — Exercise 3.1 Part 1
**Topic:** Kelly criterion for daily stock returns (two parameter sets).

Wraps the Kelly search in a function `solEx31Part1(mu, sigma)`. Tests two hypothetical stocks with different risk/return profiles. Uses JIT compilation for speed.

### `3_6b.r` — Exercise 3.1 Part 2
**Topic:** Drawdown risk at a given Kelly fraction.

Given a Kelly fraction, simulates 10,000 annual paths and computes:
- P(max drawdown < −5%)
- P(max drawdown < −20%)
- Distribution of terminal log-wealth

Evaluated for the same two stocks as 3_6a.r, with their respective Kelly fractions.

### `3_7.r`
**Topic:** Rolling historical volatility for Metro AG (MEO.DE).

Computes daily return standard deviation over five lookback windows: all-time, 1 year, 6 months, 1 quarter, 1 month. Displays candle charts for context. Demonstrates that short-window estimates are noisier but more responsive to recent conditions.

---

## Chapter 3 Figures — Kelly Illustration

### `forFig3_2.r`
**Topic:** Kelly formula curve for a coin-toss game.

Plots the expected log-growth rate g(f) = 0.5·log(1+1.7f) + 0.5·log(1−0.7f) for f ∈ [0,1]. Marks the analytical maximum at f* ≈ 0.42 (Kelly fraction) and shows that betting 100% has negative expected log-growth.

### `forFig3_3.r`
**Topic:** Wealth path comparison — all-in vs. Kelly vs. half-Kelly.

Simulates 30 coin-toss trades (win +170%, loss −70%) and plots three strategies:
- **Full bet (100%):** high variance, often ruin
- **Kelly (42%):** optimal long-run growth
- **Half-Kelly (21%):** lower growth but much smaller drawdowns

---

## Chapter 4 — Technical Analysis and Market Efficiency

### `4_1.r`
**Topic:** Runs test and ACF for DAX returns (market randomness).

Applies the Wald-Wolfowitz runs test and plots ACF for:
- Full sample
- 1st 1,000 trading days
- 3rd 1,000 trading days
- 4th 1,000 trading days (~2002–2006)

Shows that randomness is not uniformly present across all sub-periods — some show statistically significant autocorrelation.

### `4_2.r`
**Topic:** MA200 trend-following strategy on DAX 30 stocks (1995–2014).

Backtests a buy-above-MA200 / sell-below-MA200 rule on all 30 DAX constituents. Computes the wealth difference (buy-and-hold minus strategy) per stock. **Finding:** MA200 outperforms buy-and-hold on the German market. Saves per-stock charts to a local directory.

### `4_2a_dj30.r`
**Topic:** Same MA200 strategy on Dow Jones 30 (US market).

Identical logic to `4_2.r` applied to US tickers. **Finding:** MA200 does NOT beat buy-and-hold on US stocks over this period. Includes a note about a 2014 bug fix where the original signal was accidentally reversed.

### `4_3.r`
**Topic:** Dual MA crossover (MA38/MA200) on DJ30 Frankfurt tickers.

Replaces the price-vs-MA rule with a short-MA vs. long-MA crossover signal (golden cross / death cross). Tests on DJ30 stocks listed in Frankfurt (`.F` tickers). Merck excluded due to data availability issues.

### `4_4.r`
**Topic:** DAX monthly seasonality boxplot.

Computes monthly close-to-close returns for the full DAX history, groups by calendar month, and creates a boxplot. Inspects whether well-known anomalies (January effect, Sell in May) are visible in the data.

### `4_5.r`
**Topic:** Simulated trading system with 64% win rate.

Simulates a rule-based system with a 64% win probability and fixed ±0.3% return per trade, over 395 trades repeated 1,000 times. Reports distributions of terminal wealth and maximum drawdown. Useful for setting expectations and position-sizing before live trading.

---

## Chapter 5 — Portfolio Construction

### `5_1.r`
**Topic:** Correlation between bank and healthcare stocks.

Computes and plots Pearson correlations and scatter plots for three German stocks:
- Commerzbank (CBK.DE) vs. Deutsche Bank (DBK.DE): high correlation (~0.8)
- Fresenius (FRE.DE) vs. Deutsche Bank: low correlation (~0.1)

Demonstrates that sector diversification meaningfully reduces portfolio correlation.

### `5_2.r`
**Topic:** Optimal 2-asset + cash portfolio via brute force and Nekrasov's formula.

Two approaches to find the optimal fractions f1, f2 (no short-selling, f1+f2 ≤ 1):

1. **Nekrasov's formula:** u = (1+r) · Σ⁻¹ · (μ − r), where Σ is the non-central second moment matrix of excess returns (different from standard covariance).

2. **Brute force:** enumerate all (f1%, f2%) combinations, simulate 100 paths × 100 trades each, maximise mean log-terminal-wealth.

Plots a 3D scatter of mean log-wealth vs. (f1, f2) and highlights both theoretical and empirical optima. With a large enough sample they coincide.

### `5_2a.r`
**Topic:** Sensitivity of Nekrasov's formula to estimation error.

Repeats the formula with only 100 empirical observations per trial (3 trials). Shows that estimated optimal fractions vary widely from the true optimum, illustrating the "estimation error" problem in portfolio optimisation.

> **Bug fix:** the original code referenced `covMatrix` (a local variable inside `estimateSigma`); corrected to `covMat` (the global covariance matrix matching the new s1=0.4, s2=0.3 parameters).

### `5_3.r`
**Topic:** Correlation matrix for MEO.DE, SZU.DE, SLV.

Downloads daily returns for Metro AG, Südzucker, and iShares Silver Trust (May 2013 – May 2014). Aligns series to equal length and prints the 3×3 correlation matrix. Sets up data for `5_5a.r` and `5_5b.r`.

### `5_4.r`
**Topic:** Implied drift estimation via Monte Carlo.

Searches for the daily drift that makes simulated TP/SL hit frequencies match the analyst's forecast probabilities. Analogous to Black-Scholes implied volatility, but for directional trades. Example: MEO.DE bought at 29.79 with TP=35.40 and SL=26.40, 50% chance of each, over 141 trading days.

### `5_5a.r`
**Topic:** Old 2-asset portfolio simulation with TP/SL (MEO + SZU).

Simulates 10,000 paths over 121 trading days for a portfolio: 10% MEO, 10% SZU, 80% cash. When MEO hits TP or SL, the position is closed into cash. Uses correlated multivariate normal returns (MASS::mvrnorm). Reports terminal wealth and MDD distributions.

### `5_5b.r`
**Topic:** New 3-asset portfolio simulation with TP/SL (MEO + SZU + SLV).

Extends `5_5a.r` by adding 10% SLV (silver), reducing cash to 70%. SLV also has a TP and SL. The additional low-correlation asset improves the risk-adjusted return profile.

### `5_6a.r`
**Topic:** Correlated binary trade simulation via Gaussian copula.

Generates 100,000 simulated outcomes for a basket of 10 binary trades (each with equal probability of +13.4% or −5.15%). Uses a 10-dimensional Gaussian copula with pairwise correlation 0.31 to model realistic inter-trade dependence. Portfolio return = equal-weight average of all 10 trade outcomes.

### `5_6b.r`
**Topic:** Sequential portfolio performance from copula returns.

Uses the return stream from `5_6a.r` (replicated internally). Groups the 100,000 trades into blocks of 50, computing terminal wealth and MDD per block. Reports the distribution of cumulative log-growth rates and drawdowns over a 50-trade trading period.

### `5_7.r`
**Topic:** Clayton copula vs. Gaussian copula for 2-asset portfolio.

Compares a Clayton copula (strong lower-tail dependence, param=2) to a Gaussian copula for the same marginal distributions. Scatter plots clearly show the Clayton copula generates more joint crashes (bottom-left clustering), which the Gaussian model underestimates.

---

## Chapter 6 — Options

### `6_1.r`
**Topic:** European call option pricing and Greeks across price and vol changes.

Models a deeply OTM call option (SG32QT: underlying=23.81, strike=60, maturity=4yr, vol=37%). Simultaneously varies:
- Underlying price by ±2 EUR (in 1-cent steps)
- Implied vol inversely (−0.01% per 1 cent rise, capturing the volatility smile / leverage effect)

Computes price, delta, gamma, and vega for both the current maturity (4yr) and one year later (3yr). Plots all four Greeks in a 2×2 panel to show how time decay and price changes affect option risk.

---

## Dependency Map (before standalone conversion)

The following files originally required prior execution of another script. They now load all necessary data internally:

| File | Originally required | Key shared variables |
|------|-------------------|----------------------|
| `3_2b.r` | `3_2a.r` | `daxReturns`, `n` |
| `3_2c.r` | `3_2a.r` | `GDAXI` (getSymbols) |
| `3_3b.r` | `3_3a.r` | `daxMonthlyRets`, `n`, `r` |
| `3_3c.r` | `3_3a.r` | `daxMonthlyRets`, `N_STEPS`, `N_SIMULATIONS`, `N_MONTHS`, `r` |
| `3_5.r`  | `3_4.r`  | `n`, `mu`, `sigma` |
| `5_2a.r` | `5_2.r`  | `estimateSigma()`, `expRets`, `riskFreeReturn`; bug: `covMatrix` → `covMat` |
| `5_5a.r` | `5_3.r`  | `retsMEO`, `retsSZU`, `n` |
| `5_5b.r` | `5_3.r`  | `retsMatrix`, `retsMEO`, `retsSZU` |
| `5_6b.r` | `5_6a.r` | `returns`, `N_SIMULATIONS` |

---

## Key Libraries Used

| Library | Purpose |
|---------|---------|
| `quantmod` | Download Yahoo Finance data, compute returns, candlestick charts |
| `fTrading` / `tseries` | `maxDrawDown` / `maxdrawdown` for drawdown calculation |
| `mvtnorm` | Multivariate normal distribution sampling |
| `MASS` | Generalised matrix inverse (`ginv`) for Nekrasov's formula |
| `copula` | Gaussian and Clayton copula simulation |
| `lawstat` | Wald-Wolfowitz runs test |
| `scatterplot3d` | 3D portfolio frontier visualisation |
| `compiler` | JIT compilation (`cmpfun`, `enableJIT`) for nested loop speed-up |
| `RQuantLib` | Black-Scholes option pricing and Greeks |
