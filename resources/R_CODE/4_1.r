# Tests DAX daily returns for randomness using the Wald-Wolfowitz runs test and ACF.
# Splits the full history into sub-periods to check whether the market's random-walk
# property is stable over time (it is not: some sub-periods show significant autocorrelation).

library(quantmod)
getSymbols("^GDAXI", from=" 1990-11-26", to="2014-04-26")
daxClose  = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")
rets = as.numeric(daxReturns)
len  = length(rets)

install.packages("lawstat")
library("lawstat")

par(mfrow=c(2,2))
runs.test(rets[2:len])             # full sample randomness test
acf(rets[2:len], main="whole sample")

runs.test(rets[2:1001])            # 1st thousand trading days
acf(rets[2:1000], main="1st 1000")

runs.test(rets[2000:3000])         # 3rd thousand
acf(rets[2000:3000], main="3nd 1000")

runs.test(rets[3000:4000])         # 4th thousand (~2002-11 to 2006-10)
acf(rets[3000:4000], main="4th 1000")
