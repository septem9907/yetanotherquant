# Exercise 3.1 Part 1: finds the optimal Kelly fraction for a single stock
# using daily returns over one trading year (242 days), at two different
# mean/volatility settings. Uses JIT compilation to speed up nested loops.

solEx31Part1 <- function(mu, sigma)
{
  N_SIMULATIONS = 10000
  N_TDAYS = 242   # trading days per year
  N_STEPS = 100   # grid: try 1%..100% of capital in stock
  r = 0.01 / N_TDAYS  # daily risk-free rate (1% annual)

  wealth       = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
  meanLogWealth = array(0.0, dim=N_STEPS)

  for(u in 1:N_STEPS)
  {
    for(i in 2:N_SIMULATIONS)
    {
      monRets = rnorm(N_TDAYS, mu, sigma)
      for(m in 1:N_TDAYS)
      {
        if(monRets[m] < -0.99) monRets[m] = -0.99
        if(monRets[m] > 0.99)  monRets[m] = 0.99
        portfolioRet = ((u / N_STEPS) * (monRets[m] - r) + (1 + r))
        wealth[u, i] = wealth[u, (i-1)] * portfolioRet
      }
    }
    meanLogWealth[u] = mean(log(wealth[u,]))
  }
  max(meanLogWealth)
  which.max(meanLogWealth)
}

require(compiler)
enableJIT(3)
kellyFast <- cmpfun(solEx31Part1)

# Stock A: modest drift, moderate vol
mu1 = 0.0003; sigma1 = 0.02
kellyFast(mu1, sigma1)

# Stock B: higher drift, higher vol
mu2 = 0.0006; sigma2 = 0.04
kellyFast(mu2, sigma2)
