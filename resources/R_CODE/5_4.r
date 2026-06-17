# Estimates "implied drift": the daily drift that makes simulated TP/SL hit rates
# match the analyst's forecast probabilities. Analogous to implied volatility for options.
# Example: Metro AG buy at 29.79, TP=35.40 (+18.8%), SL=26.40 (-11.4%), 50/50 expected.

impliedDrift <- function(buyPrice, TP, SL, TPprob, SLprob, N_DAYS, Vola)
{
  targetUp   = TP / buyPrice
  targetDown = SL / buyPrice
  N_STEPS       = 100
  N_SIMULATIONS = 100000
  drifts = seq(1, N_STEPS) / 10000  # try drifts 0.01% to 0.10% per day

  tpCounts      = array(0, N_STEPS)
  slCounts      = array(0, N_STEPS)
  resultsArray  = array(0, N_STEPS)

  for(d in 1:N_STEPS)
  {
    for(i in 1:N_SIMULATIONS)
    {
      price = 1.0
      rets  = rnorm(N_DAYS, drifts[d], Vola)
      for(j in 1:N_DAYS)
      {
        price = price * (1 + rets[j])
        if(price >= targetUp) {
          tpCounts[d] = tpCounts[d] + 1
          break
        } else if(price <= targetDown) {
          slCounts[d] = slCounts[d] + 1
          break
        }
      }
    }
    tpCounts[d] = tpCounts[d] / N_SIMULATIONS
    slCounts[d] = slCounts[d] / N_SIMULATIONS
  }

  # Find the drift that minimises the distance from target probabilities
  resultsArray = abs(tpCounts - TPprob) + abs(slCounts - TPprob)
  optimalDriftId = which.min(resultsArray)
  print(paste("implied drift: ", drifts[optimalDriftId]))
  print(paste("empirical TP prob.: ",  tpCounts[optimalDriftId]))
  print(paste("emprirical SL prob.: ", slCounts[optimalDriftId]))
}

library(compiler)
impliedDriftCompiled <- cmpfun(impliedDrift)
# MEO.DE: buy=29.79, TP=35.40, SL=26.40, 50% TP prob, 141 trading days, daily vol=1.88%
impliedDriftCompiled(29.79, 35.4, 26.4, 0.5, 0.5, 141, 0.01883767)
