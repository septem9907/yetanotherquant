# Numerically finds the optimal Kelly fraction for DAX monthly returns.
# Iterates over 100 candidate fractions (1%..100% of capital in DAX),
# simulates 10,000 paths of 120 months each, and picks the fraction that
# maximises the mean log-wealth (the Kelly criterion objective).
#
# Variables N_STEPS, N_SIMULATIONS, N_MONTHS, r, daxMonthlyRets are used by 3_3b.r and 3_3c.r.

N_SIMULATIONS = 10000
N_MONTHS = 120  # 10-year investment horizon
N_STEPS = 100   # grid: try 1%, 2%, ..., 100% of capital in DAX

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)
r = 0.03 / 12  # risk-free monthly return (3% annual)

wealth = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
meanLogWealth = array(0.0, dim=N_STEPS)

for(u in 1:N_STEPS) {
  for(i in 2:N_SIMULATIONS)
  {
    monRets = rnorm(N_MONTHS, mu, sigma)
    for(m in 1:N_MONTHS)
    {
      if(monRets[m] < -0.99) monRets[m] = -0.99  # truncate at -99% to avoid ruin
      if(monRets[m] > 0.99)  monRets[m] = 0.99
      # portfolio return = fraction * (risky excess return) + risk-free return
      portfolioRet = ((u / N_STEPS) * (monRets[m] - r) + (1 + r))
      wealth[u, i] = wealth[u, (i-1)] * portfolioRet
    }
  }
  meanLogWealth[u] = mean(log(wealth[u,]))
}

max(meanLogWealth)
which.max(meanLogWealth)  # optimal fraction (as index: divide by 100 to get %)
