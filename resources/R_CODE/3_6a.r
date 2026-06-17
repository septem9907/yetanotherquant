solEx31Part1 <- function(mu, sigma)
{
  N_SIMULATIONS = 10000
  N_TDAYS = 242 #there are 242 trading days in a year
  N_STEPS = 100 #iteratively try 1%, 2%, ... , 100% capital in stock
  r = 0.01 / N_TDAYS #daily interest rate
  #find optimal Kelly fraction
  wealth = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
  meanLogWealth = array(0.0, dim=N_STEPS)
  for( u in 1:N_STEPS )
  {
    for( i in 2:N_SIMULATIONS)
    {
      monRets = rnorm(N_TDAYS, mu, sigma)
      for(m in 1:N_TDAYS)
      {
        if( monRets[m] < -0.99 ) monRets[m] = -0.99 #truncate
        if( monRets[m] > 0.99 ) monRets[m] = 0.99 #at +/-99%
        portfolioRet = ((u / N_STEPS)*(monRets[m] - r) + (1 + r))
        wealth[u, i] = wealth[u, (i-1)] * portfolioRet
      }
    }
    meanLogWealth[u] = mean(log(wealth[u, ]))
  }
  max(meanLogWealth)
  which.max(meanLogWealth)
}
#compile before running to speed-up
require(compiler)
enableJIT(3) #maximum optimization of JIT compiler
kellyFast <- cmpfun(solEx31Part1)
mu1 = 0.0003
sigma1 = 0.02
mu2 = 0.0006
sigma2 = 0.04
kellyFast(mu1, sigma1)
kellyFast(mu2, sigma2)