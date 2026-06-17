N_SIMULATIONS = 10000
N_MONTHS = 120 #10 years investment horizon
N_STEPS = 100 #iteratively try 1%, 2%, ... , 100% capital in DAX
library(quantmod)
#get data, set or estimate parametes
getSymbols("^GDAXI", from="1900-01-01")
#getSymbols("^GDAXI", from="2007-01-01") #try also this
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)
r = 0.03 / 12 #monthly return thus divide by 12
#find optimal Kelly fraction
wealth = array(1.0, dim=c(N_STEPS, N_SIMULATIONS))
meanLogWealth = array(0.0, dim=N_STEPS)
for( u in 1:N_STEPS ) {
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
max(meanLogWealth)
which.max(meanLogWealth)