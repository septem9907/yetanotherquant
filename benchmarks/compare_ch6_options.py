"""
Benchmark: Chapter 6 — Black-Scholes Options

Compares Python Black-Scholes output to:
  1. Known analytical reference values (computed independently)
  2. Boundary conditions (deep ITM, deep OTM, zero maturity)
  3. Put-call parity

All checks are deterministic with tight tolerances (1e-6 or better).

Expected values from R's RQuantLib::EuropeanOption for the 6_1.r scenario:
  EuropeanOption("call", 23.81, 60.0, 0.0, 0.0057, 4, 0.37)

These are computed here independently via the B-S formula so we can verify
the Python implementation is correct without running R.
"""

import numpy as np
from scipy.stats import norm
from yetanotherquant.chapter6.options import bs_call_price, bs_greeks


def bs_reference(S, K, T, r, sigma):
    """Reference B-S implementation for comparison."""
    d1 = (np.log(S / K) + (r + 0.5 * sigma**2) * T) / (sigma * np.sqrt(T))
    d2 = d1 - sigma * np.sqrt(T)
    value = S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2)
    delta = norm.cdf(d1)
    gamma = norm.pdf(d1) / (S * sigma * np.sqrt(T))
    vega  = S * norm.pdf(d1) * np.sqrt(T)
    return {"value": value, "delta": delta, "gamma": gamma, "vega": vega}


def check(name: str, got: float, expected: float, tol: float) -> bool:
    diff = abs(got - expected)
    ok = diff <= tol
    status = "PASS" if ok else "FAIL"
    print(f"  [{status}] {name}")
    print(f"         Got:      {got:.8f}")
    print(f"         Expected: {expected:.8f}")
    print(f"         |diff|:   {diff:.2e}  (tol: {tol:.2e})")
    return ok


def run() -> bool:
    print("=" * 60)
    print("BENCHMARK: Chapter 6 — Black-Scholes Options")
    print("=" * 60)
    all_pass = True

    # ---- Parameters from 6_1.r ----
    S0, K, r, sigma0 = 23.81, 60.0, 0.0057, 0.37

    # ---- 1. Price at T=4 matches independent reference ----
    print("\n--- Call price at T=4yr (6_1.r parameters) ---")
    ref4 = bs_reference(S0, K, T=4, r=r, sigma=sigma0)
    py4  = bs_greeks(S0, K, T=4, r=r, sigma=sigma0)
    all_pass &= check("Price (T=4)",  py4["value"], ref4["value"],  tol=1e-8)
    all_pass &= check("Delta (T=4)",  py4["delta"], ref4["delta"],  tol=1e-8)
    all_pass &= check("Gamma (T=4)",  py4["gamma"], ref4["gamma"],  tol=1e-8)
    all_pass &= check("Vega (T=4)",   py4["vega"],  ref4["vega"],   tol=1e-8)

    # ---- 2. Price at T=3 (one year later) ----
    print("\n--- Call price at T=3yr ---")
    ref3 = bs_reference(S0, K, T=3, r=r, sigma=sigma0)
    py3  = bs_greeks(S0, K, T=3, r=r, sigma=sigma0)
    all_pass &= check("Price (T=3) < Price (T=4)  [time decay]",
                      1.0 if py3["value"] < py4["value"] else 0.0,
                      1.0, tol=0.5)
    all_pass &= check("Price (T=3)", py3["value"], ref3["value"], tol=1e-8)

    # ---- 3. Put-call parity: C - P = S - K*exp(-rT) ----
    print("\n--- Put-call parity (ATM option) ---")
    S_atm, K_atm, T_atm = 50.0, 50.0, 1.0
    c = bs_call_price(S_atm, K_atm, T_atm, r, sigma0)
    # Put via parity: P = C - S + K*exp(-rT)
    put_via_parity = c - S_atm + K_atm * np.exp(-r * T_atm)
    # Put via B-S directly (manually)
    d1 = (np.log(S_atm/K_atm) + (r + 0.5*sigma0**2)*T_atm) / (sigma0*np.sqrt(T_atm))
    d2 = d1 - sigma0*np.sqrt(T_atm)
    put_direct = K_atm * np.exp(-r*T_atm) * norm.cdf(-d2) - S_atm * norm.cdf(-d1)
    all_pass &= check("Put-call parity", put_via_parity, put_direct, tol=1e-10)

    # ---- 4. Boundary: T→0 ----
    print("\n--- Boundary: T=0 (intrinsic value) ---")
    py_T0 = bs_call_price(60.0, 50.0, T=0, r=r, sigma=sigma0)  # ITM: intrinsic = 10
    all_pass &= check("T=0 ITM call = max(S-K, 0) = 10", py_T0, 10.0, tol=1e-9)
    py_T0_otm = bs_call_price(40.0, 50.0, T=0, r=r, sigma=sigma0)  # OTM: intrinsic = 0
    all_pass &= check("T=0 OTM call = 0", py_T0_otm, 0.0, tol=1e-9)

    # ---- 5. Deep OTM: price should be very small ----
    print("\n--- Deep OTM ---")
    py_deep_otm = bs_call_price(10.0, 1000.0, T=1.0, r=r, sigma=sigma0)
    all_pass &= check("Deep OTM call < 0.01", 1.0 if py_deep_otm < 0.01 else 0.0, 1.0, tol=0.5)

    # ---- 6. Delta in [0, 1] for calls ----
    print("\n--- Delta bounds ---")
    for S_test in [10.0, 23.81, 50.0, 100.0]:
        g = bs_greeks(S_test, K, T=4, r=r, sigma=sigma0)
        all_pass &= check(f"Delta in [0,1] for S={S_test}",
                          1.0 if 0 <= g["delta"] <= 1 else 0.0, 1.0, tol=0.5)

    # ---- 7. Gamma > 0 ----
    print("\n--- Gamma positivity ---")
    g_mid = bs_greeks(S0, K, T=4, r=r, sigma=sigma0)
    all_pass &= check("Gamma > 0", 1.0 if g_mid["gamma"] > 0 else 0.0, 1.0, tol=0.5)

    print()
    print(f"Result: {'ALL PASS' if all_pass else 'SOME FAILED'}")
    return all_pass


if __name__ == "__main__":
    import sys
    sys.exit(0 if run() else 1)
