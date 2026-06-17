#get data
library(quantmod)
getSymbols("^GDAXI", from=" 1990-11-26", to="2014-04-26")
daxClose = Cl(GDAXI)
daxReturns = ROC(daxClose, type="discrete")
rets = as.numeric(daxReturns)
len = length(rets)
par(mfrow=c(2,2))
#runs-Test (aka Wald-Wolfowitz-Test)
install.packages("lawstat")
library("lawstat")
runs.test(rets[2:len]) #use all available data for the test
acf( rets[2:len], main="whole sample" ) #plot autocorrelation function
runs.test(rets[2:1001]) #test the 1st thousand
acf( rets[2:1000], main="1st 1000" )
runs.test(rets[2000:3000]) #the 3rd thousand
acf( rets[2000:3000], main="3nd 1000" )
runs.test(rets[3000:4000]) #the 4th (from 2002-11-01 to 2006-10-04)
acf( rets[3000:4000], main="4th 1000" )