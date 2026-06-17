"""
Chapter 5 — Portfolio Construction (R: 5_1–5_5b)

Correlation analysis, Nekrasov's formula, brute-force optimisation,
and portfolio simulation with TP/SL rules.
Pass --save to write plots to disk.
"""

import argparse

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("--save", action="store_true")
args = parser.parse_args()
if args.save:
    matplotlib.use("Agg")

from yetanotherquant.chapter5.portfolio import (
    correlation_matrix,
    estimate_sigma,
    implied_drift,
    nekrasov_optimal,
)
from yetanotherquant.chapter5.simulation import simulate_portfolio_tpsl
from yetanotherquant.data.loader import daily_returns, fetch_prices, to_numpy_returns

# --- 5_1: Correlation between bank and healthcare stocks ---
print("[5_1] Correlation: CBK.DE, DBK.DE, FRE.DE (2004–2014)...")
tickers_51 = {"CBK.DE": None, "DBK.DE": None, "FRE.DE": None}
for t in list(tickers_51):
    try:
        df = fetch_prices(t, start="2004-01-01", end="2014-04-30")
        tickers_51[t] = to_numpy_returns(daily_returns(df))
    except Exception as e:
        print(f"  Skipped {t}: {e}")
        tickers_51.pop(t)

if len(tickers_51) == 3:
    corr = correlation_matrix({k: v for k, v in tickers_51.items() if v is not None})
    print(corr)

# --- 5_2: Nekrasov formula vs brute-force ---
print("\n[5_2] Nekrasov formula for 2-asset portfolio...")
r_f = 0.02
mu_52 = np.array([0.09, 0.09])
s1, s2, rho = 0.16, 0.16, 0.5
cov_52 = np.array([[s1**2, rho * s1 * s2], [rho * s1 * s2, s2**2]])

# Generate large sample to estimate Sigma
rng = np.random.default_rng(42)
sample = rng.multivariate_normal(mu_52, cov_52, size=100_000)
Sigma = estimate_sigma(sample, r_f)
u = nekrasov_optimal(mu_52, Sigma, r_f)
print(f"  Nekrasov optimal fractions: f1={u[0]:.4f}  f2={u[1]:.4f}")
print("  (With rho=0.5, symmetric mu/sigma, expect equal fractions)")

# --- 5_2a: sensitivity to estimation error ---
print("\n[5_2a] Sensitivity of Nekrasov formula (3 trials with N=100 observations)...")
s1_a, s2_a, rho_a = 0.4, 0.3, 0.7
mu_52a = np.array([0.12, 0.09])
r_f_a = 0.01
cov_52a = np.array([[s1_a**2, rho_a * s1_a * s2_a], [rho_a * s1_a * s2_a, s2_a**2]])

# True optimum
true_sample = rng.multivariate_normal(mu_52a, cov_52a, size=100_000)
true_Sigma = estimate_sigma(true_sample, r_f_a)
u_true = nekrasov_optimal(mu_52a, true_Sigma, r_f_a)
print(f"  True optimal fractions: {u_true}")

for trial in range(1, 4):
    small_sample = rng.multivariate_normal(mu_52a, cov_52a, size=100)
    Sigma_est = estimate_sigma(small_sample, r_f_a)
    u_est = nekrasov_optimal(mu_52a, Sigma_est, r_f_a)
    print(f"  Trial {trial} (N=100):   {u_est}")

# --- 5_3: Correlation matrix for MEO, SZU, SLV ---
print("\n[5_3] Correlation matrix: MEO.DE, SZU.DE, SLV (2013-05 to 2014-05)...")
tickers_53 = {"MEO.DE": None, "SZU.DE": None, "SLV": None}
lens = {}
for t in list(tickers_53):
    try:
        df = fetch_prices(t, start="2013-05-01", end="2014-05-13")
        r = to_numpy_returns(daily_returns(df))
        tickers_53[t] = r
        lens[t] = len(r)
    except Exception as e:
        print(f"  Skipped {t}: {e}")

if tickers_53:
    n53 = min(lens.values())
    aligned = {t: r[:n53] for t, r in tickers_53.items() if r is not None}
    corr53 = correlation_matrix(aligned)
    print(corr53)

# --- 5_4: Implied drift for MEO.DE ---
print("\n[5_4] Implied drift for MEO.DE (buy=29.79, TP=35.40, SL=26.40, 50/50)...")
print("  (This takes ~30s with n_sim=50_000; use smaller n_sim for quick test)")
vola_meo = 0.01883767
res_54 = implied_drift(
    29.79, 35.40, 26.40, 0.5, 0.5, 141, vola_meo, n_steps=50, n_sim=20_000, seed=42
)
print(f"  Implied drift:      {res_54['implied_drift']:.6f}  (R: ~0.0007)")
print(f"  Empirical TP prob:  {res_54['empirical_tp_prob']:.4f}")
print(f"  Empirical SL prob:  {res_54['empirical_sl_prob']:.4f}")

# --- 5_5a: 2-asset portfolio simulation (MEO + SZU) ---
print("\n[5_5a] 2-asset portfolio: MEO + SZU (10% each, 80% cash)...")
if "MEO.DE" in tickers_53 and "SZU.DE" in tickers_53:
    meo_r = tickers_53["MEO.DE"][:n53]
    szu_r = tickers_53["SZU.DE"][:n53]
    vola_meo = float(np.std(meo_r))
    vola_szu = float(np.std(szu_r))
    rho_ms = float(np.corrcoef(meo_r, szu_r)[0, 1])
    cov_2 = np.array(
        [
            [vola_meo**2, vola_meo * vola_szu * rho_ms],
            [vola_meo * vola_szu * rho_ms, vola_szu**2],
        ]
    )
    drifts_2 = np.array([0.0007, 0.0003])

    wMEO = 0.1 * 29.35 / 29.79
    wSZU = 0.1 * 15.70 / 16.10
    tpMEO = 0.1 * 35.40 / 29.79
    slMEO = 0.1 * 26.40 / 29.79

    res_55a = simulate_portfolio_tpsl(
        drifts=drifts_2,
        cov_matrix=cov_2,
        start_weights=np.array([wMEO, wSZU]),
        cash_weight=0.8,
        tp_levels=np.array([tpMEO, np.inf]),
        sl_levels=np.array([slMEO, -np.inf]),
        n_days=121,
        n_sim=5_000,
        seed=42,
    )
    print(f"  Mean terminal wealth: {res_55a['mean_terminal_wealth']:.4f}")
    print(f"  Mean MDD:             {res_55a['mean_mdd']:.4f}")
else:
    print("  Skipped (data unavailable)")

if args.save:
    plt.savefig("5_placeholder.png", dpi=120)
    print("Saved placeholder.")
else:
    plt.show()
