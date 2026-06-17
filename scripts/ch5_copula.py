"""
Chapter 5 — Copula Simulation (R: 5_6a.r, 5_6b.r, 5_7.r)

Gaussian copula for correlated binary trades, sequential portfolio simulation,
and Clayton copula comparison.
Pass --save to write plots to disk.
"""

import argparse

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import gaussian_kde

parser = argparse.ArgumentParser()
parser.add_argument("--save", action="store_true")
args = parser.parse_args()
if args.save:
    matplotlib.use("Agg")

from yetanotherquant.chapter5.copula import (
    clayton_copula_normal_margins,
    gaussian_copula_binary,
    gaussian_copula_normal_margins,
    portfolio_returns_from_copula,
    sequential_trading_simulation,
)

# --- 5_6a: Gaussian copula with 10 binary assets ---
print("[5_6a] Gaussian copula binary simulation (N=100,000, corr=0.31)...")
RET_UP = (22.00 - 19.40) / 19.40  # +13.4%
RET_DN = (18.40 - 19.40) / 19.40  # -5.15%
N_ASSETS = 10
CORR = 0.31

asset_rets = gaussian_copula_binary(
    corr=CORR,
    n_assets=N_ASSETS,
    ret_up=RET_UP,
    ret_dn=RET_DN,
    p_up=0.5,
    n_sim=100_000,
    seed=42,
)
port_rets = portfolio_returns_from_copula(asset_rets)

# Verify correlation structure
actual_corr = np.corrcoef(asset_rets.T)
off_diag = actual_corr[np.triu_indices(N_ASSETS, k=1)]
print(f"  Target corr={CORR:.2f}  Actual mean off-diagonal corr={off_diag.mean():.3f}")
print(f"  Portfolio return: mean={port_rets.mean():.4f}  std={port_rets.std():.4f}")

fig1, ax1 = plt.subplots()
x = np.linspace(port_rets.min(), port_rets.max(), 400)
ax1.plot(x, gaussian_kde(port_rets)(x), color="black", linewidth=2)
ax1.set_title("5_6a — Portfolio Return Density (Gaussian Copula Binary)")
ax1.set_xlabel("Portfolio Return")

# --- 5_6b: Sequential trading simulation ---
print("\n[5_6b] Sequential trading simulation (50 trades per block)...")
sim_56b = sequential_trading_simulation(port_rets, n_trades_per_block=50)
print(f"  Mean log-growth rate: {sim_56b['mean_log_growth_rate']:.4f}")
print(f"  Std  log-growth rate: {sim_56b['std_log_growth_rate']:.4f}")
print(f"  Mean max drawdown:    {sim_56b['mean_mdd']:.4f}")

fig2, axes = plt.subplots(1, 2, figsize=(10, 4))
lgr = np.log(sim_56b["terminal_wealth"])
axes[0].plot(
    np.linspace(lgr.min(), lgr.max(), 300),
    gaussian_kde(lgr)(np.linspace(lgr.min(), lgr.max(), 300)),
    color="black",
    linewidth=2,
)
axes[0].set_title("5_6b — Log-Growth Rate Density")
mdd = sim_56b["max_drawdown"]
axes[1].plot(
    np.linspace(mdd.min(), mdd.max(), 300),
    gaussian_kde(mdd)(np.linspace(mdd.min(), mdd.max(), 300)),
    color="black",
    linewidth=2,
)
axes[1].set_title("5_6b — Max Drawdown Density")
fig2.tight_layout()

# --- 5_7: Clayton vs Gaussian copula ---
print("\n[5_7] Clayton copula vs Gaussian copula (N=10,000)...")
mean_57 = np.array([0.08, 0.10])
sigma_57 = np.array([np.sqrt(0.09), np.sqrt(0.16)])
rho_57 = 0.69

norm_rets = gaussian_copula_normal_margins(mean_57, sigma_57, rho_57, 10_000, seed=42)
clayton_rets = clayton_copula_normal_margins(
    mean_57, sigma_57, theta=2.0, n_sim=10_000, seed=42
)

print(f"  Gaussian:  cov matrix diag ~ {np.cov(norm_rets.T).diagonal()}")
print(f"  Clayton:   cov matrix diag ~ {np.cov(clayton_rets.T).diagonal()}")
print(f"  Gaussian corr: {np.corrcoef(norm_rets.T)[0,1]:.3f}  (target {rho_57})")
print(f"  Clayton  corr: {np.corrcoef(clayton_rets.T)[0,1]:.3f}")

fig3, axes3 = plt.subplots(1, 2, figsize=(10, 5))
axes3[0].scatter(norm_rets[:, 0], norm_rets[:, 1], s=2, alpha=0.3)
axes3[0].set_title("5_7 — Gaussian Copula")
axes3[1].scatter(clayton_rets[:, 0], clayton_rets[:, 1], s=2, alpha=0.3)
axes3[1].set_title("5_7 — Clayton Copula (lower-tail clustering)")
fig3.tight_layout()

if args.save:
    fig1.savefig("5_6a_copula_density.png", dpi=120, bbox_inches="tight")
    fig2.savefig("5_6b_sequential_trading.png", dpi=120, bbox_inches="tight")
    fig3.savefig("5_7_copula_comparison.png", dpi=120, bbox_inches="tight")
    print("Saved plots.")
else:
    plt.show()
