#get data
library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")
#qqplot + return density and normal density together
n = length(daxReturns)
mu = mean(daxReturns[2:n]) #first array value is NA, drop it!
sigma = sd(daxReturns[2:n])
normalRets = rnorm((n-1), mu, sigma)
par(mfrow=c(2,1))
plot(density(daxReturns[2:n]), lwd=2)
lines(density(normalRets), lwd=2, col="grey")
qqnorm(daxReturns[2:n])