#get data from yahoo-finance
library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)
#simulate some normal and binomial returns
simNormalRets = rnorm(n, mu, sigma)
binom = rbinom(n, 1, 0.5)
binom[binom == 0] = -1
simBinomRets = mu + (sigma * binom)
empiricalDAX = array(1.0, dim=n)
daxNorm = array(1.0, dim=n)
daxBinom = array(1.0, dim=n)
for( i in 2:n )
{
  daxNorm[i] = daxNorm[i-1] * (1 + simNormalRets[i-1])
  daxBinom[i] = daxBinom[i-1] * (1 + simBinomRets[i-1])
  empiricalDAX[i] = empiricalDAX[i-1] * (1 + daxMonthlyRets[i-1])
}
#plot results
maxY = max(c(daxNorm, daxBinom, empiricalDAX))
minY = min(c(daxNorm, daxBinom, empiricalDAX))
plot(empiricalDAX, type="l", ylim=c(minY, maxY))
lines(daxNorm, lwd=2)
lines(daxBinom, lwd=2, col="grey")