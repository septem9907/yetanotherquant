# Analyses DAX monthly returns: time series, QQ-plot, and density vs. normal.
# Monthly aggregation reduces fat-tail effects compared to daily data (CLT).
# Standalone version: loads data internally (originally required 3_2a.r).

library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")

daxMonthlyRets = periodReturn(GDAXI, period='monthly')
n = length(daxMonthlyRets)
mu = mean(daxMonthlyRets)
sigma = sd(daxMonthlyRets)
normalRets = rnorm(n, mu, sigma)

par(mfrow=c(3,1))
plot(daxMonthlyRets)
qqnorm(daxMonthlyRets)
plot(density(daxMonthlyRets), lwd=2)
lines(density(normalRets), lwd=2, col="grey")
