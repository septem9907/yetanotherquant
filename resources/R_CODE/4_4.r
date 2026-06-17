library(quantmod)
getSymbols("^GDAXI", from="1900-01-01", to="2014-04-30")
monthlyData <- to.monthly(GDAXI)
monthlyReturns <- ClCl(monthlyData)
monthlyReturns[1] <- 0.0
monthIndex <- as.double(format(index(monthlyReturns),'%m'))
tmpRet<-as.double(monthlyReturns)
tmpMon<-as.numeric(monthIndex)
tmp<-data.frame(Return=tmpRet, Month=tmpMon)
tmp$Month = factor(tmp$Month, labels = c("Jan", "Feb",
  "Mar", "Apr", "May", "Jun", "Jul",
  "Aug", "Sep", "Oct", "Nov", "Dec"))
boxplot(Return~Month, data=tmp)
abline(h=0, col="grey")