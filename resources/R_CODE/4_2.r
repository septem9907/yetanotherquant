# Backtests a 200-day moving-average trend-following strategy on all 30 DAX stocks
# (1995-2014). Signal: buy when price > MA200, sell when price < MA200.
# Compares strategy wealth to buy-and-hold wealth for each stock.
# Saves individual charts to D:\BOOK\images\chapter4\MA200_DAX\ (adjust path as needed).

library(quantmod)

tickers <- c("ADS.DE", "ALV.DE", "BAS.DE", "BAYN.DE",
  "BMW.DE", "BEI.DE", "CBK.DE", "DAI.DE", "DBK.DE",
  "DB1.DE", "LHA.DE", "DPW.DE", "DTE.DE", "EOAN.DE",
  "FME.DE", "FRE.DE", "HEI.DE", "HEN3.DE", "IFX.DE",
  "SDF.DE", "LIN.DE", "MAN.DE", "MRK.DE", "MEO.DE",
  "MUV2.DE", "RWE.DE", "SAP.DE", "SIE.DE", "TKA.DE",
  "VOW3.DE")

startDate = '1995-01-01'
endDate   = '2014-04-30'
MA_DAYS   = 200
getSymbols(tickers, from=startDate, to=endDate)

N_TICKERS  = length(tickers)
weatlhDiffs = array(0.0, dim=N_TICKERS)

for(i in 1:N_TICKERS)
{
  closePrices = as.numeric(Cl(eval(parse(text=tickers[i]))))
  N_DAYS = length(closePrices)
  MA     = SMA(closePrices, MA_DAYS)

  signal    = "inCash"
  buyPrice  = 0.0
  sellPrice = 0.0
  maWealth  = 1.0

  for(d in (MA_DAYS+1):N_DAYS)
  {
    if((closePrices[d] > MA[d]) && (signal == "inCash"))
    {
      buyPrice = closePrices[d]
      signal   = "inStock"
    }
    if(((closePrices[d] < MA[d]) || (d == N_DAYS)) && (signal == "inStock"))
    {
      sellPrice = closePrices[d]
      signal    = "inCash"
      maWealth  = maWealth * (sellPrice / buyPrice)
    }
  }

  bhWealth        = closePrices[N_DAYS] / closePrices[(MA_DAYS+1)]
  weatlhDiffs[i]  = bhWealth - maWealth
  print(paste(tickers[i], weatlhDiffs[i]))

  filepath = "D:\\BOOK\\images\\chapter4\\MA200_DAX\\"
  filename <- paste(filepath, tickers[i], ".png")
  png(filename)
  ts.plot(closePrices)
  lines(MA, col="grey", lwd=2)
  dev.off()
}
print(paste("mean wealth Diff: ", mean(weatlhDiffs)))
