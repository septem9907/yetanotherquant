N_TOSSES = 10
N_SIMULATIONS = 200
coinTosses = rbinom(N_SIMULATIONS, N_TOSSES, 0.55)
mu = mean(coinTosses)
sigma = sd(coinTosses)
normalRV = rnorm(N_SIMULATIONS, mu, sigma)
plot(density(coinTosses), lwd=2)
lines(density(normalRV), lwd=2, col="grey")