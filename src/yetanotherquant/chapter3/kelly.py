"""
Chapter 3 — Kelly Criterion (R scripts: 3_3a – 3_3c, 3_6a – 3_6b, forFig3_2, forFig3_3)

Functions for:
  - Analytical Kelly fraction for simple coin-toss games
  - Numerical Kelly search via Monte Carlo simulation (single asset)
  - Kelly sensitivity analysis
  - Wealth-path comparison across Kelly fractions
  - Drawdown risk at a given Kelly fraction
"""

import matplotlib.pyplot as plt
import numpy as np

# ---------------------------------------------------------------------------
# Analytical Kelly
# ---------------------------------------------------------------------------


def analytical_kelly_coin(p_win: float, win_mult: float, loss_mult: float) -> float:
    """
    Analytical Kelly fraction for a binary bet.

    f* = p/loss_mult - q/win_mult   (where q = 1 - p)

    Example: p=0.5, win=1.7, loss=0.7 → f* ≈ 0.42

    Mirrors R: which.max(expectedGrowthRates) / 100 in forFig3_2.r
    """
    q = 1.0 - p_win
    return p_win / loss_mult - q / win_mult


def expected_growth_rate(
    fractions: np.ndarray, p_win: float, win_mult: float, loss_mult: float
) -> np.ndarray:
    """
    Expected log-growth rate for each betting fraction in a coin-toss game.

    g(f) = p*log(1 + win*f) + q*log(1 - loss*f)

    Mirrors R: forFig3_2.r
    """
    q = 1.0 - p_win
    return p_win * np.log(1 + win_mult * fractions) + q * np.log(
        1 - loss_mult * fractions
    )


def plot_growth_rate_curve(
    p_win: float = 0.5,
    win_mult: float = 1.7,
    loss_mult: float = 0.7,
) -> plt.Figure:
    """
    Plot expected log-growth rate vs. fraction bet, marking the Kelly optimum.

    Mirrors R: forFig3_2.r
    """
    fractions = np.arange(1, 101) / 100
    rates = expected_growth_rate(fractions, p_win, win_mult, loss_mult)
    f_star = analytical_kelly_coin(p_win, win_mult, loss_mult)

    fig, ax = plt.subplots()
    ax.plot(fractions, rates, color="black", linewidth=2)
    ax.axvline(x=f_star, color="grey")
    ax.axhline(y=float(np.interp(f_star, fractions, rates)), color="grey")
    ax.axhline(y=rates[-1], color="grey", linestyle="--")
    ax.set_xlabel("Fraction of capital bet (f)")
    ax.set_ylabel("Expected log-growth rate g(f)")
    ax.set_title(f"Kelly fraction f* ≈ {f_star:.2f}")
    return fig


# ---------------------------------------------------------------------------
# Numerical Kelly search (Monte Carlo)
# ---------------------------------------------------------------------------


def kelly_simulation(
    mu: float,
    sigma: float,
    r_f: float,
    n_steps: int = 100,
    n_sim: int = 10_000,
    n_periods: int = 120,
    seed: int | None = None,
) -> np.ndarray:
    """
    Numerically find the optimal Kelly fraction by Monte Carlo simulation.

    Iterates over n_steps candidate fractions (1/n_steps, 2/n_steps, …, 1).
    For each fraction f, simulates n_sim paths of n_periods periods and
    records the mean log-wealth.  Returns the mean_log_wealth array.

    The fraction that maximises mean_log_wealth is the simulated Kelly fraction:
        optimal_index = np.argmax(result) + 1   (1-indexed to match R)
        optimal_frac  = optimal_index / n_steps

    Mirrors R: 3_3a.r and 3_6a.r — but vectorised (no Python loops over sims).
    """
    rng = np.random.default_rng(seed)
    mean_log_wealth = np.empty(n_steps)

    for u in range(1, n_steps + 1):
        frac = u / n_steps
        # Draw all returns at once: shape (n_sim, n_periods)
        rets = rng.normal(mu, sigma, size=(n_sim, n_periods))
        rets = np.clip(rets, -0.99, 0.99)
        portfolio_rets = frac * (rets - r_f) + (1.0 + r_f)
        # Terminal wealth = product of period returns
        terminal = np.prod(portfolio_rets, axis=1)
        mean_log_wealth[u - 1] = float(np.mean(np.log(terminal)))

    return mean_log_wealth


def optimal_kelly_fraction(mean_log_wealth: np.ndarray, n_steps: int = 100) -> float:
    """Return the fraction (0–1) that maximised mean log-wealth."""
    return float(np.argmax(mean_log_wealth) + 1) / n_steps


