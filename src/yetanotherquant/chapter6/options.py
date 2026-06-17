"""
Chapter 6 — Options Pricing and Greeks (R script: 6_1.r)

Black-Scholes European call option implemented from scratch using scipy.stats.norm.
Computes price, delta, gamma, and vega across a range of underlying prices and
implied volatilities (modelling the inverse vol-price relationship).
"""

import numpy as np
from scipy.stats import norm
import matplotlib.pyplot as plt
import polars as pl


# ---------------------------------------------------------------------------
# Core Black-Scholes formulas
# ---------------------------------------------------------------------------

def _d1(S: float, K: float, T: float, r: float, sigma: float) -> float:
    return (np.log(S / K) + (r + 0.5 * sigma**2) * T) / (sigma * np.sqrt(T))


def bs_call_price(S: float, K: float, T: float, r: float, sigma: float) -> float:
    """
    European call option price (Black-Scholes, no dividends).

    S     : current underlying price
    K     : strike price
    T     : time to maturity in years
    r     : continuously compounded risk-free rate
    sigma : implied volatility (annualised)

    Mirrors R: EuropeanOption("call", S, K, 0, r, T, sigma)$value
    """
    if T <= 0 or sigma <= 0:
        return max(S - K, 0.0)
    d1 = _d1(S, K, T, r, sigma)
    d2 = d1 - sigma * np.sqrt(T)
    return float(S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2))


def bs_greeks(S: float, K: float, T: float, r: float, sigma: float) -> dict:
    """
    Black-Scholes Greeks for a European call option.

    Returns a dict with:
      value : option price
      delta : dV/dS — price sensitivity to underlying
      gamma : d²V/dS² — delta sensitivity to underlying
      vega  : dV/d(sigma) — price sensitivity to volatility

    Matches the sign convention of R's RQuantLib::EuropeanOption output.
    """
    if T <= 0 or sigma <= 0:
        intrinsic = max(S - K, 0.0)
        return {"value": intrinsic, "delta": 1.0 if S > K else 0.0, "gamma": 0.0, "vega": 0.0}

    d1 = _d1(S, K, T, r, sigma)
    d2 = d1 - sigma * np.sqrt(T)
    price  = S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2)
    delta  = norm.cdf(d1)
    gamma  = norm.pdf(d1) / (S * sigma * np.sqrt(T))
    vega   = S * norm.pdf(d1) * np.sqrt(T)        # per unit sigma (not per 1%)
    return {"value": float(price), "delta": float(delta), "gamma": float(gamma), "vega": float(vega)}


# ---------------------------------------------------------------------------
# Scenario analysis over price and vol range (6_1.r)
# ---------------------------------------------------------------------------

def option_scenario_sweep(
    S0: float,
    K: float,
    T: float,
    r: float,
    sigma0: float,
    price_range_cents: int = 200,
    vol_sensitivity: float = 0.0001,
) -> pl.DataFrame:
    """
    Compute option price and Greeks for S in [S0 - range, S0 + range] (1-cent steps),
    simultaneously adjusting implied vol inversely to the price change:
        sigma(i) = sigma0 - i * vol_sensitivity

    This models the vol-price inverse relationship (leverage effect) observed in practice.

    Returns a Polars DataFrame with columns:
      price_change_cents, S, sigma, value, delta, gamma, vega

    Mirrors R: 6_1.r inner loop
    """
    rows = []
    for i in range(-price_range_cents, price_range_cents + 1):
        S = S0 + i / 100
        sigma = max(sigma0 - i * vol_sensitivity, 1e-6)
        g = bs_greeks(S, K, T, r, sigma)
        rows.append({
            "price_change_cents": i,
            "S":     S,
            "sigma": sigma,
            "value": g["value"],
            "delta": g["delta"],
            "gamma": g["gamma"],
            "vega":  g["vega"],
        })

    return pl.DataFrame(rows)


def plot_greeks_comparison(
    df_now: pl.DataFrame,
    df_later: pl.DataFrame,
    title_suffix: str = "",
) -> plt.Figure:
    """
    Plot price, delta, gamma, and vega for two maturities side by side.

    df_now   : output of option_scenario_sweep at current maturity
    df_later : same sweep one year later (shorter maturity)

    Mirrors R: par(mfrow=c(2,2)) plots in 6_1.r
    """
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    x = df_now["price_change_cents"].to_numpy()
    metrics = ["value", "delta", "gamma", "vega"]
    labels  = ["Price", "Delta", "Gamma", "Vega"]

    for ax, metric, label in zip(axes.flatten(), metrics, labels):
        y_now   = df_now[metric].to_numpy()
        y_later = df_later[metric].to_numpy()
        y_min = min(y_now.min(), y_later.min())
        y_max = max(y_now.max(), y_later.max())
        ax.scatter(x, y_now,   s=4, color="black", label="Now")
        ax.plot(x, y_later, color="grey",  linewidth=1.5, label="1yr later")
        ax.set_ylim(y_min, y_max)
        ax.set_xlabel("Price change (cents)")
        ax.set_ylabel(label)
        ax.set_title(label + title_suffix)
        ax.legend(fontsize=8)

    fig.tight_layout()
    return fig
