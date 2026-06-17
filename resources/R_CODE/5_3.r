# Computes the correlation matrix of three assets: Metro AG (MEO.DE), Südzucker (SZU.DE),
# and iShares Silver ETF (SLV). Used to assess portfolio diversification benefits.
# Variables retsMEO, retsSZU, retsMatrix, n are used by 5_5a.r and 5_5b.r (now self-contained).

library(quantmod)
getSymbols(c("MEO.DE", "SZU.DE", "SLV"), from="2013-05-01", to="2014-05-13")

retsMEO = as.numeric(periodReturn(MEO.DE, period='daily'))
retsSZU = as.numeric(periodReturn(SZU.DE, period='daily'))
retsSLV = as.numeric(periodReturn(SLV,    period='daily'))

# Align to the shortest series in case Yahoo data lengths differ
n = min(length(retsMEO), length(retsSZU), length(retsSLV))
retsMatrix = array(0.0, dim=c(n, 3))
retsMatrix[,1] = retsMEO[1:n]
retsMatrix[,2] = retsSZU[1:n]
retsMatrix[,3] = retsSLV[1:n]

corrMat = cor(retsMatrix)
print(round(corrMat, 2))
