"""
Chapter 1 — Probability Foundations (R script: 1_1.r)

Computes P(X >= k | X ~ Binomial(n, p)) two ways:
  1. Exact via the survival function of the binomial CDF.
  2. Monte Carlo approximation.
"""

import numpy as np
from scipy.stats import binom


def exact_tail_prob(n: int, k: int, p: float) -> float:
    """
    P(X >= k) for X ~ Binomial(n, p).

    Mirrors R: 1 - pbinom(k-1, n, p)
    """
    return float(binom.sf(k - 1, n, p))


def monte_carlo_tail_prob(
    n: int,
    k: int,
    p: float,
    n_sim: int = 100_000,
    seed: int | None = None,
) -> float:
    """
    Monte Carlo estimate of P(X >= k) for X ~ Binomial(n, p).

    Simulates n_sim experiments of n coin flips and counts how often
    the number of heads >= k.
    """
    rng = np.random.default_rng(seed)
    tosses = rng.binomial(n, p, size=n_sim)
    return float(np.mean(tosses >= k))
