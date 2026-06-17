# Removes extreme DAX daily returns (beyond ±3 sigma) and re-runs QQ-plot.
# Shows that after capping outliers, the remaining returns are near-normal.
# Standalone version: loads data internally (originally required 3_2a.r).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")
n = length(daxReturns)

cap = 3 * sd(daxReturns[2:n])  # 3-sigma threshold for filtering outliers
capRets = array(0.0, dim=0)
for(i in 2:n)
{
  if(abs(daxReturns[i]) < cap)
  {
    capRets = c(capRets, daxReturns[i])
  }
}
qqnorm(capRets)
print(length(capRets) / length(daxReturns[2:n]))  # fraction of returns within 3 sigma
