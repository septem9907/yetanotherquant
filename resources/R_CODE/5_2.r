# Finds the optimal two-risky-asset + cash portfolio using:
#   (a) Nekrasov's closed-form Kelly formula for multivariate normal returns
#   (b) Brute-force simulation over all (f1, f2) fraction combinations (no short selling)
# Both methods should converge to the same fractions with large enough simulation samples.
#
# Nekrasov's formula: u = (1+r) * Sigma^{-1} * (mu - r)
# where Sigma is the matrix of second mixed non-central moments of EXCESS returns.

install.packages("scatterplot3d")
install.packages("mvtnorm")
install.packages("MASS")
library(scatterplot3d)
library(sm)
library(mvtnorm)
library(MASS)

# Helper: second non-central moment matrix of excess returns (not the standard covariance)
estimateSigma <- function(inSampleReturns, riskFreeReturn)
{
  n_assets       = (dim(inSampleReturns))[1]
  n_observations = (dim(inSampleReturns))[2]
  covMatrix = array(0, dim=c(n_assets, n_assets))
  for(k in 1:n_assets) {
    for(j in 1:n_assets) {
      covMatrix[k,j] = mean(
        (inSampleReturns[k,] - riskFreeReturn) *
        (inSampleReturns[j,] - riskFreeReturn)
      )
    }
  }
  return(covMatrix)
}

riskFreeReturn = 0.02
expRets = c(0.09, 0.09)  # expected returns for the two stocks
s1 = 0.16; s2 = 0.16     # standard deviations
rho = 0.5                 # correlation; try 0.0, 0.5, 1.0 to see diversification effect
covMat <- matrix(c(s1, sqrt(s1*s2)*rho, sqrt(s1*s2)*rho, s2), 2, 2)

# Use a large sample so Sigma converges to the true value
N = 100000
temp  = rmvnorm(n=N, mean=expRets, sigma=covMat)
Sigma <- estimateSigma(t(temp), riskFreeReturn)

# Nekrasov's formula: closed-form optimal fractions
u = (1 + riskFreeReturn) * ginv(Sigma) %*% (expRets - riskFreeReturn)

# Brute-force: enumerate all (f1%, f2%) with f1+f2 <= 100%
PATHLEN = 100   # trades per simulated path
SIMNUM  = 100   # number of Monte Carlo paths
COMBLEN = 0
for(i in 0:100) { for(j in 0:(100-i)) { COMBLEN = COMBLEN + 1 } }
terminalWealth = array(0.0, dim=c(COMBLEN, 3, SIMNUM))

allFracs <- function()
{
  for(simulation in 1:SIMNUM)
  {
    rets = rmvnorm(n=N, mean=expRets, sigma=covMat)
    for(i in 1:PATHLEN)
    {
      if(rets[i, 1] < -0.95) rets[i, 1] = -0.95
      if(rets[i, 2] < -0.95) rets[i, 2] = -0.95
      if(rets[i, 1] > 0.95)  rets[i, 1] = 0.95
      if(rets[i, 2] > 0.95)  rets[i, 2] = 0.95
    }
    idx = 1
    for(i in 0:100) {
      for(j in 0:(100-i)) {
        frac1 = 0.01 * i
        frac2 = 0.01 * j
        capitalInCash = 1.0 - (frac1 + frac2)
        wealth = 1.0
        for(schritt in 1:PATHLEN) {
          wealth = wealth * ((1.0 + rets[schritt,1])*frac1
            + (1.0 + rets[schritt,2])*frac2 + 1.02*capitalInCash)
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
allFracsCompiled <- cmpfun(allFracs)
terminalWealth   <- allFracsCompiled()
scatterplot3d(terminalWealth[,,1])

# Average log-wealth across simulation paths
terminalWealthAveraged = array(0.0, dim=c(COMBLEN, 3, 1))
for(i in 1:COMBLEN)
{
  terminalWealthAveraged[i, 1, 1] = terminalWealth[i, 1, 1]
  terminalWealthAveraged[i, 2, 1] = terminalWealth[i, 2, 1]
  terminalWealthAveraged[i, 3, 1] = mean(log(terminalWealth[i, 3, ]))
}

s3d <- scatterplot3d(terminalWealthAveraged[,,1], angle=120)

# Compare theoretical vs. empirical optimum
teorMaxIdx = which(
  terminalWealthAveraged[,1,1] == round(u[1], 2) &
  terminalWealthAveraged[,2,1] == round(u[2], 2)
)
terminalWealthAveraged[teorMaxIdx, , 1]

realMaxIdx = which.max(terminalWealthAveraged[,3,1])
terminalWealthAveraged[realMaxIdx, , 1]

# Highlight both points on the 3D plot
s3d$points(x=terminalWealthAveraged[realMaxIdx,1,1],
  y=terminalWealthAveraged[realMaxIdx,2,1],
  z=terminalWealthAveraged[realMaxIdx,3,1],
  type="h", col="grey", lwd=2, lty=2)
s3d$points(x=terminalWealthAveraged[teorMaxIdx,1,1],
  y=terminalWealthAveraged[teorMaxIdx,2,1],
  z=terminalWealthAveraged[teorMaxIdx,3,1],
  type="h", col="grey", lwd=2)
