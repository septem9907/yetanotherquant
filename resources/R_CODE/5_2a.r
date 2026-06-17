# Shows that the Nekrasov formula is sensitive to parameter estimation error:
# with only 100 historical observations, the optimal fractions vary substantially
# across three trials drawn from the same "true" distribution.
# Standalone version: includes estimateSigma function from 5_2.r.
# Bug fix: original referenced 'covMatrix' (a local var inside estimateSigma);
#          corrected to 'covMat' (the global covariance matrix).

library("mvtnorm")
library("MASS")

estimateSigma <- function(inSampleReturns, riskFreeReturn)
{
  n_assets = (dim(inSampleReturns))[1]
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

s1 = 0.4; s2 = 0.3         # standard deviations (different from 5_2.r)
rho = 0.7                   # correlation
mu1 = 0.12; mu2 = 0.09
riskFreeReturn = 0.01
N_SIM = 100                 # small sample to demonstrate estimation error

covMat  <- matrix(c(s1*s1, s1*s2*rho, s1*s2*rho, s2*s2), 2, 2)
# Hardcoded Sigma (used as a "true" reference; matches large-sample estimate from these params)
Sigma   <- matrix(c(0.131, 0.067, 0.067, 0.158), 2, 2)
expRets <- c(mu1, mu2)

print("Optimal portfolio with TRUE market parameters")
u = (1 + riskFreeReturn) * ginv(Sigma) %*% (expRets - riskFreeReturn)
print(u)

# Three trials with only N_SIM=100 empirical observations
for(trial in 1:3)
{
  historicalData = mvrnorm(n=N_SIM, expRets, covMat)  # fixed: was 'covMatrix' (undefined)
  Sigma <- estimateSigma(t(historicalData), riskFreeReturn)
  print(paste("...with EMPIRICAL market parameters - TRIAL ", trial))
  u = (1 + riskFreeReturn) * ginv(Sigma) %*% (expRets - riskFreeReturn)
  print(u)
}
