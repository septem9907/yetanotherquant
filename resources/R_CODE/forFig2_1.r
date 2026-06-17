# Histogram of coin-toss outcomes overlaid with a fitted normal curve.
# Illustrates the Central Limit Theorem: binomial approaches normal as N grows.
# Coin is slightly biased (p=0.55).

N_TOSSES = 10
N_SIMULATIONS = 1000
coinTosses = rbinom(N_SIMULATIONS, N_TOSSES, 0.55)
h <- hist(coinTosses, breaks=10, col="grey",
  xlab="Number of Heads",
  main="Histogram with Normal Curve")
# Overlay a normal density scaled to the histogram bin counts
xfit <- seq(min(coinTosses), max(coinTosses), length=1000)
yfit <- dnorm(xfit, mean=mean(coinTosses), sd=sd(coinTosses))
yfit <- yfit * diff(h$mids[1:2]) * length(coinTosses)
lines(xfit, yfit, col="black", lwd=2)
