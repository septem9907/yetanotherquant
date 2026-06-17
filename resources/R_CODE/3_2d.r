# Monte Carlo simulation of portfolio wealth paths over 10 years (120 months).
# Uses hardcoded empirical DAX monthly mu and sigma.
# Shows the wide spread of possible outcomes across 10,000 simulated paths.

mu = 0.0085    # empirical monthly mean return (DAX)
sigma = 0.0605 # empirical monthly standard deviation
N_SIMULATIONS = 10000
N_MONTHS = 120  # 10-year investment horizon

simResult = array(1.0, dim=c(N_SIMULATIONS, N_MONTHS))
for(i in 1:N_SIMULATIONS)
{
  rets = rnorm(N_MONTHS, mu, sigma)
  for(k in 2:N_MONTHS)
  {
    simResult[i, k] = simResult[i, (k-1)] * (1 + rets[k])
  }
}

par(mfrow=c(2,1))
ts.plot(simResult[1,], lwd="2")
lines(simResult[1000,], lwd="2", col="grey")
lines(simResult[5000,], lwd="2", col="brown")
plot(density(simResult[, N_MONTHS]))  # distribution of terminal wealth
