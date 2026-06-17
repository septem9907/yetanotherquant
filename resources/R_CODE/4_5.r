library(tseries)
N = 1000
trades = 395
ret = 0.003
maxDD = array(0.0, dim=N)
termWealth = array(0.0, dim=N)
for(i in 1:N)
{
  results = rbinom(trades, 1, 0.64)
  wealth = array(1.0, dim=(trades+1))
  for(k in 2:(trades+1))
  {
  if(results[k-1] == 1)
    wealth[k] = wealth[k-1] * (1 + ret)
  else
    wealth[k] = wealth[k-1] * (1 - ret )
  }
  maxDD[i] = (maxdrawdown(wealth))[[1]]
  termWealth[i] = wealth[trades+1]
}
par(mfrow=c(1,2))
plot((density(termWealth)))
plot((density(maxDD)))