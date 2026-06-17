"""
Chapter 5 — Portfolio Simulation with TP/SL (R scripts: 5_5a.r, 5_5b.r)

Simulates a portfolio of positions where each position has a take-profit (TP)
and stop-loss (SL). When a position's value hits TP or SL it is liquidated
into cash and stays there for the rest of the simulation period.
"""

import numpy as np
from yetanotherquant.chapter3.returns import max_drawdown


def simulate_portfolio_tpsl(
    drifts: np.ndarray,
    cov_matrix: np.ndarray,
    start_weights: np.ndarray,
    cash_weight: float,
    tp_levels: np.ndarray,
    sl_levels: np.ndarray,
    n_days: int = 121,
    n_sim: int = 10_000,
    seed: int | None = None,
) -> dict:
    """
    Monte Carlo simulation for a multi-asset portfolio with TP/SL rules.

    Each asset i starts with weight start_weights[i]. If the asset value
    crosses tp_levels[i] (up) or sl_levels[i] (down), it is transferred
    to cash for the remaining days.

    Parameters
    ----------
    drifts        : daily implied drift for each asset, shape (n_assets,)
    cov_matrix    : daily covariance matrix, shape (n_assets, n_assets)
    start_weights : initial portfolio weight of each asset, shape (n_assets,)
    cash_weight   : initial cash fraction
    tp_levels     : TP threshold as fraction of starting weight, shape (n_assets,)
    sl_levels     : SL threshold as fraction of starting weight, shape (n_assets,)
    n_days        : simulation horizon in trading days
    n_sim         : number of Monte Carlo paths

    Returns a dict with terminal wealth and MDD distributions.

    Mirrors R: 5_5a.r and 5_5b.r
    """
    rng = np.random.default_rng(seed)
    n_assets = len(drifts)

    term_wealth = np.empty(n_sim)
    mdd_values  = np.empty(n_sim)

    for i in range(n_sim):
        # Draw correlated daily returns: shape (n_days, n_assets)
        rets = rng.multivariate_normal(drifts, cov_matrix, size=n_days)

        asset_wealth = start_weights.copy().astype(float)
        cash = float(cash_weight)
        path_wealth = np.empty(n_days)
        path_wealth[0] = float(np.sum(asset_wealth) + cash)

        for d in range(1, n_days):
            for a in range(n_assets):
                if asset_wealth[a] > 0:
                    asset_wealth[a] *= (1 + rets[d, a])
                    # TP or SL hit: liquidate into cash
                    if asset_wealth[a] >= tp_levels[a] or asset_wealth[a] < sl_levels[a]:
                        cash += asset_wealth[a]
                        asset_wealth[a] = 0.0

            path_wealth[d] = float(np.sum(asset_wealth) + cash)

        term_wealth[i] = path_wealth[-1]
        mdd_values[i]  = max_drawdown(path_wealth)

    return {
        "terminal_wealth":       term_wealth,
        "max_drawdown":          mdd_values,
        "mean_terminal_wealth":  float(np.mean(term_wealth)),
        "std_terminal_wealth":   float(np.std(term_wealth)),
        "mean_mdd":              float(np.mean(mdd_values)),
        "std_mdd":               float(np.std(mdd_values)),
    }
