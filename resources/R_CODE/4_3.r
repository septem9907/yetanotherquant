# Backtests a dual-MA crossover strategy (MA38 / MA200) on DJ30 stocks
# listed on the Frankfurt exchange (*.F tickers, 1995-2014).
# Signal: buy when short MA crosses above long MA; sell on the reverse.
# Merck (6MK.F) excluded due to data issues.

library(quantmod)

tickers <- c("MMM.F", "ALU.F", "AEC1.F", "SOBA.F",
  "NCB.F", "BCO.F", "CAT1.F", "CHV.F", "CIS.F",
  "CCC3.F", "WDP.F", "DUP.F", "XONA.F", "GEC.F",
  "HWP.F", "HDI.F", "INL.F", "IBM.F", "JNJ.F",
  "CMC.F", "KTF.F", "MDO.F", "MSF.F", "PFE.F",
  "PRG.F", "PA9.F", "UTC1.F", "BAC.F", "WMT.DE")

startDate    = '1995-01-01'
endDate      = '2014-04-30'
MA_DAYS      = 200
MA_DAYS_SHORT = 38
getSymbols(tickers, from=startDate, to=endDate)

N_TICKERS  = length(tickers)
weatlhDiffs = array(0.0, dim=N_TICKERS)

for(i in 1:N_TICKERS)
{
  closePrices = as.numeric(Cl(eval(parse(text=tickers[i]))))
  N_DAYS = length(closePrices)
  MA200  = SMA(closePrices, MA_DAYS)
  MA38   = SMA(closePrices, MA_DAYS_SHORT)

  signal    = "inCash"
  buyPrice  = 0.0
  sellPrice = 0.0
  maWealth  = 1.0

  for(d in (MA_DAYS+1):N_DAYS)
  {
    # Golden cross: short MA crosses above long MA
    if((MA38[d] > MA200[d]) && (signal == "inCash"))
    {
      buyPrice = closePrices[d]
      signal   = "inStock"
    }
    # Death cross: short MA crosses below long MA
    if(((MA38[d] < MA200[d]) || (d == N_DAYS)) && (signal == "inStock"))
    {
      sellPrice = closePrices[d]
      signal    = "inCash"
      maWealth  = maWealth * (sellPrice / buyPrice)
    }
  }

  bhWealth       = closePrices[N_DAYS] / closePrices[(MA_DAYS+1)]
  weatlhDiffs[i] = bhWealth - maWealth
  print(paste(tickers[i], weatlhDiffs[i]))

  filepath = "D:\\BOOK\\images\\chapter4\\MA_crossover_DJ30\\"
  filename <- paste(filepath, tickers[i], ".png")
  png(filename)
  ts.plot(closePrices)
  lines(MA200, col="grey", lwd=2)
  lines(MA38,  col="grey", lwd=2, lty=2)
  dev.off()
}
print(paste("mean wealth Diff: ", mean(weatlhDiffs)))