def kelly_sensitivity(
    monthly_returns: np.ndarray,
    r_f: float,
    n_iterations: int = 3,
    n_steps: int = 100,
    n_sim: int = 10_000,
    n_months: int = 120,
    seed: int | None = None,
) -> list[dict]:
    """
    Run the Kelly search n_iterations times, each time estimating mu/sigma
    from a fresh sample of the same size as the historical data.

    Shows how estimation error causes the optimal fraction to vary.
    Mirrors R: 3_3c.r
    """
    rng = np.random.default_rng(seed)
    true_mu = float(np.mean(monthly_returns))
    true_sigma = float(np.std(monthly_returns))
    n = len(monthly_returns)

    results = []
    for i in range(n_iterations):
        # Simulate a limited sample — as if we only had n historical observations
        sample = rng.normal(true_mu, true_sigma, n)
        mu_est = float(np.mean(sample))
        sigma_est = float(np.std(sample))

        mlw = kelly_simulation(
            mu_est, sigma_est, r_f, n_steps, n_sim, n_months, seed=rng.integers(1e9)
        )
        frac = optimal_kelly_fraction(mlw, n_steps)
        results.append(
            {
                "iteration": i + 1,
                "mu_est": mu_est,
                "sigma_est": sigma_est,
                "optimal_frac": frac,
            }
        )

    return results


# ---------------------------------------------------------------------------
# Wealth-path backtest at fixed fractions (3_3b.r)
# ---------------------------------------------------------------------------


def backtest_kelly_fractions(
    monthly_returns: np.ndarray,
    r_f: float,
    fracs: list[float],
) -> dict[str, np.ndarray]:
    """
    Apply each allocation fraction to a historical return series and compound.

    portfolio_ret = frac * (r - r_f) + (1 + r_f)

    Returns a dict mapping fraction label → cumulative wealth array.
    Mirrors R: 3_3b.r
    """
    n = len(monthly_returns)
    result = {}
    for frac in fracs:
        wealth = np.ones(n)
        for m in range(1, n):
            ret = float(monthly_returns[m - 1])
            wealth[m] = wealth[m - 1] * (frac * (ret - r_f) + (1 + r_f))
        result[f"{int(frac*100)}%"] = wealth
    return result


# ---------------------------------------------------------------------------
# Kelly fraction wealth comparison (forFig3_3.r)
# ---------------------------------------------------------------------------


def simulate_betting_strategies(
    n_trades: int = 30,
    p_win: float = 0.5,
    win_mult: float = 1.7,
    loss_mult: float = 0.7,
    kelly_frac: float = 0.42,
    seed: int | None = None,
) -> dict[str, np.ndarray]:
    """
    Simulate three strategies over a sequence of coin-toss trades:
      - 'full': bet everything each trade
      - 'kelly': bet the Kelly fraction
      - 'half_kelly': bet half the Kelly fraction

    Returns a dict of wealth arrays (length n_trades).
    Mirrors R: forFig3_3.r
    """
    rng = np.random.default_rng(seed)
    outcomes = rng.binomial(1, p_win, size=n_trades)  # 1=win, 0=loss

    full_w = np.ones(n_trades)
    kelly_w = np.ones(n_trades)
    half_w = np.ones(n_trades)
    hk = kelly_frac / 2

    for i in range(1, n_trades):
        if outcomes[i] == 0:  # loss
            full_w[i] = full_w[i - 1] * (1 - loss_mult)
            kelly_w[i] = kelly_w[i - 1] * (
                kelly_frac * (1 - loss_mult) + (1 - kelly_frac)
            )
            half_w[i] = half_w[i - 1] * (hk * (1 - loss_mult) + (1 - hk))
        else:  # win
            full_w[i] = full_w[i - 1] * (1 + win_mult)
            kelly_w[i] = kelly_w[i - 1] * (
                kelly_frac * (1 + win_mult) + (1 - kelly_frac)
            )
            half_w[i] = half_w[i - 1] * (hk * (1 + win_mult) + (1 - hk))

    return {"full": full_w, "kelly": kelly_w, "half_kelly": half_w}


# ---------------------------------------------------------------------------
# Drawdown risk at a given Kelly fraction (3_6b.r)
# ---------------------------------------------------------------------------


def drawdown_risk_at_fraction(
    mu: float,
    sigma: float,
    kelly_frac: float,
    r_f: float,
    n_days: int = 242,
    n_sim: int = 10_000,
    dd_thresholds: list[float] | None = None,
    seed: int | None = None,
) -> dict:
    """
    Given a Kelly fraction, simulate n_sim annual paths and compute:
      - Probability that max drawdown exceeds each threshold
      - Mean and std of terminal log-wealth

    Mirrors R: 3_6b.r
    """
    from yetanotherquant.chapter3.returns import max_drawdown

    if dd_thresholds is None:
        dd_thresholds = [0.05, 0.20]

    rng = np.random.default_rng(seed)
    rets = rng.normal(mu, sigma, size=(n_sim, n_days))
    rets = np.clip(rets, -0.99, 0.99)
    portfolio_rets = (rets - r_f) * kelly_frac + (1 + r_f)

    # Cumulative wealth paths: shape (n_sim, n_days)
    wealth_paths = np.cumprod(portfolio_rets, axis=1)
    full_paths = np.hstack([np.ones((n_sim, 1)), wealth_paths])

    mdd_values = np.array([max_drawdown(full_paths[i]) for i in range(n_sim)])
    terminal_log = np.log(wealth_paths[:, -1])

    result = {
        "mean_terminal_log_wealth": float(np.mean(terminal_log)),
        "std_terminal_log_wealth": float(np.std(terminal_log)),
    }
    for thr in dd_thresholds:
        result[f"prob_mdd_lt_{int(thr*100)}pct"] = float(np.mean(mdd_values < -thr))

    return result
