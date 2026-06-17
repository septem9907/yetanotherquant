# Downloads DAX index data from Yahoo Finance and plots price and daily returns.
# install.packages("quantmod")  # run once if not installed
library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")  # Yahoo Finance will use earliest available date
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")  # simple (arithmetic) daily returns
par(mfrow=c(2,1))
plot(daxClose)
plot(daxReturns)
