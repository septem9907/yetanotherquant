# Sequential trading simulation using the copula-generated return stream from 5_6a.r.
# Groups the 100,000 single-trade returns into blocks of 50, computing terminal
# wealth and max drawdown for each block. Reports the distribution of outcomes.
# Standalone version: runs 5_6a.r's copula simulation internally.

install.packages("copula")
library(copula)
library(tseries)

# --- replicate 5_6a.r to generate the `returns` vector ---
N_SIMULATIONS = 100000
CORR   = 0.31
RET_UP = (22.00 - 19.40) / 19.40
RET_DN = (18.40 - 19.40) / 19.40

tmp <- normalCopula(CORR, dim=10)
x   <- rcopula(tmp, N_SIMULATIONS)

b1  = qbinom(x[,1],  1, 0.5); b2  = qbinom(x[,2],  1, 0.5)
b3  = qbinom(x[,3],  1, 0.5); b4  = qbinom(x[,4],  1, 0.5)
b5  = qbinom(x[,5],  1, 0.5); b6  = qbinom(x[,6],  1, 0.5)
b7  = qbinom(x[,7],  1, 0.5); b8  = qbinom(x[,8],  1, 0.5)
b9  = qbinom(x[,9],  1, 0.5); b10 = qbinom(x[,10], 1, 0.5)

returns = array(0.0, dim=N_SIMULATIONS)
for(i in 1:N_SIMULATIONS)
{
  if(b1[i]  == 0) b1[i]  = RET_DN else b1[i]  = RET_UP
  if(b2[i]  == 0) b2[i]  = RET_DN else b2[i]  = RET_UP
  if(b3[i]  == 0) b3[i]  = RET_DN else b3[i]  = RET_UP
  if(b4[i]  == 0) b4[i]  = RET_DN else b4[i]  = RET_UP
  if(b5[i]  == 0) b5[i]  = RET_DN else b5[i]  = RET_UP
  if(b6[i]  == 0) b6[i]  = RET_DN else b6[i]  = RET_UP
  if(b7[i]  == 0) b7[i]  = RET_DN else b7[i]  = RET_UP
  if(b8[i]  == 0) b8[i]  = RET_DN else b8[i]  = RET_UP
  if(b9[i]  == 0) b9[i]  = RET_DN else b9[i]  = RET_UP
  if(b10[i] == 0) b10[i] = RET_DN else b10[i] = RET_UP
  returns[i] = 0.1 * (b1[i]+b2[i]+b3[i]+b4[i]+b5[i]
    +b6[i]+b7[i]+b8[i]+b9[i]+b10[i])
}
# --- end of 5_6a.r replication ---

N_TRADES = 50
termWealth = array(1.0, dim=(N_SIMULATIONS / N_TRADES))
maxDD      = array(0.0, dim=(N_SIMULATIONS / N_TRADES))
index = 1
trade = 1

while(trade < N_SIMULATIONS)
{
  # Wealth path over a block of N_TRADES consecutive trades
  # Note: wealth is sized N_TRADES; the loop writes wealth[d+1] up to wealth[N_TRADES+1],
  # which R auto-extends, so termWealth captures the last appended element.
  wealth = array(1.0, dim=N_TRADES)
  rets   = returns[trade:(trade + N_TRADES - 1)]
  trade  = trade + N_TRADES
  for(d in 1:N_TRADES)
  {
    wealth[d+1] = wealth[d] * (1 + rets[d])
  }
  termWealth[index] = wealth[N_TRADES]
  maxDD[index]      = (maxdrawdown(wealth))[[1]]
  index = index + 1
}

cgr = log(termWealth)
print(paste("expected cumulative growth rate: ", mean(cgr)))
print(paste("s.d. of cumulative growth rate: ",  sd(cgr)))

par(mfrow=c(2,1))
plot(density(cgr))
plot(density(maxDD))
mean(maxDD)
sd(maxDD)
