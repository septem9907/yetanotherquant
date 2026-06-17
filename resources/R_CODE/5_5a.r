##Old-portfolio##
#run after R-code 5.3
library(mvtnorm)
library(MASS)
library(tseries) #for max. drawdown
volaMEO = sd(retsMEO[1:n]) #is 0.01883767
volaSZU = sd(retsSZU[1:n]) #is 0.02423929
driftMEO = 0.0007
driftSZU = 0.0003
impliedDrifts = c(driftMEO, driftSZU)
rho = cor(retsSZU[1:n], retsMEO[1:n]) #is 0.18
covar = volaMEO * volaSZU * rho
covMatrix = matrix( c(volaMEO^2, covar, covar, volaSZU^2), 2, 2)
N_DAYS = 121 #6 months = half of year = 242/2 trading days
N_SIMULATIONS = 10000
startWealthMEO = 0.1 * 29.35 / 29.79 #10% * current price / buy price
startWealthSZU = 0.1 * 15.70 / 16.10
wealthMEO = array(startWealthMEO, dim=c(N_DAYS, N_SIMULATIONS))
wealthSZU = array(startWealthSZU, dim=c(N_DAYS, N_SIMULATIONS))
wealthCash = array(0.8, dim=c(N_DAYS, N_SIMULATIONS)) #and 80% in Cash
maxDDpath = array(0.0, dim=N_SIMULATIONS) #max. drawdown per path
tpMEO = 0.1 * (35.40 / 29.79) #€29.79 is the buy price of METRO AG
slMEO = 0.1 * (26.40 / 29.79)
for(i in 1:N_SIMULATIONS)
{
  #pairs of correlated returns
  mRets = mvrnorm(n=N_DAYS, mu=impliedDrifts, Sigma=covMatrix)
  for( d in 2:N_DAYS)
  {
    wealthMEO[d, i] = wealthMEO[(d-1), i] * (1 + mRets[d, 1])
    wealthSZU[d, i] = wealthSZU[(d-1), i] * (1 + mRets[d, 2])
    if( wealthMEO[d, i] >= tpMEO || wealthMEO[d,i ] < slMEO )
    {
      wealthCash[(d:N_DAYS), i] = wealthCash[(d:N_DAYS), i] + wealthMEO[d, i]
      wealthMEO[(d:N_DAYS), i] = 0.0
    }
  }
  pathWealth = wealthCash[,i] + wealthMEO[,i] + wealthSZU[,i]
  maxDDpath[i] = (maxdrawdown(pathWealth))[[1]]
}
totalWealth = wealthCash + wealthMEO + wealthSZU
terminalWealth = totalWealth[N_DAYS,]
par(mfrow=c(2,1))
print(paste("mean terminal wealth:", mean(terminalWealth)))
print(paste("s.d. terminal wealth:", sd(terminalWealth)))
plot(density(terminalWealth))
print(paste("mean Maximum Drawdown:", mean(maxDDpath)))
print(paste("s.d. Maximum Drawdown:", sd(maxDDpath)))
plot(density(maxDDpath))