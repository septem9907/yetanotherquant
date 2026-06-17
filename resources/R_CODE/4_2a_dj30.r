# NB! Bug fix note from 2014-11-29: the original 4_2.r had the MA signal reversed
# (it was buying below MA, not above). After fixing, MA200 still beats buy&hold on
# DAX (see 4_2.r) but does NOT beat it on Dow Jones 30 (this script).
#
# Backtests MA200 on US Dow Jones 30 stocks (US tickers, 1995-2014).

library(quantmod)

tickers <- c("GE", "MRK", "XOM", "CVX", "MMM", "UNH", "V", "NTC", "PFE", "NKE",
  "DD", "TRV", "BA", "JNJ", "UTX", "IBM", "HD", "MSFT", "CAT", "GS",
  "WMT", "VZ", "KO", "PG", "CSCO", "MCD", "AXP", "DIS", "T", "JPM")

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

  bhWealth       = closePrices[N_DAYS] / closePrices[(MA_DAYS+1)]
  weatlhDiffs[i] = bhWealth - maWealth
  print(paste(tickers[i], weatlhDiffs[i]))

  filepath = "D:\\BOOK\\images\\chapter4\\MA200_DJ30\\"
  filename <- paste(filepath, tickers[i], ".png")
  png(filename)
  ts.plot(closePrices)
  lines(MA, col="grey", lwd=2)
  dev.off()
}
print(paste("mean wealth Diff: ", mean(weatlhDiffs)))
