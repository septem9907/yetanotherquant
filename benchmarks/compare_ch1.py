"""
Benchmark: Chapter 1 — Coin Flip Probability

Compares Python output to the expected R value from 1_1.r:
  R: 1 - pbinom(59, 100, 0.5)  →  0.02844397

The exact binomial result is deterministic and should match to machine precision.
The Monte Carlo result is stochastic — we verify it falls within ±3 standard errors.
"""

import numpy as np

from yetanotherquant.chapter1.probability import exact_tail_prob, monte_carlo_tail_prob

R_EXACT = 0.028443966  # from R: 1 - pbinom(59, 100, 0.5)
N, K, P = 100, 60, 0.5
N_SIM = 100_000
TOLERANCE = 1e-8  # exact value must match to this precision
MC_SE_MULTIPLIER = 3.0  # MC value must be within 3 standard errors


def check(name: str, python_val: float, r_val: float, tol: float) -> bool:
    diff = abs(python_val - r_val)
    ok = diff <= tol
    status = "PASS" if ok else "FAIL"
    print(f"  [{status}] {name}")
    print(f"         Python: {python_val:.8f}")
    print(f"         R:      {r_val:.8f}")
    print(f"         |diff|: {diff:.2e}  (tolerance: {tol:.2e})")
    return ok


def run() -> bool:
    print("=" * 60)
    print("BENCHMARK: Chapter 1 — Binomial Tail Probability")
    print("=" * 60)

    all_pass = True

    # --- Exact value ---
    py_exact = exact_tail_prob(N, K, P)
    all_pass &= check(
        "Exact binomial P(X>=60 | Bin(100,0.5))", py_exact, R_EXACT, TOLERANCE
    )

    # --- Monte Carlo ---
    py_mc = monte_carlo_tail_prob(N, K, P, n_sim=N_SIM, seed=42)
    # Standard error of a proportion: sqrt(p*(1-p)/n)
    se_mc = np.sqrt(R_EXACT * (1 - R_EXACT) / N_SIM)
    mc_tol = MC_SE_MULTIPLIER * se_mc
    all_pass &= check(f"Monte Carlo P(X>=60) N_sim={N_SIM:,}", py_mc, R_EXACT, mc_tol)

    print()
    print(f"Result: {'ALL PASS' if all_pass else 'SOME FAILED'}")
    return all_pass


if __name__ == "__main__":
    import sys

    sys.exit(0 if run() else 1)
