# Prices a deeply out-of-the-money European call option (SG32QT) and computes
# its Greeks (delta, gamma, vega) across a ±2 EUR range of underlying prices.
# Models simultaneous change in underlying price AND implied volatility
# (vol declines as price rises, capturing the leverage/fear effect).
# Then repeats the calculation one year later (maturity shrinks from 4 to 3 years).
#
# Option details: underlying=23.81, strike=60.00, maturity=4yr, vol=37%, rfr=0.57%

install.packages("RQuantLib")
library("RQuantLib")

priceChangeInEuroCents = array(0.0, dim=401)
price1 = array(0.0, dim=401)
delta1 = array(0.0, dim=401)
gamma1 = array(0.0, dim=401)
vega1  = array(0.0, dim=401)

for(i in -200:200)
{
  # vol decreases by 0.01% per 1 cent rise in underlying (inverse vol-price relationship)
  op = EuropeanOption("call", 23.81+i/100, 60.0, 0.0, 0.0057, 4, 0.37-i/10000)
  priceChangeInEuroCents[i+201] = i
  price1[i+201] = op$value
  delta1[i+201] = op$delta
  gamma1[i+201] = op$gamma
  vega1[i+201]  = op$vega
}

# Same option one year later: maturity 3 instead of 4
price2 = array(0.0, dim=401)
delta2 = array(0.0, dim=401)
gamma2 = array(0.0, dim=401)
vega2  = array(0.0, dim=401)

for(i in -200:200)
{
  op = EuropeanOption("call", 23.81+i/100, 60.0, 0.0, 0.0057, 3, 0.37-i/10000)
  priceChangeInEuroCents[i+201] = i
  price2[i+201] = op$value
  delta2[i+201] = op$delta
  gamma2[i+201] = op$gamma
  vega2[i+201]  = op$vega
}

par(mfrow=c(2,2))
tmp = c(price1, price2)
plot(priceChangeInEuroCents, price1, ylim=c(min(tmp), max(tmp)))
lines(priceChangeInEuroCents, price2)
tmp = c(delta1, delta2)
plot(priceChangeInEuroCents, delta1, ylim=c(min(tmp), max(tmp)))
lines(priceChangeInEuroCents, delta2)
tmp = c(gamma1, gamma2)
plot(priceChangeInEuroCents, gamma1, ylim=c(min(tmp), max(tmp)))
lines(priceChangeInEuroCents, gamma2)
tmp = c(vega1, vega2)
plot(priceChangeInEuroCents, vega1, ylim=c(min(tmp), max(tmp)))
lines(priceChangeInEuroCents, vega2)
