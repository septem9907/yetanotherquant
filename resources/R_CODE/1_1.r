# Probability that a fair coin (p=0.5) lands heads >= 60 times in 100 tosses.
# Demonstrates exact binomial vs. Monte Carlo approximation.

print("Exact Solution")
1 - pbinom(59, 100, 0.5)  # P(X >= 60) = 1 - P(X <= 59)

# Monte Carlo: simulate 100,000 experiments of 100 coin flips each
tosses = rbinom(100000, 100, 0.5)
nSuccessfulOutcomes = 0
for(i in 1:100000)
{
  if(tosses[i] >= 60)
    nSuccessfulOutcomes = nSuccessfulOutcomes + 1
}
print("Approximate Solution")
nSuccessfulOutcomes / 100000
