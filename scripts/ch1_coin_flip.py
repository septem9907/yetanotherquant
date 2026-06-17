"""
Chapter 1 — Coin Flip Probability (R: 1_1.r)

Computes P(X >= 60 | X ~ Binomial(100, 0.5)) exactly and via Monte Carlo.
"""

from yetanotherquant.chapter1.probability import exact_tail_prob, monte_carlo_tail_prob

N, K, P = 100, 60, 0.5
N_SIM = 100_000

exact = exact_tail_prob(N, K, P)
mc = monte_carlo_tail_prob(N, K, P, n_sim=N_SIM, seed=42)

print(f"P(X >= {K} | Binomial({N}, {P}))")
print(f"  Exact (scipy):    {exact:.6f}")
print(f"  Monte Carlo:      {mc:.6f}  (N_sim={N_SIM:,})")
print("  Expected (R):     0.028444")
print(f"  Difference:       {abs(exact - 0.028444):.2e}")
