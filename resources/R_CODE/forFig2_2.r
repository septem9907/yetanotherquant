# Kernel density comparison: binomial coin-toss outcomes vs. fitted normal.
# Shows how the binomial distribution resembles a normal at moderate N.

N_TOSSES = 10
N_SIMULATIONS = 200
coinTosses = rbinom(N_SIMULATIONS, N_TOSSES, 0.55)
mu = mean(coinTosses)
sigma = sd(coinTosses)
normalRV = rnorm(N_SIMULATIONS, mu, sigma)
plot(density(coinTosses), lwd=2)
lines(density(normalRV), lwd=2, col="grey")
