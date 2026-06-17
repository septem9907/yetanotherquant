"""
Chapter 3 — Return Distributions (R: 3_1.r through 3_5.r, 3_7.r)

Downloads DAX data, analyses daily and monthly return distributions,
compares normal vs binomial models, and estimates historical volatility.
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

from yetanotherquant.data.loader import fetch_prices, daily_returns, period_returns, to_numpy_returns
from yetanotherquant.chapter3.returns import (
    fit_normal, plot_density_vs_normal, plot_qq_normal,
    filter_outliers, simulate_wealth_paths,
    simulate_terminal_wealth_and_mdd, rolling_volatility,
    compare_normal_binomial_models,
)

print("Downloading DAX (^GDAXI)...")
dax = fetch_prices("^GDAXI", start="1990-01-01")
print(f"  {len(dax)} daily observations from {dax['date'][0]} to {dax['date'][-1]}")

# --- Daily returns (3_2a) ---
ret_series = daily_returns(dax)
rets = to_numpy_returns(ret_series)
mu, sigma = fit_normal(rets)
print(f"\nDaily returns: mu={mu:.6f}  sigma={sigma:.6f}  n={len(rets)}")

fig1 = plot_density_vs_normal(rets, title="3_2a — DAX Daily Returns vs Normal")
fig2 = plot_qq_normal(rets, title="3_2a — QQ-Plot (daily returns)")

# --- Outlier removal (3_2b) ---
capped = filter_outliers(rets, n_sigma=3)
fraction_kept = len(capped) / len(rets)
print(f"\n[3_2b] After 3-sigma cap: {len(capped):,} / {len(rets):,} = {fraction_kept:.4f} kept")
fig3 = plot_qq_normal(capped, title="3_2b — QQ-Plot (3-sigma capped returns)")

# --- Monthly returns (3_2c) ---
monthly = period_returns(dax, period="monthly")
m_rets = to_numpy_returns(monthly["return"])
mu_m, sigma_m = fit_normal(m_rets)
print(f"\nMonthly returns: mu={mu_m:.6f}  sigma={sigma_m:.6f}  n={len(m_rets)}")
fig4 = plot_density_vs_normal(m_rets, title="3_2c — Monthly Returns vs Normal")

# --- Monte Carlo wealth paths (3_2d) ---
mu_hc, sigma_hc = 0.0085, 0.0605   # hardcoded DAX monthly params as in R
paths = simulate_wealth_paths(mu_hc, sigma_hc, n_sim=10_000, n_months=120, seed=42)
print(f"\n[3_2d] Terminal wealth: mean={paths[:,-1].mean():.4f}  std={paths[:,-1].std():.4f}")

fig5, ax5 = plt.subplots()
ax5.plot(paths[0],    color="black", linewidth=1.5)
ax5.plot(paths[999],  color="grey",  linewidth=1.5)
ax5.plot(paths[4999], color="brown", linewidth=1.5)
ax5.set_title("3_2d — Monte Carlo Wealth Paths (sample)")
ax5.set_xlabel("Month")

# --- Normal vs binomial model comparison (3_4 / 3_5) ---
print("\n[3_4] Comparing normal vs binomial return models...")
models = compare_normal_binomial_models(m_rets, seed=42)

fig6, ax6 = plt.subplots()
n = len(models["empirical"])
ax6.plot(models["empirical"], color="black", linewidth=1.5, label="Empirical DAX")
ax6.plot(models["normal"],    color="grey",  linewidth=1.5, label="Normal sim")
ax6.plot(models["binomial"],  color="blue",  linewidth=1.5, label="Binomial sim")
ax6.legend()
ax6.set_title("3_4 — Wealth Paths: Empirical vs Normal vs Binomial")

print("[3_5] Simulating terminal wealth and MDD distributions (1000 paths)...")
mdd_results = simulate_terminal_wealth_and_mdd(m_rets, n_sim=1_000, seed=42)
print(f"  Normal  — mean terminal wealth: {mdd_results['terminal_wealth_normal'].mean():.4f}"
      f"  mean MDD: {mdd_results['mdd_normal'].mean():.4f}")
print(f"  Binomial— mean terminal wealth: {mdd_results['terminal_wealth_binomial'].mean():.4f}"
      f"  mean MDD: {mdd_results['mdd_binomial'].mean():.4f}")

# --- Rolling volatility for Metro AG (3_7) ---
print("\n[3_7] Downloading Metro AG (MEO.DE)...")
try:
    meo = fetch_prices("MEO.DE")
    meo_rets = to_numpy_returns(daily_returns(meo))
    n = len(meo_rets)
    windows = {"all": n, "1yr": 242, "6mo": 121, "1q": 63, "1mo": 21}
    vols = rolling_volatility(meo_rets, windows)
    print("  Volatility estimates:", {k: f"{v:.4f}" for k, v in vols.items()})
except Exception as e:
    print(f"  MEO.DE download skipped: {e}")

figs = [fig1, fig2, fig3, fig4, fig5, fig6]
names = ["3_2a_density", "3_2a_qq", "3_2b_qq_capped", "3_2c_monthly", "3_2d_paths", "3_4_model_comparison"]

if args.save:
    for fig, name in zip(figs, names):
        fig.savefig(f"{name}.png", dpi=120, bbox_inches="tight")
        print(f"Saved {name}.png")
else:
    plt.show()
