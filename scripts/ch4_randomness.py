"""
Chapter 4 — Market Randomness (R: 4_1.r)

Wald-Wolfowitz runs test and ACF for DAX daily returns across multiple sub-periods.
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

from yetanotherquant.data.loader import fetch_prices, daily_returns, to_numpy_returns
from yetanotherquant.chapter4.randomness import runs_test_report, plot_acf_grid

print("Downloading DAX (1990-11-26 to 2014-04-26)...")
dax = fetch_prices("^GDAXI", start="1990-11-26", end="2014-04-26")
rets = to_numpy_returns(daily_returns(dax))
print(f"  {len(rets)} daily returns")

sub_ranges = {
    "whole sample": slice(None),
    "1st 1000":     slice(0, 1000),
    "3rd 1000":     slice(2000, 3000),
    "4th 1000":     slice(3000, 4000),
}

print("\nWald-Wolfowitz runs test results:")
report = runs_test_report(rets, sub_ranges)
print(report)

fig = plot_acf_grid(rets, sub_ranges, lags=20)
fig.suptitle("4_1 — DAX Daily Return ACF by Sub-Period", y=1.01)

if args.save:
    fig.savefig("4_1_acf_grid.png", dpi=120, bbox_inches="tight")
    print("Saved 4_1_acf_grid.png")
else:
    plt.show()
