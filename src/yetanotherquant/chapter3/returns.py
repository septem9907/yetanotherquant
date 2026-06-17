"""
Chapter 3 — Return Distributions and Simulation (R scripts: 3_1 – 3_5, 3_7)

Functions for:
  - Comparing empirical return distributions to a normal model
  - Outlier filtering (3-sigma cap)
  - Monte Carlo wealth-path simulation
  - Historical volatility over multiple lookback windows
"""

import numpy as np
import polars as pl
from scipy.stats import norm
import matplotlib.pyplot as plt


# ---------------------------------------------------------------------------
# Distribution analysis
# ---------------------------------------------------------------------------

def fit_normal(returns: np.ndarray) -> tuple[float, float]:
    """Estimate mean and standard deviation from a return array."""
    return float(np.mean(returns)), float(np.std(returns))


def plot_density_vs_normal(
    returns: np.ndarray,
    title: str = "Return Density vs Normal",
) -> plt.Figure:
    """
    Overlay empirical KDE and fitted normal density.

    Mirrors R: plot(density(returns)); lines(density(normalRets), col='grey')
    """
    from scipy.stats import gaussian_kde

    mu, sigma = fit_normal(returns)
    x = np.linspace(returns.min(), returns.max(), 400)
    kde = gaussian_kde(returns)
    fig, ax = plt.subplots()
    ax.plot(x, kde(x),                    color="black", linewidth=2, label="Empirical")
    ax.plot(x, norm.pdf(x, mu, sigma),    color="grey",  linewidth=2, label="Normal fit")
    ax.set_title(title)
    ax.legend()
    return fig


def plot_qq_normal(returns: np.ndarray, title: str = "Normal QQ-Plot") -> plt.Figure:
    """
    Quantile-quantile plot against the standard normal.

    Mirrors R: qqnorm(returns)
    """
    from scipy.stats import probplot

    fig, ax = plt.subplots()
    (osm, osr), (slope, intercept, r) = probplot(returns, dist="norm")
    ax.scatter(osm, osr, s=4, color="black", alpha=0.5)
    ax.plot(osm, slope * np.array(osm) + intercept, color="grey", linewidth=2)
    ax.set_xlabel("Theoretical Quantiles")
    ax.set_ylabel("Sample Quantiles")
    ax.set_title(title)
    return fig


def filter_outliers(returns: np.ndarray, n_sigma: float = 3.0) -> np.ndarray:
    """
    Remove returns beyond ±n_sigma standard deviations.

    Mirrors R: cap <- 3*sd(...); capRets <- returns[abs(returns) < cap]
    """
    cap = n_sigma * float(np.std(returns))
    return returns[np.abs(returns) < cap]


def compare_normal_binomial_models(
    monthly_returns: np.ndarray,
    seed: int | None = None,
) -> dict:
    """
    Build three cumulative wealth series from the same mu/sigma:
      - 'empirical': actual returns compounded
      - 'normal':    Gaussian simulated returns
      - 'binomial':  binary ±sigma returns

    Mirrors R: 3_4.r
    Returns a dict of numpy arrays (length n).
    """
    rng = np.random.default_rng(seed)
    n = len(monthly_returns)
    mu, sigma = fit_normal(monthly_returns)

    sim_normal = rng.normal(mu, sigma, n)

    signs = rng.choice([-1, 1], size=n)
    sim_binary = mu + sigma * signs

    def compound(rets):
        w = np.ones(n)
        for i in range(1, n):
            w[i] = w[i - 1] * (1 + rets[i - 1])
        return w

    return {
        "empirical": compound(monthly_returns),
        "normal":    compound(sim_normal),
        "binomial":  compound(sim_binary),
    }


# ---------------------------------------------------------------------------
# Wealth-path simulation
# ---------------------------------------------------------------------------

def simulate_wealth_paths(
    mu: float,
    sigma: float,
    n_sim: int = 10_000,
    n_months: int = 120,
    seed: int | None = None,
) -> np.ndarray:
    """
    Simulate n_sim independent wealth paths over n_months months.

    Returns array of shape (n_sim, n_months). Each row starts at 1.0.
    Mirrors R: 3_2d.r
    """
    rng = np.random.default_rng(seed)
    rets = rng.normal(mu, sigma, size=(n_sim, n_months))
    # Compound returns along the time axis
    wealth = np.cumprod(1 + rets, axis=1)
    # Prepend a column of 1.0 for t=0
    ones = np.ones((n_sim, 1))
    return np.hstack([ones, wealth[:, :-1]])


def max_drawdown(wealth: np.ndarray) -> float:
    """
    Maximum drawdown of a wealth series: (trough / previous peak) - 1.

    Returns a negative number (e.g. -0.30 for a 30% drawdown).
    Mirrors R: fTrading::maxDrawDown / tseries::maxdrawdown.
    """
    peak = np.maximum.accumulate(wealth)
    drawdowns = wealth / peak - 1
    return float(np.min(drawdowns))


def simulate_terminal_wealth_and_mdd(
    monthly_returns: np.ndarray,
    n_sim: int = 1_000,
    seed: int | None = None,
) -> dict:
    """
    Simulate n_sim paths for both the normal and binomial return models,
    returning terminal wealth and MDD distributions for each.

    Mirrors R: 3_5.r
    """
    rng = np.random.default_rng(seed)
    n = len(monthly_returns)
    mu, sigma = fit_normal(monthly_returns)

    tw_norm = np.empty(n_sim)
    tw_binom = np.empty(n_sim)
    mdd_norm = np.empty(n_sim)
    mdd_binom = np.empty(n_sim)

    for k in range(n_sim):
        # Normal model
        r_norm = rng.normal(mu, sigma, n)
        w_norm = np.cumprod(1 + r_norm)
        tw_norm[k] = w_norm[-1]
        mdd_norm[k] = max_drawdown(np.insert(w_norm, 0, 1.0))

        # Binomial model
        signs = rng.choice([-1, 1], size=n)
        r_binom = mu + sigma * signs
        w_binom = np.cumprod(1 + r_binom)
        tw_binom[k] = w_binom[-1]
        mdd_binom[k] = max_drawdown(np.insert(w_binom, 0, 1.0))

    return {
        "terminal_wealth_normal":  tw_norm,
        "terminal_wealth_binomial": tw_binom,
        "mdd_normal":              mdd_norm,
        "mdd_binomial":            mdd_binom,
    }


# ---------------------------------------------------------------------------
# Historical volatility (3_7.r)
# ---------------------------------------------------------------------------

def rolling_volatility(returns: np.ndarray, windows: dict[str, int]) -> dict[str, float]:
    """
    Compute historical volatility over multiple lookback windows.

    windows: dict mapping label -> number of trading days, e.g.
             {'all': len(r), '1yr': 242, '6mo': 121, '1q': 63, '1mo': 21}
    Returns a dict of {label: annualised_daily_sigma}.
    Mirrors R: 3_7.r
    """
    n = len(returns)
    result = {}
    for label, days in windows.items():
        start = max(0, n - days)
        result[label] = round(float(np.std(returns[start:])), 4)
    return result
