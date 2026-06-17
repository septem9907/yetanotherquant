install.packages("tseries")
library(tseries)
N_TRADES = 30
outcomes = rbinom(N_TRADES, 1, 0.5)
wealth = array(1.0, dim=N_TRADES)
wealthKelly = array(1.0, dim=N_TRADES)
wealthHalfKelly = array(1.0, dim=N_TRADES)
for( i in 2:(length(outcomes)) )
{
  if(outcomes[i] == 0) {
    wealth[i] = wealth[i-1] * (1 - 0.7)
    wealthKelly[i] = wealthKelly[i-1] * 0.42 *
      (1 - 0.7) + wealthKelly[i-1] * (1 - 0.42)
    wealthHalfKelly[i] = wealthHalfKelly[i-1] * 0.21 *
      (1 - 0.7) + wealthHalfKelly[i-1] * (1 - 0.21)
  }
  else {
    wealth[i] = wealth[i-1] * (1 + 1.7)
    wealthKelly[i] = wealthKelly[i-1] * 0.42 *
      (1 + 1.7) + wealthKelly[i-1] * (1 - 0.42)
    wealthHalfKelly[i] = wealthHalfKelly[i-1] * 0.21 *
      (1 + 1.7) + wealthHalfKelly[i-1] * (1 - 0.21)
  }
}
chartYmin = min(c(wealth, wealthKelly, wealthHalfKelly))
chartYmax = max(c(wealth, wealthKelly, wealthHalfKelly))
ts.plot(wealth, lwd=1, ylim=c(chartYmin, chartYmax))
lines(wealthKelly, lwd=2,)
lines(wealthHalfKelly, lty=2, lwd=2)