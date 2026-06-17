"""
Chapter 4 — Moving Average Strategies (R: 4_2.r, 4_2a_dj30.r, 4_3.r, 4_4.r, 4_5.r)

Backtests MA200 trend-following on DAX and DOW30 stocks,
tests dual MA crossover, analyses monthly seasonality,
and simulates a binomial trading system.
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
from yetanotherquant.chapter4.strategies import (
    simple_ma_strategy, dual_ma_crossover, backtest_universe,
    monthly_seasonality, plot_seasonality_boxplot, simulate_trading_system,
)

# --- 4_2: MA200 on a subset of DAX stocks ---
DAX_TICKERS = ["ADS.DE", "ALV.DE", "SAP.DE", "SIE.DE", "BMW.DE"]  # sample of 5 for speed
print(f"[4_2] Downloading {len(DAX_TICKERS)} DAX stocks (1995–2014)...")
dax_prices = {}
for ticker in DAX_TICKERS:
    try:
        df = fetch_prices(ticker, start="1995-01-01", end="2014-04-30")
        dax_prices[ticker] = df["close"].to_numpy().astype(float)
    except Exception as e:
        print(f"  Skipped {ticker}: {e}")

dax_results = backtest_universe(DAX_TICKERS, dax_prices, simple_ma_strategy, ma_days=200)
print("\nDAX MA200 results (positive wealth_diff = buy-and-hold beat MA):")
print(dax_results)
print(f"  Mean wealth diff: {dax_results['wealth_diff'].mean():.4f}")

# --- 4_2a: MA200 on a subset of US DOW30 stocks ---
DOW_TICKERS = ["GE", "IBM", "MSFT", "JNJ", "KO"]  # sample of 5
print(f"\n[4_2a] Downloading {len(DOW_TICKERS)} DOW30 stocks (1995–2014)...")
dow_prices = {}
for ticker in DOW_TICKERS:
    try:
        df = fetch_prices(ticker, start="1995-01-01", end="2014-04-30")
        dow_prices[ticker] = df["close"].to_numpy().astype(float)
    except Exception as e:
        print(f"  Skipped {ticker}: {e}")

dow_results = backtest_universe(DOW_TICKERS, dow_prices, simple_ma_strategy, ma_days=200)
print("\nDOW30 MA200 results:")
print(dow_results)

# --- 4_3: Dual MA crossover (MA38/MA200) on a few DAX stocks ---
print("\n[4_3] Dual MA crossover (MA38/MA200) on DAX sample...")
dual_results = backtest_universe(DAX_TICKERS, dax_prices, dual_ma_crossover,
                                 short_days=38, long_days=200)
print(dual_results)

# --- 4_4: Monthly seasonality ---
print("\n[4_4] DAX monthly seasonality (1990–2014)...")
dax_full = fetch_prices("^GDAXI", start="1990-01-01", end="2014-04-30")
monthly = period_returns(dax_full, period="monthly")
season = monthly_seasonality(monthly)
print(season)
fig_season = plot_seasonality_boxplot(monthly)
fig_season.suptitle("4_4 — DAX Monthly Return Seasonality")

# --- 4_5: Binomial trading system ---
print("\n[4_5] Simulating trading system (64% win rate, ±0.3%, 395 trades, 1000 runs)...")
ts = simulate_trading_system(n_trades=395, win_prob=0.64, ret_per_trade=0.003, n_sim=1_000, seed=42)
print(f"  Mean terminal wealth: {ts['mean_terminal_wealth']:.4f}")
print(f"  Mean max drawdown:    {ts['mean_mdd']:.4f}")

fig_ts, axes = plt.subplots(1, 2, figsize=(10, 4))
axes[0].hist(ts["terminal_wealth"], bins=50, color="grey", edgecolor="white")
axes[0].set_title("4_5 — Terminal Wealth Distribution")
axes[1].hist(ts["max_drawdown"],    bins=50, color="grey", edgecolor="white")
axes[1].set_title("4_5 — Max Drawdown Distribution")
fig_ts.tight_layout()

if args.save:
    fig_season.savefig("4_4_seasonality.png",   dpi=120, bbox_inches="tight")
    fig_ts.savefig("4_5_trading_system.png",    dpi=120, bbox_inches="tight")
    print("Saved plots.")
else:
    plt.show()
