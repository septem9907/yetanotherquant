#function to estimate the matrix of the second mixed
#non-centralized moments of the excess returns
estimateSigma<-function(inSampleReturns, riskFreeReturn)
{
  n_assets = (dim(inSampleReturns))[1]
  n_observations = (dim(inSampleReturns))[2]
  covMatrix = array(0, dim=c(n_assets,n_assets))
  for(k in 1:n_assets)
  {
    for(j in 1:n_assets)
    {
      covMatrix[k,j] = mean( (inSampleReturns[k,] -
      riskFreeReturn)*(inSampleReturns[j,] - riskFreeReturn) )
    }
  }
  return(covMatrix)
}

#brute force search for the optimal
#portfolio of two risky stocks and
#a riskless bond.
install.packages("scatterplot3d")
install.packages("mvtnorm") #multivariate normal distribution
install.packages("MASS") #matrix inversion
library(scatterplot3d)
library(sm)
library(mvtnorm)
library(MASS)

#parameters:
riskFreeReturn = 0.02
expRets=c(0.09, 0.09) #expected returns
s1 = 0.16 #standard deviation of returns for the 1st
s2 = 0.16 #...and the 2nd stock
rho = 0.5 #correlation coefficient. Try with rho = 0.0, 0.5 and 1.0 !!!
covMat <- matrix(c(s1, sqrt(s1*s2)*rho, sqrt(s1*s2)*rho, s2),2,2)

#To estimate Sigma we take a BIG sample, so that the estimate
#converges to the genuine value
N = 100000
temp = rmvnorm(n=N, mean=expRets, sigma=covMat)
Sigma<-estimateSigma(t(temp), riskFreeReturn)
#optimal portfolio via Nekrasov's formula
u = (1+riskFreeReturn) * ginv( Sigma ) %*% (expRets - riskFreeReturn)
### detemine the number of all possible fraction
# combinations by no short selling
PATHLEN = 100 #number of trades per path
SIMNUM = 100 #number of repeats (paths)
COMBLEN = 0 #number of admissible fractions
for(i in 0:100) { for(j in 0:(100-i)) { COMBLEN = COMBLEN + 1 } }
  terminalWealth = array(0.0, dim=c(COMBLEN, 3, SIMNUM))

##
allFracs<-function()
{
  for( simulation in 1:SIMNUM)
  {
    rets = rmvnorm(n=N, mean=expRets, sigma=covMat)
    for( i in 1:PATHLEN ) #truncate returns at +/-95%
    {
      if( rets[i, 1] < -0.95 ) rets[i, 1] = -0.95
      if( rets[i, 2] < -0.95 ) rets[i, 2] = -0.95
      if( rets[i, 1] > 0.95 ) rets[i, 1] = 0.95
      if( rets[i, 2] > 0.95 ) rets[i, 2] = 0.95
    }
    idx = 1
    for(i in 0:100)
    {
      for(j in 0:(100-i))
      {
        frac1 = 0.01 * i
        frac2 = 0.01 * j
        wealth = 1.0
        capitalInCash = 1.0 - (frac1 + frac2)
        for( schritt in 1:PATHLEN )
        {
          wealth = wealth * ((1.0 + rets[schritt,1])*frac1
            + (1.0 + rets[schritt,2])*frac2 + 1.02*capitalInCash )
        }
        terminalWealth[idx, 1, simulation] = frac1
        terminalWealth[idx, 2, simulation] = frac2
        terminalWealth[idx, 3, simulation] = wealth
        idx = idx + 1
      }
    }
  }
  return(terminalWealth)
}

library(compiler)
allFracsCompiled<-cmpfun(allFracs) #compiled R-code runs much faster
terminalWealth=allFracsCompiled()
scatterplot3d(terminalWealth[,,1]) #preliminary scatterplot
#Average among all simulation pathes
terminalWealthAveraged = array(0.0, dim=c(COMBLEN, 3, 1))
for( i in 1:COMBLEN )
{
  terminalWealthAveraged[i, 1, 1] = terminalWealth[i, 1, 1]
  terminalWealthAveraged[i, 2, 1] = terminalWealth[i, 2, 1]
  terminalWealthAveraged[i, 3, 1] = mean(log(terminalWealth[i, 3, ]))
}

#compare theoretical and empirical optimal solutions
s3d<-scatterplot3d(terminalWealthAveraged[,,1], angle=120)
teorMaxIdx = which((terminalWealthAveraged[,1,1]==round(u[1], 2)
  & terminalWealthAveraged[,2,1]==round(u[2], 2))) #from 'of' above
terminalWealthAveraged[teorMaxIdx, ,1]
realMaxIdx = which.max(terminalWealthAveraged[,3,1])
terminalWealthAveraged[realMaxIdx, ,1]
s3d$points(x=terminalWealthAveraged[realMaxIdx,1,1],
  y =terminalWealthAveraged[realMaxIdx,2,1],
  z=terminalWealthAveraged[realMaxIdx,3,1],
  type="h", col="grey", lwd=2, lty=2)
s3d$points(x=terminalWealthAveraged[teorMaxIdx,1,1],
  y=terminalWealthAveraged[teorMaxIdx,2,1],
  z=terminalWealthAveraged[teorMaxIdx,3,1],
  type="h", col="grey", lwd=2)