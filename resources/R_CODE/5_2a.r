#run after R-code 5.2
s1 = 0.4 #volatility of the 1st asset
s2 = 0.3 #..of the 2nd asset
rho = 0.7 #correlation coefficient, must be in [-1, 1]
mu1 = 0.12 #expected return of the 1st asset
mu2 = 0.09 #..of the 2nd asset
riskFreeReturn = 0.01 #risk-free return
N_SIM = 100 #number of simulations

### theoretical solution with "true" market parameters ###
library("mvtnorm") #multivariate normal distribution
library("MASS") #[generalized] matrix inverse
covMat <- matrix(c(s1*s1, s1*s2*rho, s1*s2*rho, s2*s2), 2,2)
Sigma<-matrix(c(0.131, 0.067, 0.067, 0.158), 2,2)
expRets = c(mu1, mu2)
print( "Optimal portfolio with TRUE market parameters" )
#optimal portfolio via Nekrasov's formula
u = (1+riskFreeReturn) * ginv( Sigma ) %*% (expRets - riskFreeReturn)
print(u)

##three trias with a limited sample of "emprical" market data##
for( trial in 1:3 )
{
  historicalData = mvrnorm(n=N_SIM, expRets, covMatrix)
  Sigma<-estimateSigma(t(historicalData), riskFreeReturn)
  print( paste("...with EMPIRICAL market parameters - TRIAL ", trial) )
  u = (1+riskFreeReturn) * ginv( Sigma ) %*% (expRets - riskFreeReturn)
  print(u)
}