# Compares three return models using DAX monthly data:
#   1. Empirical DAX prices
#   2. Normally distributed returns (same mu/sigma)
#   3. Binomial returns (same mu/sigma, only two outcomes: ±1 sigma)
# Despite different higher moments, all three produce visually similar wealth paths.
#
# Variables n, mu, sigma are used by 3_5.r (now self-contained).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)

# Normal model
simNormalRets = rnorm(n, mu, sigma)
# Binomial model: +sigma or -sigma with equal probability
binom = rbinom(n, 1, 0.5)
binom[binom == 0] = -1
simBinomRets = mu + (sigma * binom)

empiricalDAX = array(1.0, dim=n)
daxNorm      = array(1.0, dim=n)
daxBinom     = array(1.0, dim=n)

for(i in 2:n)
{
  daxNorm[i]      = daxNorm[i-1]      * (1 + simNormalRets[i-1])
  daxBinom[i]     = daxBinom[i-1]     * (1 + simBinomRets[i-1])
  empiricalDAX[i] = empiricalDAX[i-1] * (1 + daxMonthlyRets[i-1])
}

maxY = max(c(daxNorm, daxBinom, empiricalDAX))
minY = min(c(daxNorm, daxBinom, empiricalDAX))
plot(empiricalDAX, type="l", ylim=c(minY, maxY))
lines(daxNorm,  lwd=2)
lines(daxBinom, lwd=2, col="grey")
