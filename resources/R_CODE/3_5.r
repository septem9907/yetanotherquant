#simulation of the terminal wealth and the maximum drawdown
#run after R-code 3.4
install.packages("fTrading")
library("fTrading")
N_SIMULATIONS = 1000
terminalWealthNorm = array(0.0, dim=N_SIMULATIONS)
terminalWealthBinom = array(0.0, dim=N_SIMULATIONS)
mddNorm = array(0.0, dim=N_SIMULATIONS)
mddBinom = array(0.0, dim=N_SIMULATIONS)
#simulate many scenarios and record the terminal
#wealth and the maximum drawdown for each
for( k in 1:N_SIMULATIONS )
{
  simNormalRets = rnorm(n, mu, sigma)
  binom = rbinom(n, 1, 0.5)
  binom[binom == 0] = -1
  simBinomRets = mu + (sigma * binom)
  daxNorm = array(1.0, dim=n)
  daxBinom = array(1.0, dim=n)
  for( i in 2:n ) {
    daxNorm[i] = daxNorm[i-1] * (1 + simNormalRets[i-1])
    daxBinom[i] = daxBinom[i-1] * (1 + simBinomRets[i-1])
  }
  terminalWealthNorm[k] = daxNorm[n]
  terminalWealthBinom[k] = daxBinom[n]
  mdd = maxDrawDown(daxNorm)
  mddNorm[k] = (daxNorm[mdd$to] / daxNorm[mdd$from]) - 1
  mdd = maxDrawDown(daxBinom)
  mddBinom[k] = (daxBinom[mdd$to] / daxBinom[mdd$from]) - 1
}
#plot the results. Note the better visibility of the terminal log-wealth densities
par(mfrow=c(3,1))
plot(density(terminalWealthNorm), lwd=2)
lines(density(terminalWealthBinom), lwd=2, col="grey")
plot(density(log(terminalWealthNorm)), lwd=2)
lines(density(log(terminalWealthBinom)), lwd=2, col="grey")
plot(density(mddNorm), lwd=2)
lines(density(mddBinom), lwd=2, col="grey")