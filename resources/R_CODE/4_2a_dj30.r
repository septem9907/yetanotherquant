##NB! On 29.11.2014 an error was found: the MA strategy was actually reversed,
#it bought if stockPrice was less than MA and sold if stockPrice > MA
#
#After I fixed it I found out that the MA200 strategy works well on German
#Market (DAX), as the script 4_2.r demonstrates.
#
#However, it does not beat buy&hold on US Market (DJ30), as this script shows

library(quantmod)
#all 30 stocks from DOW
tickers <-c("GE", "MRK", "XOM", "CVX", "MMM", "UNH", "V", "NTC", "PFE", "NKE",
            "DD", "TRV", "BA", "JNJ", "UTX", "IBM", "HD", "MSFT", "CAT", "GS",
            "WMT", "VZ", "KO", "PG", "CSCO", "MCD", "AXP", "DIS", "T", "JPM")
#play with different combinations of these parameters!
startDate = '1995-01-01'
endDate = '2014-04-30'
MA_DAYS = 200
getSymbols(tickers, from=startDate, to=endDate)
N_TICKERS = length(tickers)
weatlhDiffs = array(0.0, dim=N_TICKERS)
for( i in 1:N_TICKERS)
{
  closePrices = Cl(eval(parse(text=tickers[i])))
  closePrices = as.numeric(closePrices)
  N_DAYS = length(closePrices)
  MA = SMA( closePrices, MA_DAYS )
  signal = "inCash"
  buyPrice = 0.0
  sellPrice = 0.0
  maWealth = 1.0
  for(d in (MA_DAYS+1):N_DAYS)
  {
    #buy if Stockprice > MA & if not bought yet
    if((closePrices[d] > MA[d]) && (signal == "inCash"))
    {
      buyPrice = closePrices[d]
      signal = "inStock"
    }
    #sell if (Stockprice < MA OR endDate reached)
    # & there is something to sell
    if(((closePrices[d] < MA[d]) || (d == N_DAYS)) && (signal == "inStock"))
    {
      sellPrice = closePrices[d]
      signal = "inCash"
      maWealth = maWealth * (sellPrice / buyPrice)
    }
  }
  bhWealth = closePrices[N_DAYS] / closePrices[(MA_DAYS+1)]
  weatlhDiffs[i] = bhWealth - maWealth
  print(paste(tickers[i], weatlhDiffs[i]))
  #redirect graphical output to a file
  filepath = "D:\\BOOK\\images\\chapter4\\MA200_DJ30\\"
  filename <- paste(filepath, tickers[i],".png")
  png(filename)
  ts.plot( closePrices )
  lines( MA, col="grey", lwd=2)
  dev.off()
}
print(paste("mean wealth Diff: ", mean(weatlhDiffs)))