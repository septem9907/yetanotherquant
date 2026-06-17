# Kelly criterion illustration for a coin-toss game:
# win ratio 1.7, loss ratio 0.7, fair coin (p=0.5).
# Expected log-growth rate = 0.5*log(1+1.7f) + 0.5*log(1-0.7f),
# maximised analytically at f* = (p/l - q/w) = 0.5/0.7 - 0.5/1.7 ≈ 0.42.

u = seq(1, 100) / 100  # fraction of capital bet: 1% to 100%
expectedGrowthRates = 0.5 * (log(1 + 1.7*u) + log(1 - 0.7*u))
plot(u, expectedGrowthRates, type="l", lwd=2)
abline(v=0.42, col="grey")                           # optimal Kelly fraction
abline(h=expectedGrowthRates[42], col="grey")        # expected growth at Kelly
abline(h=expectedGrowthRates[100], col="grey")       # expected growth at 100% bet (negative)
which.max(expectedGrowthRates)
