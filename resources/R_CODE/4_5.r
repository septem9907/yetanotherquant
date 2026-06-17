# Simulates a hypothetical trading system with 64% win rate, fixed ±0.3% return per trade,
# over 395 trades per run repeated 1,000 times. Reports distributions of terminal wealth
# and maximum drawdown. Useful for setting realistic drawdown expectations before live trading.

library(tseries)
N = 1000      # simulation runs
trades = 395  # trades per run
ret = 0.003   # +0.3% per winning trade, -0.3% per losing trade

maxDD      = array(0.0, dim=N)
termWealth = array(0.0, dim=N)

for(i in 1:N)
{
  results = rbinom(trades, 1, 0.64)  # 1 = win, 0 = loss
  wealth  = array(1.0, dim=(trades+1))
  for(k in 2:(trades+1))
  {
    if(results[k-1] == 1)
      wealth[k] = wealth[k-1] * (1 + ret)
    else
      wealth[k] = wealth[k-1] * (1 - ret)
  }
  maxDD[i]      = (maxdrawdown(wealth))[[1]]
  termWealth[i] = wealth[trades+1]
}

par(mfrow=c(1,2))
plot((density(termWealth)))
plot((density(maxDD)))
