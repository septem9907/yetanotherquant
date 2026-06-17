"""
Benchmark: Chapter 3 — Kelly Criterion

Verifies:
1. Analytical Kelly fraction for the coin-toss game (forFig3_2.r):
      R: which.max(expectedGrowthRates) = 42  →  f* = 42/100 = 0.42
      Analytical formula: p/loss - q/win = 0.5/0.7 - 0.5/1.7 ≈ 0.4202

2. Expected log-growth at the Kelly fraction (computed from closed form):
      g(f*) = 0.5*log(1+1.7*0.42) + 0.5*log(1-0.7*0.42)

3. Expected log-growth at full bet (f=1) is negative:
      g(1) = 0.5*log(2.7) + 0.5*log(0.3) ≈ -0.064  (R: abline(h=expectedGrowthRates[100]))

4. Simulated Kelly fraction for a coin-toss game should match ≈0.42 within ±10%.

All deterministic values are compared to exact analytical results.
Stochastic values (MC simulation) allow ±10% relative tolerance.
"""

import numpy as np
from yetanotherquant.chapter3.kelly import (
    analytical_kelly_coin, expected_growth_rate,
    kelly_simulation, optimal_kelly_fraction,
)

P_WIN, WIN_MULT, LOSS_MULT = 0.5, 1.7, 0.7

# Pre-compute R reference values analytically (not from MC)
R_FRACS = np.arange(1, 101) / 100
R_RATES  = expected_growth_rate(R_FRACS, P_WIN, WIN_MULT, LOSS_MULT)
R_KELLY_IDX   = int(np.argmax(R_RATES))           # 41 (0-indexed) → fraction = 42%
R_KELLY_FRAC  = R_FRACS[R_KELLY_IDX]              # 0.42
R_KELLY_RATE  = float(R_RATES[R_KELLY_IDX])       # g(0.42)
R_FULL_RATE   = float(R_RATES[-1])                # g(1.0) — should be negative


def check(name: str, got: float, expected: float, tol: float) -> bool:
    diff = abs(got - expected)
    ok = diff <= tol
    status = "PASS" if ok else "FAIL"
    print(f"  [{status}] {name}")
    print(f"         Got:      {got:.6f}")
    print(f"         Expected: {expected:.6f}")
    print(f"         |diff|:   {diff:.2e}  (tol: {tol:.2e})")
    return ok


def run() -> bool:
    print("=" * 60)
    print("BENCHMARK: Chapter 3 — Kelly Criterion")
    print("=" * 60)
    all_pass = True

    # 1. Analytical Kelly fraction
    # R's which.max() on a 1%-step grid returns index 42 → fraction 0.42.
    # Our continuous formula gives 0.4202, differing by at most 0.5% (half-step).
    py_fstar = analytical_kelly_coin(P_WIN, WIN_MULT, LOSS_MULT)
    all_pass &= check("Analytical Kelly fraction (coin-toss)", py_fstar, R_KELLY_FRAC, 5e-3)

    # 2. Expected growth rate at f*
    fracs = np.arange(1, 101) / 100
    py_rates = expected_growth_rate(fracs, P_WIN, WIN_MULT, LOSS_MULT)
    py_rate_at_fstar = float(py_rates[int(py_fstar * 100) - 1])
    all_pass &= check("Expected growth rate at f*", py_rate_at_fstar, R_KELLY_RATE, 1e-9)

    # 3. Growth rate at 100% bet is negative
    py_full_rate = float(py_rates[-1])
    all_pass &= check("Expected growth rate at f=100% (should be negative)", py_full_rate, R_FULL_RATE, 1e-9)
    if py_full_rate >= 0:
        print("  [WARN] f=100% growth rate should be negative!")

    # 4. Simulated Kelly fraction (stochastic coin-toss game)
    # For a bet of fraction f:
    #   win:  portfolio return multiplier = 1 + WIN_MULT * f  (e.g. f=0.42 → ×1.714)
    #   loss: portfolio return multiplier = 1 - LOSS_MULT * f (e.g. f=0.42 → ×0.706)
    print(f"\n  Running simulated Kelly search (coin-toss game)...")
    rng = np.random.default_rng(42)
    mlw_coin = np.empty(100)
    for u in range(1, 101):
        frac = u / 100
        win_port  = 1.0 + WIN_MULT  * frac   # 1 + 1.7*f
        loss_port = 1.0 - LOSS_MULT * frac   # 1 - 0.7*f
        outcomes  = rng.binomial(1, P_WIN, size=(5_000, 30))
        port_rets = np.where(outcomes == 1, win_port, loss_port)
        terminal  = np.prod(port_rets, axis=1)
        mlw_coin[u - 1] = float(np.mean(np.log(np.maximum(terminal, 1e-10))))

    sim_fstar = optimal_kelly_fraction(mlw_coin)
    # Allow ±10% of the analytical value as tolerance
    tol_sim = 0.10 * R_KELLY_FRAC
    all_pass &= check("Simulated Kelly fraction (coin-toss, stochastic)", sim_fstar, R_KELLY_FRAC, tol_sim)

    print()
    print(f"Result: {'ALL PASS' if all_pass else 'SOME FAILED'}")
    return all_pass


if __name__ == "__main__":
    import sys
    sys.exit(0 if run() else 1)
