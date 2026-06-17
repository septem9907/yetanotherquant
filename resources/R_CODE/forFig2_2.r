u = seq(1,100)/100 #fractions
expectedGrowthRates = 0.5*(log(1 + 1.7*u) + log(1 - 0.7*u))
plot(u, expectedGrowthRates, type="l", lwd=2)
abline(v=0.42, col="grey")
abline(h=expectedGrowthRates[42], col="grey")
abline(h=expectedGrowthRates[100], col="grey")
which.max(expectedGrowthRates)