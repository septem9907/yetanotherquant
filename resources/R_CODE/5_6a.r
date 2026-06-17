install.packages("copula")
library(copula)
N_SIMULATIONS = 100000
CORR = 0.31
RET_UP = (22.00 - 19.40) / 19.40 # = 0.1340
RET_DN = (18.40 - 19.40) / 19.40 # = -0.0515
tmp <- normalCopula( CORR, dim=10 )
x <- rcopula(tmp, N_SIMULATIONS)
b1 = qbinom(x[,1], 1, 0.5)
b2 = qbinom(x[,2], 1, 0.5)
b3 = qbinom(x[,3], 1, 0.5)
b4 = qbinom(x[,4], 1, 0.5)
b5 = qbinom(x[,5], 1, 0.5)
b6 = qbinom(x[,6], 1, 0.5)
b7 = qbinom(x[,7], 1, 0.5)
b8 = qbinom(x[,8], 1, 0.5)
b9 = qbinom(x[,9], 1, 0.5)
b10 = qbinom(x[,10], 1, 0.5)
returns = array(0.0, dim=N_SIMULATIONS)
for( i in 1:N_SIMULATIONS )
{
  if (b1[i] == 0) b1[i] = RET_DN else b1[i] = RET_UP
  if (b2[i] == 0) b2[i] = RET_DN else b2[i] = RET_UP
  if (b3[i] == 0) b3[i] = RET_DN else b3[i] = RET_UP
  if (b4[i] == 0) b4[i] = RET_DN else b4[i] = RET_UP
  if (b5[i] == 0) b5[i] = RET_DN else b5[i] = RET_UP
  if (b6[i] == 0) b6[i] = RET_DN else b6[i] = RET_UP
  if (b7[i] == 0) b7[i] = RET_DN else b7[i] = RET_UP
  if (b8[i] == 0) b8[i] = RET_DN else b8[i] = RET_UP
  if (b9[i] == 0) b9[i] = RET_DN else b9[i] = RET_UP
  if (b10[i] == 0) b10[i] = RET_DN else b10[i] = RET_UP

  returns[i] = 0.1 * (b1[i]+b2[i]+b3[i]+b4[i]
    +b5[i]+b6[i]+b7[i]+b8[i]+b9[i]+b10[i])
}
#check that all correlations are about 0.2
mRets <- cbind( b1, b2, b3, b4, b5, b6, b7, b8, b9, b10 )
print(round(cor(mRets), 2))
plot(density(returns))
print(paste("mean return: ", mean(returns)))
print(paste("s.d. of returns: ", sd(returns)))