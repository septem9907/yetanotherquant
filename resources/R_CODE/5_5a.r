# Portfolio simulation (OLD 2-asset portfolio): 10% Metro AG + 10% Südzucker + 80% cash.
# MEO.DE has a TP at 35.40 and SL at 26.40; when either is hit the position is liquidated
# into cash. Simulates 10,000 paths of 121 trading days using correlated returns.
# Standalone version: loads data internally (originally required 5_3.r).

library(quantmod)
getSymbols(c("MEO.DE", "SZU.DE"), from="2013-05-01", to="2014-05-13")
retsMEO = as.numeric(periodReturn(MEO.DE, period='daily'))
retsSZU = as.numeric(periodReturn(SZU.DE, period='daily'))
n = min(length(retsMEO), length(retsSZU))

library(mvtnorm)
library(MASS)
library(tseries)

volaMEO = sd(retsMEO[1:n])   # ~0.01883767
volaSZU = sd(retsSZU[1:n])   # ~0.02423929
driftMEO = 0.0007; driftSZU = 0.0003   # implied drifts from 5_4.r
impliedDrifts = c(driftMEO, driftSZU)
rho    = cor(retsSZU[1:n], retsMEO[1:n])   # empirical correlation ~0.18
covar  = volaMEO * volaSZU * rho
covMatrix = matrix(c(volaMEO^2, covar, covar, volaSZU^2), 2, 2)

N_DAYS        = 121   # 6-month horizon (242/2 trading days)
N_SIMULATIONS = 10000

# Initial wealth: position sizes adjusted for current price vs. buy price
startWealthMEO = 0.1 * 29.35 / 29.79   # 10% allocation, mark-to-market
startWealthSZU = 0.1 * 15.70 / 16.10

wealthMEO  = array(startWealthMEO, dim=c(N_DAYS, N_SIMULATIONS))
wealthSZU  = array(startWealthSZU, dim=c(N_DAYS, N_SIMULATIONS))
wealthCash = array(0.8,            dim=c(N_DAYS, N_SIMULATIONS))
maxDDpath  = array(0.0,            dim=N_SIMULATIONS)

# TP/SL thresholds expressed as fraction of portfolio
tpMEO = 0.1 * (35.40 / 29.79)
slMEO = 0.1 * (26.40 / 29.79)

for(i in 1:N_SIMULATIONS)
{
  mRets = mvrnorm(n=N_DAYS, mu=impliedDrifts, Sigma=covMatrix)
  for(d in 2:N_DAYS)
  {
    wealthMEO[d, i] = wealthMEO[(d-1), i] * (1 + mRets[d, 1])
    wealthSZU[d, i] = wealthSZU[(d-1), i] * (1 + mRets[d, 2])
    if(wealthMEO[d, i] >= tpMEO || wealthMEO[d, i] < slMEO)
    {
      # TP/SL hit: move MEO position to cash for remaining days
      wealthCash[(d:N_DAYS), i] = wealthCash[(d:N_DAYS), i] + wealthMEO[d, i]
      wealthMEO[(d:N_DAYS), i]  = 0.0
    }
  }
  pathWealth   = wealthCash[,i] + wealthMEO[,i] + wealthSZU[,i]
  maxDDpath[i] = (maxdrawdown(pathWealth))[[1]]
}

totalWealth    = wealthCash + wealthMEO + wealthSZU
terminalWealth = totalWealth[N_DAYS,]

par(mfrow=c(2,1))
print(paste("mean terminal wealth:", mean(terminalWealth)))
print(paste("s.d. terminal wealth:", sd(terminalWealth)))
plot(density(terminalWealth))
print(paste("mean Maximum Drawdown:", mean(maxDDpath)))
print(paste("s.d. Maximum Drawdown:", sd(maxDDpath)))
plot(density(maxDDpath))
