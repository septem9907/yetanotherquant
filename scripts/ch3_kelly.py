"""
Chapter 3 — Kelly Criterion (R: 3_3a – 3_3c, 3_6a – 3_6b, forFig3_2, forFig3_3)

Analytical and simulated Kelly fractions for coin-toss games and DAX monthly returns.
Pass --save to write plots to disk.
"""

import argparse
import numpy as np
import matplotlib
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--save", action="store_true")
args = parser.parse_args()
if args.save:
    matplotlib.use("Agg")

from yetanotherquant.data.loader import fetch_prices, period_returns, to_numpy_returns
from yetanotherquant.chapter3.kelly import (
    analytical_kelly_coin, expected_growth_rate, plot_growth_rate_curve,
    kelly_simulation, optimal_kelly_fraction,
    kelly_sensitivity, backtest_kelly_fractions,
    simulate_betting_strategies, drawdown_risk_at_fraction,
)

# --- forFig3_2: analytical Kelly for coin-toss game ---
P_WIN, WIN_MULT, LOSS_MULT = 0.5, 1.7, 0.7
f_star = analytical_kelly_coin(P_WIN, WIN_MULT, LOSS_MULT)
fracs = np.arange(1, 101) / 100
rates = expected_growth_rate(fracs, P_WIN, WIN_MULT, LOSS_MULT)
print(f"[forFig3_2] Analytical Kelly fraction: {f_star:.4f}  (R: 0.4202)")
print(f"            Expected growth at f*:     {np.interp(f_star, fracs, rates):.6f}")
print(f"            Expected growth at 100%:   {rates[-1]:.6f}")
fig1 = plot_growth_rate_curve(P_WIN, WIN_MULT, LOSS_MULT)

# --- forFig3_3: betting strategy comparison ---
strategies = simulate_betting_strategies(n_trades=30, seed=42)
fig2, ax2 = plt.subplots()
ax2.plot(strategies["full"],       linewidth=1, label="Full bet (100%)", color="black")
ax2.plot(strategies["kelly"],      linewidth=2, label=f"Kelly ({f_star:.0%})", color="darkblue")
ax2.plot(strategies["half_kelly"], linewidth=2, label=f"Half-Kelly ({f_star/2:.0%})", color="grey", linestyle="--")
ax2.set_title("forFig3_3 — Betting Strategies")
ax2.legend()

# --- 3_3a: numerical Kelly for DAX monthly returns ---
print("\nDownloading DAX for Kelly estimation...")
dax = fetch_prices("^GDAXI", start="1990-01-01")
monthly = period_returns(dax, period="monthly")
m_rets = to_numpy_returns(monthly["return"])
mu_m  = float(np.mean(m_rets))
sigma_m = float(np.std(m_rets))
r_monthly = 0.03 / 12

print(f"  DAX monthly: mu={mu_m:.6f}  sigma={sigma_m:.6f}  n={len(m_rets)}")
print("  Running Kelly simulation (n_steps=100, n_sim=5000)...")
mlw = kelly_simulation(mu_m, sigma_m, r_monthly, n_steps=100, n_sim=5_000, n_periods=120, seed=42)
opt_frac = optimal_kelly_fraction(mlw)
print(f"  Optimal Kelly fraction: {opt_frac:.2f}  (R reports ~0.93)")

# --- 3_3b: backtest at fixed fractions ---
print("\n[3_3b] Backtesting allocations on historical DAX monthly returns...")
fracs_to_test = [0.30, 0.50, 0.93, 1.00]
wealth_paths = backtest_kelly_fractions(m_rets, r_monthly, fracs_to_test)
fig3, ax3 = plt.subplots()
for label, w in wealth_paths.items():
    ax3.plot(w, label=label)
ax3.set_title("3_3b — Historical Wealth at Different Kelly Fractions")
ax3.legend()

# --- 3_3c: Kelly sensitivity to parameter estimation error ---
print("\n[3_3c] Kelly sensitivity (3 iterations)...")
sensitivity = kelly_sensitivity(m_rets, r_monthly, n_iterations=3,
                                n_steps=100, n_sim=2_000, n_months=120, seed=42)
for row in sensitivity:
    print(f"  Iter {row['iteration']}: mu_est={row['mu_est']:.4f}  "
          f"sigma_est={row['sigma_est']:.4f}  optimal_frac={row['optimal_frac']:.2f}")

# --- 3_6a + 3_6b: Kelly for two hypothetical stocks ---
print("\n[3_6a] Finding Kelly fractions for two stocks...")
configs = [
    {"mu": 0.0003, "sigma": 0.02, "label": "Stock A (low drift/vol)"},
    {"mu": 0.0006, "sigma": 0.04, "label": "Stock B (high drift/vol)"},
]
r_daily = 0.01 / 242
for cfg in configs:
    mlw_d = kelly_simulation(cfg["mu"], cfg["sigma"], r_daily,
                             n_steps=100, n_sim=5_000, n_periods=242, seed=42)
    frac_d = optimal_kelly_fraction(mlw_d)
    print(f"  {cfg['label']}: Kelly fraction = {frac_d:.2f}")

print("\n[3_6b] Drawdown risk at specified Kelly fractions...")
for mu_k, sigma_k, kf, label in [(0.0003, 0.02, 0.76, "A"), (0.0006, 0.04, 0.65, "B")]:
    res = drawdown_risk_at_fraction(mu_k, sigma_k, kf, r_daily, seed=42)
    print(f"  Stock {label} (f={kf}): P(MDD<-5%)={res['prob_mdd_lt_5pct']:.3f}  "
          f"P(MDD<-20%)={res['prob_mdd_lt_20pct']:.3f}  "
          f"E[log W]={res['mean_terminal_log_wealth']:.4f}")

if args.save:
    fig1.savefig("forFig3_2_kelly_curve.png",       dpi=120, bbox_inches="tight")
    fig2.savefig("forFig3_3_strategy_comparison.png", dpi=120, bbox_inches="tight")
    fig3.savefig("3_3b_backtest.png",                dpi=120, bbox_inches="tight")
    print("Saved plots.")
else:
    plt.show()
