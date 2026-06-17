mu = 0.0085 #empirical value
sigma = 0.0605 # and this too
N_SIMULATIONS = 10000
N_MONTHS = 120 #10 years investment horizon
simResult = array(1.0, dim=c(N_SIMULATIONS, N_MONTHS))
for( i in 1:N_SIMULATIONS)
{
  rets = rnorm(N_MONTHS, mu, sigma)
  for( k in 2:N_MONTHS )
  {
    simResult[i, k] = simResult[i, (k-1)] * (1+rets[k])
  }
}
par(mfrow=c(2,1))
ts.plot(simResult[1, ], lwd="2")
lines(simResult[1000, ], lwd="2", col="grey")
lines(simResult[5000, ], lwd="2", col="brown")
plot(density(simResult[,N_MONTHS])) #terminal prices