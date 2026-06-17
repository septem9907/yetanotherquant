# Kelly fraction sensitivity analysis: shows how parameter estimation error
# causes the optimal fraction to vary across three independent samples drawn
# from the same DAX distribution. Illustrates the "Kelly is sensitive to inputs" problem.
# Standalone version: loads data internally (originally required 3_3a.r).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')

N_SIMULATIONS = 10000
N_MONTHS = 120
N_STEPS = 100
r = 0.03 / 12  # monthly risk-free rate

kellySensitivity <- function()
{
  n = length(daxMonthlyRets)
  trueMu    = mean(daxMonthlyRets)
  trueSigma = sd(daxMonthlyRets)

  for(iteration in 1:3)
  {
    # Draw a limited sample to simulate parameter estimation from finite history
    rets  = rnorm(n, trueMu, trueSigma)
    mu    = mean(rets)
    sigma = sd(rets)

    wealth       = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
    meanLogWealth = array(0.0, dim=N_STEPS)

    for(u in 1:N_STEPS)
    {
      for(i in 2:N_SIMULATIONS)
      {
        monRets = rnorm(N_MONTHS, mu, sigma)
        for(m in 1:N_MONTHS)
        {
          if(monRets[m] < -0.99) monRets[m] = -0.99
          if(monRets[m] > 0.99)  monRets[m] = 0.99
          portfolioRet = ((u / N_STEPS) * (monRets[m] - r) + (1 + r))
          wealth[u, i] = wealth[u, (i-1)] * portfolioRet
        }
      }
      meanLogWealth[u] = mean(log(wealth[u,]))
    }
    print(paste("Iteration: ", iteration, sep=""))
    print(max(meanLogWealth))
    print(which.max(meanLogWealth))
  }
}

require(compiler)
enableJIT(3)  # JIT compilation for ~10x speed-up on nested loops
kellyFast <- cmpfun(kellySensitivity)
kellyFast()
