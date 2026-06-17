"""
Chapter 2 — Central Limit Theorem (R scripts: forFig2_1.r, forFig2_2.r)

Demonstrates that the sum of many independent Bernoulli trials approaches
a normal distribution (CLT). Uses a slightly biased coin (p=0.55).
"""

import numpy as np
from scipy.stats import norm
import matplotlib.pyplot as plt


def simulate_coin_tosses(
    n_tosses: int = 10,
    n_sim: int = 1_000,
    p: float = 0.55,
    seed: int | None = None,
) -> np.ndarray:
    """
    Simulate n_sim experiments of n_tosses coin flips.

    Returns an array of head counts, shape (n_sim,).
    """
    rng = np.random.default_rng(seed)
    return rng.binomial(n_tosses, p, size=n_sim).astype(float)


def plot_histogram_with_normal(
    tosses: np.ndarray,
    title: str = "Histogram with Normal Curve",
) -> plt.Figure:
    """
    Histogram of coin-toss head counts overlaid with a fitted normal curve.

    Mirrors R: forFig2_1.r
    """
    fig, ax = plt.subplots()
    counts, bin_edges, _ = ax.hist(tosses, bins=10, color="grey", edgecolor="white", label="Observed")
    bin_width = bin_edges[1] - bin_edges[0]

    mu, sigma = float(np.mean(tosses)), float(np.std(tosses))
    x = np.linspace(tosses.min(), tosses.max(), 400)
    # Scale normal PDF to histogram counts
    y = norm.pdf(x, mu, sigma) * bin_width * len(tosses)
    ax.plot(x, y, color="black", linewidth=2, label="Normal fit")

    ax.set_xlabel("Number of Heads")
    ax.set_title(title)
    ax.legend()
    return fig


def plot_density_comparison(
    tosses: np.ndarray,
    title: str = "Binomial vs Normal Density",
) -> plt.Figure:
    """
    Kernel density estimate of coin-toss outcomes vs. fitted normal density.

    Mirrors R: forFig2_2.r
    """
    from scipy.stats import gaussian_kde

    fig, ax = plt.subplots()
    mu, sigma = float(np.mean(tosses)), float(np.std(tosses))
    x = np.linspace(tosses.min() - 1, tosses.max() + 1, 400)

    kde = gaussian_kde(tosses)
    ax.plot(x, kde(x), color="black", linewidth=2, label="Binomial (KDE)")
    ax.plot(x, norm.pdf(x, mu, sigma), color="grey", linewidth=2, label="Normal fit")

    ax.set_xlabel("Number of Heads")
    ax.set_title(title)
    ax.legend()
    return fig
