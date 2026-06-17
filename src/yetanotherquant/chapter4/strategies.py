"""
Chapter 4 — Technical Analysis Strategies (R scripts: 4_2.r, 4_2a_dj30.r, 4_3.r, 4_4.r, 4_5.r)

Functions for:
  - Simple MA strategy (price vs MA)
  - Dual MA crossover strategy (short MA vs long MA)
  - Monthly seasonality analysis
  - Binomial trading system simulation
"""

import numpy as np
import polars as pl
import pandas as pd
import matplotlib.pyplot as plt
from yetanotherquant.chapter3.returns import max_drawdown


# ---------------------------------------------------------------------------
# Moving Average strategies
# ---------------------------------------------------------------------------

def simple_ma_strategy(prices: np.ndarray, ma_days: int = 200) -> dict:
    """
    Trend-following rule: buy when price > MA, sell when price < MA.

    Returns a dict with:
      ma_wealth   — final wealth of the MA strategy
      bh_wealth   — final wealth of buy-and-hold from day ma_days onward
      n_trades    — number of round-trip trades

    Mirrors R: 4_2.r and 4_2a_dj30.r
    """
    n = len(prices)
    if n <= ma_days:
        raise ValueError(f"Need more than {ma_days} prices, got {n}")

    # Simple moving average (same as R's SMA)
    ma = pd.Series(prices).rolling(ma_days).mean().to_numpy()

    signal = "inCash"
    buy_price = 0.0
    ma_wealth = 1.0
    n_trades = 0

    for d in range(ma_days, n):
        if prices[d] > ma[d] and signal == "inCash":
            buy_price = prices[d]
            signal = "inStock"
        elif (prices[d] < ma[d] or d == n - 1) and signal == "inStock":
            ma_wealth *= prices[d] / buy_price
            signal = "inCash"
            n_trades += 1

    bh_wealth = prices[-1] / prices[ma_days]
    return {"ma_wealth": ma_wealth, "bh_wealth": bh_wealth, "n_trades": n_trades}


def dual_ma_crossover(prices: np.ndarray, short_days: int = 38, long_days: int = 200) -> dict:
    """
    Golden-cross / death-cross rule: buy when MA_short > MA_long, sell otherwise.

    Mirrors R: 4_3.r
    """
    n = len(prices)
    ma_short = pd.Series(prices).rolling(short_days).mean().to_numpy()
    ma_long  = pd.Series(prices).rolling(long_days).mean().to_numpy()

    signal = "inCash"
    buy_price = 0.0
    ma_wealth = 1.0
    n_trades = 0

    for d in range(long_days, n):
        if ma_short[d] > ma_long[d] and signal == "inCash":
            buy_price = prices[d]
            signal = "inStock"
        elif (ma_short[d] < ma_long[d] or d == n - 1) and signal == "inStock":
            ma_wealth *= prices[d] / buy_price
            signal = "inCash"
            n_trades += 1

    bh_wealth = prices[-1] / prices[long_days]
    return {"ma_wealth": ma_wealth, "bh_wealth": bh_wealth, "n_trades": n_trades}


def backtest_universe(
    tickers: list[str],
    price_data: dict[str, np.ndarray],
    strategy_fn,
    **strategy_kwargs,
) -> pl.DataFrame:
    """
    Run a strategy function over multiple tickers and collect results.

    price_data: dict mapping ticker → numpy price array
    strategy_fn: simple_ma_strategy or dual_ma_crossover

    Returns a Polars DataFrame with columns: ticker, ma_wealth, bh_wealth, wealth_diff.
    """
    rows = []
    for ticker in tickers:
        if ticker not in price_data:
            continue
        try:
            res = strategy_fn(price_data[ticker], **strategy_kwargs)
            rows.append({
                "ticker":       ticker,
                "ma_wealth":    res["ma_wealth"],
                "bh_wealth":    res["bh_wealth"],
                "wealth_diff":  res["bh_wealth"] - res["ma_wealth"],
            })
        except Exception as e:
            rows.append({"ticker": ticker, "ma_wealth": None, "bh_wealth": None, "wealth_diff": None})

    return pl.DataFrame(rows)


# ---------------------------------------------------------------------------
# Seasonality (4_4.r)
# ---------------------------------------------------------------------------

def monthly_seasonality(monthly_returns: pl.DataFrame, return_col: str = "return") -> pl.DataFrame:
    """
    Compute average return by calendar month.

    monthly_returns: Polars DataFrame with a 'period' (Date) column and a return column.
    Returns a Polars DataFrame with columns: month_name, mean_return, median_return.

    Mirrors R: 4_4.r
    """
    month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    df = monthly_returns.with_columns(
        pl.col("period").dt.month().alias("month_num")
    )
    stats = (
        df.group_by("month_num")
        .agg([
            pl.col(return_col).mean().alias("mean_return"),
            pl.col(return_col).median().alias("median_return"),
            pl.col(return_col).std().alias("std_return"),
        ])
        .sort("month_num")
        .with_columns(
            pl.col("month_num").map_elements(
                lambda m: month_labels[m - 1], return_dtype=pl.Utf8
            ).alias("month_name")
        )
    )
    return stats


def plot_seasonality_boxplot(monthly_returns: pl.DataFrame, return_col: str = "return") -> plt.Figure:
    """
    Box plot of returns grouped by calendar month.

    Mirrors R: 4_4.r — boxplot(Return~Month, data=tmp)
    """
    month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    df = (
        monthly_returns
        .with_columns(pl.col("period").dt.month().alias("month_num"))
        .sort("month_num")
    )

    groups = [
        df.filter(pl.col("month_num") == m)[return_col].drop_nulls().to_numpy()
        for m in range(1, 13)
    ]

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.boxplot(groups, labels=month_labels)
    ax.axhline(0, color="grey", linewidth=1)
    ax.set_ylabel("Monthly Return")
    ax.set_title("DAX Monthly Return Seasonality")
    return fig


# ---------------------------------------------------------------------------
# Binomial trading system simulation (4_5.r)
# ---------------------------------------------------------------------------

def simulate_trading_system(
    n_trades: int = 395,
    win_prob: float = 0.64,
    ret_per_trade: float = 0.003,
    n_sim: int = 1_000,
    seed: int | None = None,
) -> dict:
    """
    Simulate a rule-based trading system with a fixed win rate and return per trade.

    Each trade either wins (+ret_per_trade) or loses (-ret_per_trade).
    Reports distributions of terminal wealth and max drawdown.

    Mirrors R: 4_5.r
    """
    rng = np.random.default_rng(seed)
    outcomes = rng.binomial(1, win_prob, size=(n_sim, n_trades))  # 1=win, 0=loss

    term_wealth = np.empty(n_sim)
    mdd_values  = np.empty(n_sim)

    for i in range(n_sim):
        rets = np.where(outcomes[i] == 1, ret_per_trade, -ret_per_trade)
        wealth = np.cumprod(1 + rets)
        wealth_full = np.insert(wealth, 0, 1.0)
        term_wealth[i] = wealth[-1]
        mdd_values[i]  = max_drawdown(wealth_full)

    return {
        "terminal_wealth": term_wealth,
        "max_drawdown":    mdd_values,
        "mean_terminal_wealth": float(np.mean(term_wealth)),
        "mean_mdd":             float(np.mean(mdd_values)),
    }
