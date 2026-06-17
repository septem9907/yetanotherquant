# Compares terminal wealth and maximum drawdown distributions between the
# normal and binomial return models (same mu/sigma) via 1,000 simulated paths.
# Despite identical first two moments, the normal model has heavier tails in the MDD.
# Standalone version: loads data internally (originally required 3_4.r).

install.packages("fTrading")
library("fTrading")

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu    = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)

N_SIMULATIONS = 1000
terminalWealthNorm  = array(0.0, dim=N_SIMULATIONS)
terminalWealthBinom = array(0.0, dim=N_SIMULATIONS)
mddNorm  = array(0.0, dim=N_SIMULATIONS)
mddBinom = array(0.0, dim=N_SIMULATIONS)

for(k in 1:N_SIMULATIONS)
{
  simNormalRets = rnorm(n, mu, sigma)
  binom = rbinom(n, 1, 0.5)
  binom[binom == 0] = -1
  simBinomRets = mu + (sigma * binom)

  daxNorm  = array(1.0, dim=n)
  daxBinom = array(1.0, dim=n)
  for(i in 2:n) {
    daxNorm[i]  = daxNorm[i-1]  * (1 + simNormalRets[i-1])
    daxBinom[i] = daxBinom[i-1] * (1 + simBinomRets[i-1])
  }

  terminalWealthNorm[k]  = daxNorm[n]
  terminalWealthBinom[k] = daxBinom[n]

  mdd = maxDrawDown(daxNorm)
  mddNorm[k]  = (daxNorm[mdd$to]  / daxNorm[mdd$from])  - 1
  mdd = maxDrawDown(daxBinom)
  mddBinom[k] = (daxBinom[mdd$to] / daxBinom[mdd$from]) - 1
}

par(mfrow=c(3,1))
plot(density(terminalWealthNorm),  lwd=2)
lines(density(terminalWealthBinom), lwd=2, col="grey")
plot(density(log(terminalWealthNorm)),  lwd=2)   # log-scale is more readable
lines(density(log(terminalWealthBinom)), lwd=2, col="grey")
plot(density(mddNorm),  lwd=2)
lines(density(mddBinom), lwd=2, col="grey")
