# Compares a Gaussian copula to a Clayton copula (heavy lower tail) for a 2-asset portfolio.
# The Clayton copula amplifies joint losses (left-tail dependence), which matters for
# realistic risk modelling — normal correlation underestimates crash co-movement.

library(copula)
library(mvtnorm)
library(MASS)

meanReturns = c(0.08, 0.10)
s1  = 0.09; s2 = 0.16; rho = 0.69
Sigma <- matrix(c(s1, sqrt(s1*s2)*rho, sqrt(s1*s2)*rho, s2), 2, 2)

# Clayton copula: param=2 gives moderate lower-tail dependence
myCop.clayton <- archmCopula(family="clayton", dim=2, param=2)
myMvd <- mvdc(
  copula     = myCop.clayton,
  margins    = c("norm", "norm"),
  paramMargins = list(
    list(mean=meanReturns[1], sd=sqrt(s1)),
    list(mean=meanReturns[2], sd=sqrt(s2))
  )
)

retsClayton = rmvdc(myMvd,  10000)
retsNorm    = mvrnorm(n=10000, mu=meanReturns, Sigma=Sigma)

par(mfrow=c(1,2))
plot(retsNorm)      # elliptical scatter
plot(retsClayton)   # asymmetric: more mass in lower-left (joint crashes)

print(cov(retsNorm))
print(cov(retsClayton))
print(cor(retsNorm))
print(cor(retsClayton))
