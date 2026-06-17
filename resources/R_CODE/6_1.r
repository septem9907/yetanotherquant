####option out-of the money + vola change (SG32QT)
#option expires on 14.12.18 (in 4 years) and is deeply-out-of the money
#NB! We model with change of both stock price and implied volatility
install.packages("RQuantLib")
library("RQuantLib")
priceChangeInEuroCents = array(0.0, dim=401)
price1 = array(0.0, dim=401)
delta1 = array(0.0, dim=401)
gamma1 = array(0.0, dim=401)
vega1 = array(0.0, dim=401)
for(i in -200:200)
{
  #type, underlying price, strike, dividendYield, riskFreeRate, maturity, volatility
  #note that with dividendYield=0.0 we can treat this American call option as
  #Europian (which accelerates the computation due to a closed-from solution)
  op=EuropeanOption("call", 23.81+i/100 , 60.0, 0.0, 0.0057, 4, 0.37-i/10000)
  priceChangeInEuroCents[i+201] = i
  price1[i+201] = op$value
  delta1[i+201] = op$delta
  gamma1[i+201] = op$gamma
  vega1[i+201] = op$vega
}

#now the same one year later
price2 = array(0.0, dim=401)
delta2 = array(0.0, dim=401)
gamma2 = array(0.0, dim=401)
vega2 = array(0.0, dim=401)
for(i in -200:200)
{
  #type, underlying price, strike, dividenYield, riskFreeRate, maturity, volatility
  op=EuropeanOption("call", 23.81+i/100 , 60.0, 0.0, 0.0057, 3, 0.37-i/10000)
  priceChangeInEuroCents[i+201] = i
  price2[i+201] = op$value
  delta2[i+201] = op$delta
  gamma2[i+201] = op$gamma
  vega2[i+201] = op$vega
}

par(mfrow=c(2,2))
tmp = c(price1, price2)
plot(priceChangeInEuroCents, price1, ylim=c( min(tmp), max(tmp) ) )
lines(priceChangeInEuroCents, price2)
tmp = c(delta1, delta2)
plot(priceChangeInEuroCents, delta1, ylim=c( min(tmp), max(tmp) ) )
lines(priceChangeInEuroCents, delta2)
tmp = c(gamma1, gamma2)
plot(priceChangeInEuroCents, gamma1, ylim=c( min(tmp), max(tmp) ) )
lines(priceChangeInEuroCents, gamma2)
tmp = c(vega1, vega2)
plot(priceChangeInEuroCents, vega1, ylim=c( min(tmp), max(tmp) ) )
lines(priceChangeInEuroCents, vega2)