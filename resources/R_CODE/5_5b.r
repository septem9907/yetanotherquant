# Portfolio simulation (NEW 3-asset portfolio): adds 10% iShares Silver (SLV)
# to the 2-asset portfolio from 5_5a.r, reducing cash to 70%.
# SLV also has a TP at 22.00 and SL at 18.40. Demonstrates how adding a low-
# correlated asset improves risk/return profile.
# Standalone version: loads data internally (originally required 5_3.r).

library(quantmod)
getSymbols(c("MEO.DE", "SZU.DE", "SLV"), from="2013-05-01", to="2014-05-13")
retsMEO = as.numeric(periodReturn(MEO.DE, period='daily'))
retsSZU = as.numeric(periodReturn(SZU.DE, period='daily'))
retsSLV = as.numeric(periodReturn(SLV,    period='daily'))
n = min(length(retsMEO), length(retsSZU), length(retsSLV))
retsMatrix = array(0.0, dim=c(n, 3))
retsMatrix[,1] = retsMEO[1:n]
retsMatrix[,2] = retsSZU[1:n]
retsMatrix[,3] = retsSLV[1:n]

library(mvtnorm)
library(MASS)
library(tseries)

driftMEO = 0.0007; driftSZU = 0.0003; driftSLV = 0.0015
impliedDrifts = c(driftMEO, driftSZU, driftSLV)
covMatrix = cov(retsMatrix)  # 3x3 empirical covariance matrix

N_DAYS        = 121
N_SIMULATIONS = 10000

startWealthMEO = 0.1 * 29.35 / 29.79
startWealthSZU = 0.1 * 15.70 / 16.10

wealthMEO  = array(startWealthMEO, dim=c(N_DAYS, N_SIMULATIONS))
wealthSZU  = array(startWealthSZU, dim=c(N_DAYS, N_SIMULATIONS))
wealthSLV  = array(0.1,            dim=c(N_DAYS, N_SIMULATIONS))
wealthCash = array(0.7,            dim=c(N_DAYS, N_SIMULATIONS))
maxDDpath  = array(0.0,            dim=N_SIMULATIONS)

tpMEO = 0.1 * (35.40 / 29.79)
slMEO = 0.1 * (26.40 / 29.79)
tpSLV = 0.1 * (22.00 / 19.40)
slSLV = 0.1 * (18.40 / 19.40)

for(i in 1:N_SIMULATIONS)
{
  mRets = mvrnorm(n=N_DAYS, mu=impliedDrifts, Sigma=covMatrix)
  for(d in 2:N_DAYS)
  {
    wealthMEO[d, i] = wealthMEO[(d-1), i] * (1 + mRets[d, 1])
    wealthSZU[d, i] = wealthSZU[(d-1), i] * (1 + mRets[d, 2])
    wealthSLV[d, i] = wealthSLV[(d-1), i] * (1 + mRets[d, 3])
    if(wealthMEO[d, i] >= tpMEO || wealthMEO[d, i] < slMEO) {
      wealthCash[(d:N_DAYS), i] = wealthCash[(d:N_DAYS), i] + wealthMEO[d, i]
      wealthMEO[(d:N_DAYS), i]  = 0.0
    }
    if(wealthSLV[d, i] >= tpSLV || wealthSLV[d, i] < slSLV) {
      wealthCash[(d:N_DAYS), i] = wealthCash[(d:N_DAYS), i] + wealthSLV[d, i]
      wealthSLV[(d:N_DAYS), i]  = 0.0
    }
  }
  pathWealth   = wealthCash[,i] + wealthMEO[,i] + wealthSZU[,i] + wealthSLV[,i]
  maxDDpath[i] = (maxdrawdown(pathWealth))[[1]]
}

totalWealth    = wealthCash + wealthMEO + wealthSZU + wealthSLV
terminalWealth = totalWealth[N_DAYS,]

par(mfrow=c(2,1))
print(paste("mean terminal wealth:", mean(terminalWealth)))
print(paste("s.d. terminal wealth:", sd(terminalWealth)))
plot(density(terminalWealth))
print(paste("mean Maximum Drawdown:", mean(maxDDpath)))
print(paste("s.d. Maximum Drawdown:", sd(maxDDpath)))
plot(density(maxDDpath))
