"""
Data loading utilities.

Downloads historical price data from Yahoo Finance (via yfinance) and returns
it as a Polars DataFrame. Pandas is used as the intermediate format since
yfinance returns pandas DataFrames natively.
"""

import numpy as np
import pandas as pd
import polars as pl
import yfinance as yf


def fetch_prices(
    ticker: str, start: str = "1990-01-01", end: str | None = None
) -> pl.DataFrame:
    """
    Download daily OHLCV data from Yahoo Finance.

    Returns a Polars DataFrame with columns: date, open, high, low, close, volume.
    """
    raw: pd.DataFrame = yf.download(
        ticker, start=start, end=end, auto_adjust=True, progress=False
    )
    if raw.empty:
        raise ValueError(f"No data returned for ticker {ticker!r}")

    # yfinance may return a MultiIndex if only one ticker — flatten it
    if isinstance(raw.columns, pd.MultiIndex):
        raw.columns = raw.columns.droplevel(1)

    raw = raw.reset_index()
    raw.columns = [c.lower().replace(" ", "_") for c in raw.columns]

    df = pl.from_pandas(raw[["date", "open", "high", "low", "close", "volume"]])
    return df.with_columns(pl.col("date").cast(pl.Date))


def daily_returns(df: pl.DataFrame, price_col: str = "close") -> pl.Series:
    """
    Compute simple (arithmetic) daily returns: r_t = (P_t - P_{t-1}) / P_{t-1}.

    First element is null (no previous price).
    Mirrors R's ROC(prices, type='discrete').
    """
    prices = df[price_col]
    return (prices / prices.shift(1) - 1).rename("return")


def period_returns(
    df: pl.DataFrame, period: str = "monthly", price_col: str = "close"
) -> pl.DataFrame:
    """
    Aggregate to monthly or weekly returns using close prices.

    period: 'monthly' | 'weekly'
    Returns a Polars DataFrame with columns: period_end, return.
    Mirrors R's periodReturn(data, period='monthly').
    """
    df = df.with_columns(
        pl.col("date")
        .dt.truncate("1mo" if period == "monthly" else "1w")
        .alias("period")
    )

    # Take last close price of each period
    period_closes = (
        df.group_by("period")
        .agg(pl.col(price_col).last().alias("close_last"))
        .sort("period")
    )

    close_arr = period_closes["close_last"].to_numpy()
    ret_arr = np.empty(len(close_arr))
    ret_arr[0] = 0.0  # no previous period
    ret_arr[1:] = close_arr[1:] / close_arr[:-1] - 1

    return period_closes.with_columns(pl.Series("return", ret_arr))


def to_numpy_returns(series: pl.Series) -> np.ndarray:
    """Drop nulls and convert a Polars return Series to a numpy float array."""
    return series.drop_nulls().to_numpy().astype(float)
