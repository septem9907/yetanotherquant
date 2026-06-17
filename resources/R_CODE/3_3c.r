##run after R-code 3.3a
kellySensitivity <-function()
{
  #set "genuine" parameters
  n = length(daxMonthlyRets) #281
  trueMu = mean(daxMonthlyRets) #0.008567559
  trueSigma = sd(daxMonthlyRets) #0.06050129
  #make three iterations
  for( iteration in 1:3 )
  {
    #get a limited(!) from the genuine distribution
    rets = rnorm(n, trueMu, trueSigma)
    mu = mean(rets)
    sigma = sd(rets)
    #find optimal Kelly fraction
    wealth = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
    meanLogWealth = array(0.0, dim=N_STEPS)
    for( u in 1:N_STEPS )
    {
      for( i in 2:N_SIMULATIONS)
      {
        monRets = rnorm(N_MONTHS, mu, sigma)
        for(m in 1:N_MONTHS)
        {
          if( monRets[m] < -0.99 ) monRets[m] = -0.99 #truncate
          if( monRets[m] > 0.99 ) monRets[m] = 0.99 #at +/-99%
          portfolioRet = ((u / N_STEPS)*(monRets[m] - r) + (1 + r))
          wealth[u, i] = wealth[u, (i-1)] * portfolioRet
        }
      }
      meanLogWealth[u] = mean(log(wealth[u, ]))
    }
    print(paste("Iteration: ", iteration, sep=""))
    print(max(meanLogWealth))
    print(which.max(meanLogWealth))
  }
}
#compile before running to speed-up
require(compiler)
enableJIT(3) #maximum optimization of JIT compiler
kellyFast <- cmpfun(kellySensitivity)
kellyFast()
