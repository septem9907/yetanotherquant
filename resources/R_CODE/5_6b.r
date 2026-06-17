#run after R-Code 5.6a
library(tseries) #for max. drawdown
trade = 1
N_TRADES = 50
termWealth = array(1.0, dim=(N_SIMULATIONS / N_TRADES))
maxDD = array(0.0, dim=(N_SIMULATIONS / N_TRADES))
index = 1
while(trade < N_SIMULATIONS )
{
  wealth = array(1.0, dim=N_TRADES)
  rets = returns[trade:(trade+N_TRADES-1)]
  trade = trade + N_TRADES
  for( d in 1:N_TRADES)
  {
    wealth[d+1] = wealth[d] * (1+ rets[d])
  }
  termWealth[index] = wealth[N_TRADES]
  maxDD[index] = (maxdrawdown(wealth))[[1]]
  index = index + 1
}
cgr = log(termWealth)
print(paste("expected cumulative growth rate: ", mean(cgr)))
print(paste("s.d. of cumulative growth rate: ", sd(cgr)))
par(mfrow=c(2,1))
plot(density(cgr))
plot(density(maxDD))
mean(maxDD)
sd(maxDD)