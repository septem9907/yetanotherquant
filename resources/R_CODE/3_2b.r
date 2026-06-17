#... run after running 3.2a otherwise it will not work
cap = 3 * sd(daxReturns[2:n])
capRets = array(0.0, dim=0)
for( i in 2:n )
{
  if( abs(daxReturns[i]) < cap )
  {
    capRets = c(capRets, daxReturns[i])
  }
}
qqnorm(capRets)
print( length(capRets) / length(daxReturns[2:n]) )