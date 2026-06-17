# Estimates historical volatility of Metro AG (MEO.DE) over multiple lookback windows:
# all-time, 1 year, 6 months, 1 quarter, 1 month.
# Shows that short-horizon vol estimates are noisier but more responsive to regime change.

library('quantmod')
getSymbols("MEO.DE")

par(mfrow=c(2,1))
candleChart(MEO.DE, theme='white')
candleChart(MEO.DE, theme='white', subset='last 12 months')

dailyRets = periodReturn(MEO.DE, period='daily')
n = length(dailyRets)

sigmaALL     = round(sd(dailyRets),               4)
sigmaYear    = round(sd(dailyRets[(n-242):n]),    4)
sigmama6Mon  = round(sd(dailyRets[(n-141):n]),    4)
sigmaQuarter = round(sd(dailyRets[(n-70):n]),     4)
sigmaMonth   = round(sd(dailyRets[(n-23):n]),     4)

print(paste(sigmaALL, sigmaYear, sigmama6Mon, sep=" "))
print(paste(sigmaQuarter, sigmaMonth, sep=" "))
