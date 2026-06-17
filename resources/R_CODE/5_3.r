library(quantmod)
getSymbols(c("MEO.DE", "SZU.DE", "SLV"), from="2013-05-01", to="2014-05-13")
retsMEO = as.numeric(periodReturn(MEO.DE, period='daily'))
retsSZU = as.numeric(periodReturn(SZU.DE, period='daily'))
retsSLV = as.numeric(periodReturn(SLV, period='daily'))
n = min(length(retsMEO), length(retsSZU), length(retsSLV))
retsMatrix = array(0.0, dim=c(n, 3))
retsMatrix[,1] = retsMEO[1:n]
retsMatrix[,2] = retsSZU[1:n]
retsMatrix[,3] = retsSLV[1:n]
corrMat = cor(retsMatrix)
print(round(corrMat,2))