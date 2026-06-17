# Backtests four DAX allocation fractions (30%, 50%, 93%, 100%) on historical data.
# The Kelly-optimal fraction found in 3_3a.r is approximately 93%.
# Standalone version: loads data internally (originally required 3_3a.r).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
r = 0.03 / 12  # risk-free monthly return (3% annual)

w30  = array(1.0, dim=n)
w50  = array(1.0, dim=n)
w93  = array(1.0, dim=n)
w100 = array(1.0, dim=n)

for(m in 2:n)
{
  ret = daxMonthlyRets[m-1]
  w100[m] = w100[m-1] * (1 + ret)                         # 100% in DAX (buy & hold)
  w30[m]  = w30[m-1]  * (0.30 * (ret - r) + (1 + r))      # 30% in DAX
  w50[m]  = w50[m-1]  * (0.50 * (ret - r) + (1 + r))      # 50% in DAX
  w93[m]  = w93[m-1]  * (0.93 * (ret - r) + (1 + r))      # ~Kelly-optimal fraction
}

ts.plot(w100)
lines(w30,  col="grey",  lwd=2, lty=2)
lines(w50,  col="black", lwd=2, lty=2)
lines(w93,  col="grey",  lwd=2)
