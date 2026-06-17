# Exercise 3.1 Part 2: given a Kelly fraction, simulates 10,000 annual paths
# and reports probabilities of exceeding -5% and -20% drawdown thresholds,
# plus the terminal log-wealth distribution. Evaluated for two stocks.

library("fTrading")

solEx31Part2 <- function(mu, sigma, kellyFrac)
{
  N_TDAYS = 242
  N_SIMULATIONS = 10000
  r = 0.01 / N_TDAYS

  results     = array(1.0, dim=c(N_SIMULATIONS, N_TDAYS))
  drawDown005 = array(0, dim=N_SIMULATIONS)  # 1 if MDD < -5%
  drawDown02  = array(0, dim=N_SIMULATIONS)  # 1 if MDD < -20%

  for(i in 1:N_SIMULATIONS)
  {
    stockRets = rnorm(N_TDAYS, mu, sigma)
    for(d in 2:N_TDAYS)
    {
      if(stockRets[d] < -0.99) stockRets[d] = -0.99
      if(stockRets[d] > 0.99)  stockRets[d] = 0.99
      portfolioRet = (stockRets[d] - r) * kellyFrac + (1 + r)
      results[i, d] = results[i, (d-1)] * portfolioRet
    }
    path = results[i,]
    mdd = maxDrawDown(path)
    mddValue = (path[mdd$to] / path[mdd$from]) - 1
    if(mddValue < -0.2) {
      drawDown02[i]  = 1
      drawDown005[i] = 1
    }
    if(mddValue < -0.05)
      drawDown005[i] = 1
  }

  print(sum(drawDown02)  / N_SIMULATIONS)   # P(MDD < -20%)
  print(sum(drawDown005) / N_SIMULATIONS)   # P(MDD < -5%)
  terminalLogWealth = log(results[, N_TDAYS])
  print(mean(terminalLogWealth))
  print(sd(terminalLogWealth))
  plot(density(terminalLogWealth))
}

require(compiler)
enableJIT(3)
solEx31Part2Fast <- cmpfun(solEx31Part2)

mu1 = 0.0003; sigma1 = 0.02; kellyFrac1 = 0.76
solEx31Part2Fast(mu1, sigma1, kellyFrac1)

mu2 = 0.0006; sigma2 = 0.04; kellyFrac2 = 0.65
solEx31Part2Fast(mu2, sigma2, kellyFrac2)
