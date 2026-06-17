"""
Chapter 5 — Portfolio Construction (R scripts: 5_1.r, 5_2.r, 5_2a.r, 5_3.r, 5_4.r)

Functions for:
  - Correlation analysis between assets
  - Nekrasov's closed-form Kelly formula for multi-asset portfolios
  - Brute-force optimal fraction search (grid over f1, f2)
  - Implied drift estimation (analogous to implied volatility)
"""

import numpy as np
import polars as pl
from scipy.stats import norm
from itertools import product
import matplotlib.pyplot as plt


# ---------------------------------------------------------------------------
# Correlation analysis (5_1.r, 5_3.r)
# ---------------------------------------------------------------------------

def correlation_matrix(returns_dict: dict[str, np.ndarray]) -> pl.DataFrame:
    """
    Compute the Pearson correlation matrix for a set of return series.

    returns_dict: {asset_name: return_array}
    Returns a Polars DataFrame (n_assets × n_assets correlation matrix).
    """
    names = list(returns_dict.keys())
    n = len(names)
    matrix = np.corrcoef([returns_dict[k] for k in names])
    df = pl.DataFrame({names[i]: matrix[:, i].tolist() for i in range(n)})
    return df.with_columns(pl.Series("asset", names)).select(["asset"] + names)


# ---------------------------------------------------------------------------
# Nekrasov's formula (5_2.r, 5_2a.r)
# ---------------------------------------------------------------------------

def estimate_sigma(returns_matrix: np.ndarray, r_f: float) -> np.ndarray:
    """
    Estimate the non-central second moment matrix of excess returns.

    Sigma[i,j] = E[(r_i - r_f)(r_j - r_f)]

    This is NOT the standard covariance matrix. It includes the cross-product
    of mean excess returns, which is why the Kelly fraction is higher than
    the mean-variance formula would give.

    returns_matrix: shape (n_obs, n_assets)
    Mirrors R: estimateSigma() in 5_2.r
    """
    excess = returns_matrix - r_f  # broadcast: subtract scalar from each row
    return (excess.T @ excess) / len(excess)


def nekrasov_optimal(
    mu: np.ndarray,
    sigma: np.ndarray,
    r_f: float,
) -> np.ndarray:
    """
    Nekrasov's closed-form Kelly fractions for a multi-asset portfolio.

    u = (1 + r_f) * Sigma^{-1} * (mu - r_f)

    Uses the Moore-Penrose pseudo-inverse for numerical stability.

    Mirrors R: u = (1+riskFreeReturn) * ginv(Sigma) %*% (expRets - riskFreeReturn)
    """
    excess_mu = np.asarray(mu) - r_f
    return (1 + r_f) * np.linalg.pinv(sigma) @ excess_mu


# ---------------------------------------------------------------------------
# Brute-force optimal fraction (5_2.r)
# ---------------------------------------------------------------------------

def brute_force_two_asset(
    mu: np.ndarray,
    cov: np.ndarray,
    r_f: float,
    path_len: int = 100,
    n_sim: int = 100,
    seed: int | None = None,
) -> dict:
    """
    Enumerate all (f1%, f2%) combinations with f1+f2 ≤ 100%, simulate n_sim
    paths of path_len trades each, and find the fractions that maximise mean
    log-terminal-wealth.

    Returns a dict with:
      optimal_f1, optimal_f2  — best fractions found
      mean_log_wealth_grid    — array of shape (n_combinations,)
      fracs                   — array of shape (n_combinations, 2)

    Mirrors R: allFracs() in 5_2.r
    """
    from scipy.stats import multivariate_normal as mvn_dist

    rng = np.random.default_rng(seed)

    # Pre-generate all path returns: shape (n_sim, path_len, 2)
    all_rets = rng.multivariate_normal(mu, cov, size=(n_sim, path_len))
    all_rets = np.clip(all_rets, -0.95, 0.95)

    # Build list of (f1, f2) pairs
    frac_pairs = [
        (i / 100, j / 100)
        for i in range(101)
        for j in range(101 - i)
    ]
    n_combos = len(frac_pairs)
    fracs = np.array(frac_pairs)
    log_wealth = np.empty(n_combos)

    for idx, (f1, f2) in enumerate(frac_pairs):
        cash = 1.0 - f1 - f2
        # Portfolio return each step: f1*r1 + f2*r2 + cash*(1+r_f) - 1
        port_rets = (
            (1 + all_rets[:, :, 0]) * f1
            + (1 + all_rets[:, :, 1]) * f2
            + (1 + r_f) * cash
        )  # shape (n_sim, path_len)
        terminal = np.prod(port_rets, axis=1)  # shape (n_sim,)
        log_wealth[idx] = float(np.mean(np.log(np.maximum(terminal, 1e-10))))

    best = int(np.argmax(log_wealth))
    return {
        "optimal_f1":          fracs[best, 0],
        "optimal_f2":          fracs[best, 1],
        "mean_log_wealth_grid": log_wealth,
        "fracs":               fracs,
    }


# ---------------------------------------------------------------------------
# Implied drift estimation (5_4.r)
# ---------------------------------------------------------------------------

def implied_drift(
    buy_price: float,
    tp: float,
    sl: float,
    tp_prob: float,
    sl_prob: float,
    n_days: int,
    vola: float,
    n_steps: int = 100,
    n_sim: int = 100_000,
    seed: int | None = None,
) -> dict:
    """
    Find the daily drift such that simulated TP/SL hit rates match target probabilities.

    Searches over n_steps candidate drifts (0.01%, 0.02%, …, n_steps/100 %).
    Returns the drift that minimises |simulated_tp_prob - tp_prob| + |simulated_sl_prob - sl_prob|.

    Mirrors R: impliedDrift() in 5_4.r
    """
    rng = np.random.default_rng(seed)
    target_up   = tp / buy_price
    target_down = sl / buy_price
    drifts = np.arange(1, n_steps + 1) / 10_000  # 0.01% to 0.10% per day

    tp_counts = np.zeros(n_steps)
    sl_counts = np.zeros(n_steps)

    for d, drift in enumerate(drifts):
        rets = rng.normal(drift, vola, size=(n_sim, n_days))
        prices = np.cumprod(1 + rets, axis=1)

        # Check if TP or SL is hit first
        tp_hit = np.any(prices >= target_up,   axis=1)
        sl_hit = np.any(prices <= target_down, axis=1)

        # First-hit logic: TP wins if the TP crossing comes before SL
        tp_first_idx = np.where(tp_hit, np.argmax(prices >= target_up,   axis=1), n_days)
        sl_first_idx = np.where(sl_hit, np.argmax(prices <= target_down, axis=1), n_days)

        tp_counts[d] = float(np.mean(tp_hit & (tp_first_idx <= sl_first_idx)))
        sl_counts[d] = float(np.mean(sl_hit & (sl_first_idx < tp_first_idx)))

    residuals = np.abs(tp_counts - tp_prob) + np.abs(sl_counts - sl_prob)
    best = int(np.argmin(residuals))

    return {
        "implied_drift":       float(drifts[best]),
        "empirical_tp_prob":   float(tp_counts[best]),
        "empirical_sl_prob":   float(sl_counts[best]),
    }
