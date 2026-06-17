"""
Chapter 4 — Market Randomness (R script: 4_1.r)

Tests DAX daily returns for serial randomness using:
  - Wald-Wolfowitz runs test (equivalent to R's lawstat::runs.test)
  - Autocorrelation function (ACF) plot
"""

import matplotlib.pyplot as plt
import numpy as np
import polars as pl
from statsmodels.graphics.tsaplots import plot_acf
from statsmodels.sandbox.stats.runs import runstest_1samp as sm_runs_test


def runs_test(returns: np.ndarray) -> dict:
    """
    Wald-Wolfowitz runs test on a return series.

    Converts returns to binary (1 if above median, 0 otherwise) then tests
    whether the number of "runs" is consistent with randomness.

    Returns dict with keys: statistic, p_value.
    Mirrors R: lawstat::runs.test(rets)
    """
    median = float(np.median(returns))
    binary = (returns > median).astype(int)
    # statsmodels runstest_1samp expects the raw binary sequence
    # cutoff='mean' uses the series mean as threshold; we pre-binarise instead
    z_stat, p_value = sm_runs_test(binary, cutoff=0.5)
    return {"statistic": float(z_stat), "p_value": float(p_value)}


def plot_acf_grid(
    returns: np.ndarray,
    sub_ranges: dict[str, slice],
    lags: int = 20,
) -> plt.Figure:
    """
    Plot ACF for the full return series and several sub-periods in a grid.

    sub_ranges: dict mapping title → slice, e.g.
        {'whole sample': slice(None), '1st 1000': slice(0, 1000), ...}

    Mirrors R: par(mfrow=c(2,2)); acf(rets, main=...)
    """
    n_panels = len(sub_ranges)
    n_cols = 2
    n_rows = (n_panels + 1) // n_cols
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(12, 4 * n_rows))
    axes = np.array(axes).flatten()

    for ax, (title, slc) in zip(axes, sub_ranges.items(), strict=False):
        segment = returns[slc]
        plot_acf(
            segment, lags=min(lags, len(segment) - 1), ax=ax, title=title, zero=False
        )

    for ax in axes[n_panels:]:
        ax.set_visible(False)

    fig.tight_layout()
    return fig


def runs_test_report(returns: np.ndarray, sub_ranges: dict[str, slice]) -> pl.DataFrame:
    """
    Run the Wald-Wolfowitz test on the full series and multiple sub-periods.

    Returns a Polars DataFrame with columns: period, statistic, p_value.
    """
    rows = []
    for label, slc in sub_ranges.items():
        segment = returns[slc]
        res = runs_test(segment)
        rows.append(
            {"period": label, "statistic": res["statistic"], "p_value": res["p_value"]}
        )

    return pl.DataFrame(rows)
