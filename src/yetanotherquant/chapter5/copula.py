"""
Chapter 5 — Copula Simulation (R scripts: 5_6a.r, 5_6b.r, 5_7.r)

Functions for:
  - Gaussian copula with binary trade outcomes (5_6a.r)
  - Sequential portfolio simulation from copula returns (5_6b.r)
  - Clayton copula vs Gaussian copula comparison (5_7.r)
"""

import numpy as np
from scipy.stats import norm

from yetanotherquant.chapter3.returns import max_drawdown

# ---------------------------------------------------------------------------
# Gaussian copula with binary returns (5_6a.r)
# ---------------------------------------------------------------------------


def build_corr_matrix(corr: float, n: int) -> np.ndarray:
    """Uniform pairwise correlation matrix: off-diagonal = corr, diagonal = 1."""
    mat = np.full((n, n), corr)
    np.fill_diagonal(mat, 1.0)
    return mat


def gaussian_copula_binary(
    corr: float,
    n_assets: int,
    ret_up: float,
    ret_dn: float,
    p_up: float = 0.5,
    n_sim: int = 100_000,
    seed: int | None = None,
) -> np.ndarray:
    """
    Simulate correlated binary trade returns via a Gaussian copula.

    Steps (matching R's copula::rcopula + qbinom approach):
      1. Sample from a multivariate normal with the given correlation matrix
      2. Apply the standard-normal CDF to get uniform marginals
      3. Map uniforms > 0.5 to ret_up, the rest to ret_dn

    Returns array of shape (n_sim, n_assets) with individual trade returns.

    Mirrors R: 5_6a.r
    """
    rng = np.random.default_rng(seed)
    corr_matrix = build_corr_matrix(corr, n_assets)

    # Step 1: multivariate normal samples
    mvn_samples = rng.multivariate_normal(np.zeros(n_assets), corr_matrix, size=n_sim)
    # Step 2: uniform marginals via Phi
    uniforms = norm.cdf(mvn_samples)
    # Step 3: binary mapping — qbinom(u, 1, p_up) = 1 if u > (1 - p_up), else 0
    is_up = uniforms > (1 - p_up)
    returns = np.where(is_up, ret_up, ret_dn)
    return returns  # shape (n_sim, n_assets)


def portfolio_returns_from_copula(
    asset_returns: np.ndarray,
    weights: np.ndarray | None = None,
) -> np.ndarray:
    """
    Compute equal-weight (or weighted) portfolio return from correlated asset returns.

    asset_returns: shape (n_sim, n_assets)
    Returns 1D array of portfolio returns, shape (n_sim,).
    """
    if weights is None:
        weights = np.ones(asset_returns.shape[1]) / asset_returns.shape[1]
    return asset_returns @ weights


def sequential_trading_simulation(
    returns: np.ndarray,
    n_trades_per_block: int = 50,
    seed: int | None = None,
) -> dict:
    """
    Group the flat returns array into sequential blocks of n_trades_per_block,
    compute terminal wealth and max drawdown for each block.

    Mirrors R: 5_6b.r
    """
    n_total = len(returns)
    n_blocks = n_total // n_trades_per_block

    term_wealth = np.empty(n_blocks)
    mdd_values = np.empty(n_blocks)

    for b in range(n_blocks):
        start = b * n_trades_per_block
        block_rets = returns[start : start + n_trades_per_block]
        wealth = np.cumprod(1 + block_rets)
        wealth_full = np.insert(wealth, 0, 1.0)
        term_wealth[b] = wealth[-1]
        mdd_values[b] = max_drawdown(wealth_full)

    log_growth = np.log(term_wealth)
    return {
        "terminal_wealth": term_wealth,
        "max_drawdown": mdd_values,
        "mean_log_growth_rate": float(np.mean(log_growth)),
        "std_log_growth_rate": float(np.std(log_growth)),
        "mean_mdd": float(np.mean(mdd_values)),
        "std_mdd": float(np.std(mdd_values)),
    }


# ---------------------------------------------------------------------------
# Clayton copula comparison (5_7.r)
# ---------------------------------------------------------------------------


def sample_clayton_copula(
    theta: float, n_sim: int, seed: int | None = None
) -> np.ndarray:
    """
    Sample from a bivariate Clayton copula with parameter theta (theta > 0).

    Uses the conditional sampling algorithm:
      1. Sample u ~ Uniform(0,1)
      2. Sample t ~ Uniform(0,1) independent of u
      3. v = ( u^{-theta} * (t^{-theta/(theta+1)} - 1) + 1 )^{-1/theta}

    Returns array of shape (n_sim, 2) with uniform marginals.
    """
    rng = np.random.default_rng(seed)
    u = rng.uniform(size=n_sim)
    t = rng.uniform(size=n_sim)
    # Conditional inverse CDF
    v = (u ** (-theta) * (t ** (-theta / (theta + 1)) - 1) + 1) ** (-1 / theta)
    v = np.clip(v, 1e-10, 1 - 1e-10)
    return np.column_stack([u, v])


def gaussian_copula_normal_margins(
    mean: np.ndarray,
    sigma_diag: np.ndarray,
    rho: float,
    n_sim: int,
    seed: int | None = None,
) -> np.ndarray:
    """
    Sample from a bivariate Gaussian copula with normal margins.

    mean:       (mu1, mu2)
    sigma_diag: (std1, std2)
    rho:        linear correlation
    Returns array of shape (n_sim, 2).

    Mirrors R: mvrnorm() in 5_7.r
    """
    rng = np.random.default_rng(seed)
    cov = np.array(
        [
            [sigma_diag[0] ** 2, rho * sigma_diag[0] * sigma_diag[1]],
            [rho * sigma_diag[0] * sigma_diag[1], sigma_diag[1] ** 2],
        ]
    )
    return rng.multivariate_normal(mean, cov, size=n_sim)


def clayton_copula_normal_margins(
    mean: np.ndarray,
    sigma_diag: np.ndarray,
    theta: float,
    n_sim: int,
    seed: int | None = None,
) -> np.ndarray:
    """
    Sample from a bivariate Clayton copula with normal margins (via inversion).

    Steps:
      1. Sample uniform pairs from the Clayton copula
      2. Apply the inverse normal CDF to each marginal

    Returns array of shape (n_sim, 2).

    Mirrors R: rmvdc(myMvd, n) with clayton copula in 5_7.r
    """
    uniforms = sample_clayton_copula(theta, n_sim, seed=seed)
    samples = np.column_stack(
        [
            norm.ppf(uniforms[:, 0], loc=mean[0], scale=sigma_diag[0]),
            norm.ppf(uniforms[:, 1], loc=mean[1], scale=sigma_diag[1]),
        ]
    )
    return samples
