# Illustrates diversification: two banks (Commerzbank, Deutsche Bank) are highly
# correlated, while Fresenius (healthcare) is nearly uncorrelated with Deutsche Bank.
# Scatter plots and Pearson correlations confirm the relationship.

library(quantmod)
tickers   = c("CBK.DE", "DBK.DE", "FRE.DE")
startDate = '2004-01-01'
endDate   = '2014-04-30'
getSymbols(tickers, from=startDate, to=endDate)

retsFresenius    = as.numeric(periodReturn(FRE.DE, period='daily'))
retsDeutscheBank = as.numeric(periodReturn(DBK.DE, period='daily'))
retsCommerzbank  = as.numeric(periodReturn(CBK.DE, period='daily'))

par(mfrow=c(1,2))
plot(retsCommerzbank, retsDeutscheBank)
abline(lm(retsCommerzbank ~ retsDeutscheBank), lwd=2)  # regression line
plot(retsFresenius, retsDeutscheBank)
abline(lm(retsFresenius ~ retsDeutscheBank), lwd=2)

cor(retsFresenius,   retsDeutscheBank)  # ~0.1: low
cor(retsCommerzbank, retsDeutscheBank)  # ~0.8: high
