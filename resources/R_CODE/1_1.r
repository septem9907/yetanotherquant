#exact value
print("Exact Solution")
1 - pbinom(59, 100, 0.5)
#approximate value by Monte Carlo simulation
tosses = rbinom(100000, 100, 0.5)
nSuccessfulOutcomes = 0
for(i in 1:100000)
{
if(tosses[i] >=60 )
nSuccessfulOutcomes = nSuccessfulOutcomes + 1
}
print("Approximate Solution")
nSuccessfulOutcomes / 100000