#run after R-code 3.3a
w30 = array(1.0, dim=n)
w50 = array(1.0, dim=n)
w93 = array(1.0, dim=n)
w100 = array(1.0, dim=n)
for( m in 2:n )
{
  ret = daxMonthlyRets[m-1]
  w100[m] = w100[m-1] * (1 + ret)
  w30[m] = w30[m-1] * (0.3*(ret - r) + (1 + r))
  w50[m] = w50[m-1] * (0.5*(ret - r) + (1 + r))
  w93[m] = w93[m-1] * (0.93*(ret - r) + (1 + r))
}
ts.plot(w100)
lines(w30, col="grey", lwd=2, lty=2)
lines(w50, col="black", lwd=2, lty=2)
lines(w93, col="grey", lwd=2)