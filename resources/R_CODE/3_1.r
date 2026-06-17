install.packages("quantmod") #do it only by the 1st run
library(quantmod)
getSymbols("^GDAXI", from="1900-01-01")
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")
par(mfrow=c(2,1))
plot(daxClose)
plot(daxReturns)