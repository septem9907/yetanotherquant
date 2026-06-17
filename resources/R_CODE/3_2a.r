# Compares the empirical distribution of DAX daily returns to a normal distribution.
# Key finding: real returns have fat tails and are not normally distributed.
#
# Variables n, mu, sigma, daxReturns are used by 3_2b.r and 3_2c.r (now self-contained).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")

n = length(daxReturns)
mu = mean(daxReturns[2:n])    # daxReturns[1] is NA (no previous day), drop it
sigma = sd(daxReturns[2:n])
normalRets = rnorm((n-1), mu, sigma)

par(mfrow=c(2,1))
plot(density(daxReturns[2:n]), lwd=2)         # empirical density
lines(density(normalRets), lwd=2, col="grey") # fitted normal for comparison
qqnorm(daxReturns[2:n])                        # heavy tails appear as S-curve deviation
