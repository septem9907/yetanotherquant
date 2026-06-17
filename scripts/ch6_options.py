"""
Chapter 6 — Options Pricing and Greeks (R: 6_1.r)

European call option on a deeply OTM warrant (SG32QT), sweeping ±2 EUR
while simultaneously adjusting implied vol (leverage effect).
Pass --save to write plots to disk.
"""

import argparse

import matplotlib
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--save", action="store_true")
args = parser.parse_args()
if args.save:
    matplotlib.use("Agg")

from yetanotherquant.chapter6.options import (
    bs_greeks,
    option_scenario_sweep,
    plot_greeks_comparison,
)

# Option parameters matching R's 6_1.r
S0 = 23.81  # current underlying price (EUR)
K = 60.0  # strike price
r = 0.0057  # risk-free rate
sigma0 = 0.37  # implied volatility

print(f"European call: S={S0}, K={K}, r={r}, sigma={sigma0}")
g_now = bs_greeks(S0, K, T=4, r=r, sigma=sigma0)
print(f"\nAt-the-point Greeks (T=4yr, S={S0}, sigma={sigma0}):")
for key, val in g_now.items():
    print(f"  {key:8s}: {val:.6f}")

print("\nOne year later Greeks (T=3yr):")
g_later = bs_greeks(S0, K, T=3, r=r, sigma=sigma0)
for key, val in g_later.items():
    print(f"  {key:8s}: {val:.6f}")

# Sweep ±200 cents with vol adjustment
print("\nRunning scenario sweep (±2 EUR, vol adjusted)...")
df_now = option_scenario_sweep(S0, K, T=4, r=r, sigma0=sigma0)
df_later = option_scenario_sweep(S0, K, T=3, r=r, sigma0=sigma0)

print(
    f"  At S0 (i=0), T=4: price={df_now.filter(df_now['price_change_cents']==0)['value'][0]:.6f}"
)
print(
    f"  At S0 (i=0), T=3: price={df_later.filter(df_later['price_change_cents']==0)['value'][0]:.6f}"
)

fig = plot_greeks_comparison(df_now, df_later, title_suffix=" (SG32QT)")
fig.suptitle("6_1 — European Call Greeks: T=4yr (dots) vs T=3yr (line)", y=1.01)

if args.save:
    fig.savefig("6_1_option_greeks.png", dpi=120, bbox_inches="tight")
    print("Saved 6_1_option_greeks.png")
else:
    plt.show()
