"""
Chapter 2 — Central Limit Theorem (R: forFig2_1.r, forFig2_2.r)

Demonstrates CLT convergence: binomial coin-toss sums approach a normal distribution.
Pass --save to write plots to disk instead of displaying interactively.
"""

import argparse
import matplotlib
import matplotlib.pyplot as plt
from yetanotherquant.chapter2.clt import (
    simulate_coin_tosses,
    plot_histogram_with_normal,
    plot_density_comparison,
)

parser = argparse.ArgumentParser()
parser.add_argument("--save", action="store_true", help="Save plots to disk")
args = parser.parse_args()

if args.save:
    matplotlib.use("Agg")

# Fig 2_1: N_SIM=1000, histogram
tosses_large = simulate_coin_tosses(n_tosses=10, n_sim=1_000, p=0.55, seed=42)
fig1 = plot_histogram_with_normal(tosses_large, title="Fig 2.1 — Histogram (N=1000)")
print(f"[Fig 2.1] mean={tosses_large.mean():.2f}  std={tosses_large.std():.2f}")

# Fig 2_2: N_SIM=200, density overlay
tosses_small = simulate_coin_tosses(n_tosses=10, n_sim=200, p=0.55, seed=42)
fig2 = plot_density_comparison(tosses_small, title="Fig 2.2 — Density (N=200)")
print(f"[Fig 2.2] mean={tosses_small.mean():.2f}  std={tosses_small.std():.2f}")

if args.save:
    fig1.savefig("fig2_1_histogram.png", dpi=120, bbox_inches="tight")
    fig2.savefig("fig2_2_density.png",   dpi=120, bbox_inches="tight")
    print("Saved fig2_1_histogram.png and fig2_2_density.png")
else:
    plt.show()
