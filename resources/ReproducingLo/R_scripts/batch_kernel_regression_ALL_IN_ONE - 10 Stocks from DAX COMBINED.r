#Script to generate normalized combined returns and proceed with KS-test
#for the following stock from DAX:
#Adidas
#Allianz
#Daimler
#Deutsche Bank
#Deutsche Telekom
#Heidelberger Zement
#Henkel
#Merck
#RWE
#ThyssenKrupp
#
#Graphical output and accounting is disabled and bandwidthFactor is alway 1  
#to reduce computational time (about 5 hours on 2.80Hz processor). 





le <- 35 #35 days: window length according to Lo et al
d <- 3   #lag parameter to allow a pattern to complete: 3 days according to Lo et al 
bandwidthFactor = 1.0 # Lo et all multiply optimal bandwidth h with factor 0.3


###############################################################################


findPattern <- function(pattern)
{
  patternCompletedAt <- vector("integer") #trading days on which the considered pattern completed
  lastExtremumDetected <- vector("integer") #day on which the last extremum falls
  
  cursor <- 1 #beginn of the timeframe (i.e. window) in question, runs from 1 to T-le-d 
  while( cursor < length(TradingDay)-(le+d) ) 
  {
    tradeDay <- c(1:(le+d))
    stockprice <-vector("integer", length=(le+d))
    for (i in cursor:(cursor+(le+d-1)))
        stockprice[i+1-cursor] = Close[i] #we consider the daily stock prices
       
    #nw <- npreg(stockprice~tradeDay)
    #m <- npreg(stockprice~tradeDay, bws=nw$bw*bandwidthFactor)
    m <- npreg(stockprice~tradeDay)
    #summary(m)
    
    #the vector "extrema" contains alternating local extrema: {...min,max,min,max...} 
    maxmin<-msExtrema(as.vector(fitted(m)))
    extremaVector<-vector("integer")
    for(j in 1:length(maxmin$index.max))
    {
      if(maxmin$index.max[j])
        extremaVector<-append(extremaVector, j)
        
      if(maxmin$index.min[j])
        extremaVector<-append(extremaVector, j)
  
    }
      
    #filenumber<-toString(cursor)
    #fileindex<-paste(pattern, filenumber)
    #filename <- paste("D:\\BOOK\\WEBSITE\\ReproducingLo\\R_scripts\\graphs\\",fileindex,".png")
    #png(filename)
  
    if ( pattern=="TTOP" )
      p<-findTTOP(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="TBOT" )
      p<-findTBOT(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="BTOP" )
      p<-findBTOP(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="BBOT" )
      p<-findBBOT(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="HS" )
      p<-findHS(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="IHS" )
      p<-findIHS(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="RTOP" )
      p<-findRTOP(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="RBOT" )
      p<-findRBOT(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="DTOP" )
      p<-findDTOP(as.vector(fitted(m)), extremaVector, maxmin)
    else if ( pattern=="DBOT" )
      p<-findDBOT(as.vector(fitted(m)), extremaVector, maxmin)
 

    if( length(p) == 5 && (!(pattern=="DTOP" || pattern=="DBOT")))
    {
      #plot(m, ylim=range(stockprice))  #ylim=range(stockprice) ensures we have all empirical data plotted                                  
      #points(stockprice) #plot empirical data
      #x<-c( p[1], p[2], p[3], p[4], p[5] )
      #y<-c( stockprice[p[1]], stockprice[p[2]], stockprice[p[3]], stockprice[p[4]] ,stockprice[p[5]]  )
      #lines(x,y, lwd=3.5) #sketch pattern
      
      patternCompletedAt <- append(patternCompletedAt, (p[5]+cursor))
      lastExtremumDetected <- append(lastExtremumDetected, (cursor+(le+d-1)))
                   
    }
    else if( (length(p) == 2) && (pattern=="DTOP" || pattern=="DBOT") )
    {
      #plot(m, ylim=range(stockprice))  #ylim=range(stockprice) ensures we have all empirical data plotted
      #points(stockprice) #plot empirical data
      #x<-c( p[1], p[2] )
      #y<-c( stockprice[p[1]], stockprice[p[2]]  )
      #lines(x,y, lwd=3.5) #sketch pattern - connect two tops (or bottoms)

      patternCompletedAt <- append(patternCompletedAt, (p[2]+cursor))
      lastExtremumDetected <- append(lastExtremumDetected, (cursor+(le+d-1)))  
    }
    #dev.off() 
   
    cursor = (cursor + 1)  #shift window 1 day forward
  }
  
  print("-----------------------------------------------------------------")
  print(pattern)
  print("-----------------------------------------------------------------")
  
  print("pattern completed at day")
  for(i in 1:length(patternCompletedAt) )
    print(patternCompletedAt[i])
  
  print("pattern detected at day")  
  for(i in 1:length(lastExtremumDetected) )
    print(lastExtremumDetected[i])
    
  
  #remove duplicates of recognized patterns
  patternDetectedAtUnique <- vector("integer")
  patternDetectedAtUnique <- append(patternDetectedAtUnique, lastExtremumDetected[1])
  for(i in 2:length(lastExtremumDetected) )
  {
    if( lastExtremumDetected[i] != (lastExtremumDetected[i-1] + 1) )
      patternDetectedAtUnique <- append(patternDetectedAtUnique, lastExtremumDetected[i])   
  }
  print("pattern detected at day - UNIQUE")
  for(i in 1:length(patternDetectedAtUnique) )
    print(patternDetectedAtUnique[i])
  
  
  #determine one-day returns after pattern completion
  returnsAfterPattern <- vector("numeric")
  print("RETURNS AFTER PATTERN COMPLETION")
  for(i in 1:length(patternDetectedAtUnique) )
  {
    ret <- (Close[(patternDetectedAtUnique[i]+1)] - Close[patternDetectedAtUnique[i]]) / Close[patternDetectedAtUnique[i]]
    returnsAfterPattern <-append(returnsAfterPattern, ret)
    print(ret)
  }
  
  #compare returns after pattern with unconditional returns
  returnsUnconditional <- vector("numeric")
  for(i in 2:(length(Close)-1))
  {
    retUncond <- (Close[i] - Close[i-1]) / Close[i-1] 
    returnsUnconditional <- append(returnsUnconditional, retUncond)
  }  
    
  #normalize returns
  returnsAfterPatternNormalized <- (returnsAfterPattern - mean(returnsAfterPattern)) / sd(returnsAfterPattern) 
  returnsUnconditionalNormalized <- (returnsUnconditional - mean(returnsUnconditional)) / sd(returnsUnconditional)
    
  kstestOf_NON_normalized <- ks.test(returnsUnconditional, returnsAfterPattern)
  kstestOfnormalized <- ks.test(returnsUnconditionalNormalized, returnsAfterPatternNormalized)
  
  print(kstestOf_NON_normalized)
  print(kstestOfnormalized)
  
  filename <- paste("D:\\BOOK\\WEBSITE\\ReproducingLo\\R_scripts\\qqplots\\",pattern,".png")
  png(filename)
  qqplot(returnsUnconditional, returnsAfterPattern)
  dev.off() 
  
  print("number of [unique] occurance of")
  print(pattern)
  print( length(returnsAfterPattern) ) 
  
  
  #combine data to increase power of goodness-of-fit test
     if ( pattern=="TTOP" )
      TTOPNormalizedGlobal <<- append(TTOPNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="TBOT" )
      TBOTNormalizedGlobal <<- append(TBOTNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="BTOP" )
      BTOPNormalizedGlobal <<- append(BTOPNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="BBOT" )
      BBOTNormalizedGlobal <<- append(BBOTNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="HS" )
      HSNormalizedGlobal <<- append(HSNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="IHS" )
      IHSNormalizedGlobal <<- append(IHSNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="RTOP" )
      RTOPNormalizedGlobal <<- append(RTOPNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="RBOT" )
      RBOTNormalizedGlobal <<- append(RBOTNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="DTOP" )
      DTOPNormalizedGlobal <<- append(DTOPNormalizedGlobal, returnsAfterPatternNormalized)
    else if ( pattern=="DBOT" )
    {
      DBOTNormalizedGlobal <<- append(DBOTNormalizedGlobal, returnsAfterPatternNormalized)
      UnconditionalNormalizedGlobal  <<- append(UnconditionalNormalizedGlobal, returnsUnconditionalNormalized)
    }
      
    
   
} 


####################################################################################################

#Triangle bottoms (TBOT) search routine
findTBOT <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for TBOT we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]
    
      if(   maximini$index.min[extrema[k-4]] #E1 is minumum
         && (E1 < E3) && (E3 < E5)    #E1 < E3 < E5 
         && (E2 > E4) #E2 > E4 
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
} 


#Triangle tops (TTOP) search routine
findTTOP <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for TTOP we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      if(   maximini$index.max[extrema[k-4]] #E1 is a maximum
         && (E1 > E3) && (E3 > E5)    #E1 > E3 > E5 
         && (E2 < E4) #E2 < E4 
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
} 

                              
#Broadening tops (BTOP) search routine
findBTOP <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for BTOP we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      if(   maximini$index.max[extrema[k-4]] #E1 is a maximum
         && (E1 < E3) && (E3 < E5)    #E1 < E3 < E5 
         && (E2 > E4) #E2 > E4 
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


#Broadening bottoms (BBOT) search routine
findBBOT <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for BBOT we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      if(   maximini$index.min[extrema[k-4]] #E1 is a minimum
         && (E1 > E3) && (E3 > E5)    #E1 > E3 > E5 
         && (E2 < E4) #E2 < E4 
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


#Head-and-shoulders (HS) search routine
findHS <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for HS we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      e1e5avr = (E1 + E5) / 2
      e2e4avr = (E2 + E4) / 2
     
      if(   maximini$index.max[extrema[k-4]] #E1 is a maximum
         && (E3 > E1) && (E3 > E5)    #E3 > E1 , E3 > E5 
         && (abs(E1 - e1e5avr) < 0.015*e1e5avr ) &&  (abs(E5 - e1e5avr) < 0.015*e1e5avr ) #E1 and E5 within 1.5% of their average
         && (abs(E2 - e2e4avr) < 0.015*e2e4avr ) &&  (abs(E4 - e2e4avr) < 0.015*e2e4avr ) #E2 and E4 within 1.5% of their average
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


#Inverse Head-and-shoulders (IHS) search routine
findIHS <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for IHS we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      e1e5avr = (E1 + E5) / 2
      e2e4avr = (E2 + E4) / 2
     
      if(   maximini$index.min[extrema[k-4]] #E1 is a minimum
         && (E3 < E1) && (E3 < E5)    #E3 < E1 , E3 < E5 
         && (abs(E1 - e1e5avr) < 0.015*e1e5avr ) &&  (abs(E5 - e1e5avr) < 0.015*e1e5avr ) #E1 and E5 within 1.5% of their average
         && (abs(E2 - e2e4avr) < 0.015*e2e4avr ) &&  (abs(E4 - e2e4avr) < 0.015*e2e4avr ) #E2 and E4 within 1.5% of their average
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


#Rectangle tops (RTOP) search routine
findRTOP <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for RTOP we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      topsavr = (E1 + E3 + E5) / 3 #further condition that E1 is a maximum, so tops are E1, E3, E5
      bottomsavr = (E2 + E4) / 2
     
      if(   maximini$index.max[extrema[k-4]] #E1 is a maximum
         && (min(E1,E3,E5) > max(E2, E4) )   #lowest top > highest bottom 
         && (abs(E1 - topsavr) < 0.0075*topsavr ) #tops
         && (abs(E3 - topsavr) < 0.0075*topsavr ) #are 
         && (abs(E5 - topsavr) < 0.0075*topsavr ) #within 0.75% of their average
         && (abs(E2 - bottomsavr) < 0.0075*bottomsavr ) #bottom are
         && (abs(E4 - bottomsavr) < 0.0075*bottomsavr ) #within 0.75% of their average
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


#Rectangle bottoms (RBOT) search routine
findRBOT <- function( vec, extrema, maximini )
{
  if((length(extrema) > 4)  ) #for RBOT we need 5 local extrema
  {
    for(k in (length(extrema)):5)
    {
      E1 = vec[extrema[k-4]]
      E2 = vec[extrema[k-3]]
      E3 = vec[extrema[k-2]]
      E4 = vec[extrema[k-1]]
      E5 = vec[extrema[k]]    
     
      bottomsavr = (E1 + E3 + E5) / 3 #further condition that E1 is a minimum, so bottoms are E1, E3, E5
      topsavr = (E2 + E4) / 2
     
      if(   maximini$index.min[extrema[k-4]] #E1 is a minimum
         && (min(E2,E4) > max(E1, E3, E5) )   #lowest top > highest bottom 
         && (abs(E2 - topsavr) < 0.0075*topsavr ) #tops #are
         && (abs(E4 - topsavr) < 0.0075*topsavr ) #within 0.75% of their average 
         && (abs(E1 - bottomsavr) < 0.0075*bottomsavr ) 
         && (abs(E3 - bottomsavr) < 0.0075*bottomsavr ) #bottom are
         && (abs(E5 - bottomsavr) < 0.0075*bottomsavr ) #within 0.75% of their average
         && extrema[k] >= length(vec)-d #allow 3 days to complete pattern      
      ) 
      { 
        retvec <- as.vector(c(extrema[k-4],extrema[k-3],extrema[k-2],extrema[k-1],extrema[k]))
        #print( c(E1,E2,E3,E4,E5) )
        return (retvec)
      } 
        
    }
  }
  retvec <- as.vector(c(0,0,0))
  return( retvec )
}


###############################DTOP and DBOT##################################

#Double tops (DTOP) search routine
findDTOP <- function( vec, extrema, maximini )
{
  #for DOUBLE top we need at least 3 extrema, i.e. at least {max,min,max}
  if((length(extrema) > 2)  )
  {
    for(k in 1:(length(extrema)))
    {
      E1 <- 0 #the 1st maximum
      t_1 <- 0 #date on which E1 occurs
      if(  maximini$index.max[extrema[1]] ) {
        E1 = vec[extrema[1]]
        t_1 = extrema[1]
      }
      else {
        E1 = vec[extrema[2]]
        t_1 = extrema[2]
      }

      Ea <- 0  #the 2nd maximum
      t_a <- 0 #date on which Ea occurs
      for(k in (length(extrema)):2)
      {
        if( vec[extrema[k]] > Ea ) {
          Ea = vec[extrema[k]]
          t_a = extrema[k]
        }
      }

      avr = (E1 + Ea) / 2 #average of tops

      if(  ((t_a - t_1) > 22) #distance between the tops > 22 days
         && (abs(E1 - avr) < 0.015*avr ) && (abs(Ea - avr) < 0.015*avr ) #tops are within 1.5% of their average
         && t_a >= length(vec)-d #allow 3 days to complete pattern
      )
      {
        retvec <- as.vector(c(t_1, t_a))
        return (retvec)
      }

    }
  }
  
  retvec <- vector("integer", length=0)
  return( retvec )
}


#Double bottoms (DBOT) search routine
findDBOT <- function( vec, extrema, maximini )
{
  #for DOUBLE bottom we need at least 3 extrema, i.e. at least {min,max,min}
  if((length(extrema) > 2)  )
  {
    for(k in 1:(length(extrema)))
    {
      E1 <- 0 #the 1st minimum
      t_1 <- 0 #date on which E1 occurs
      if(  maximini$index.min[extrema[1]] ) {
        E1 = vec[extrema[1]]
        t_1 = extrema[1]
      }
      else {
        E1 = vec[extrema[2]]
        t_1 = extrema[2]
      }

      Ea <- max(vec)  #the 2nd minimum
      t_a <- 0 #date on which Ea occurs
      for(k in (length(extrema)):2)
      {
        if( vec[extrema[k]] < Ea ) {
          Ea = vec[extrema[k]]
          t_a = extrema[k]
        }
      }

      avr = (E1 + Ea) / 2 #average of bottoms

      if(  ((t_a - t_1) > 22) #distance between the bottoms > 22 days
         && (abs(E1 - avr) < 0.015*avr ) && (abs(Ea - avr) < 0.015*avr ) #tops are within 1.5% of their average
         && t_a >= length(vec)-d #allow 3 days to complete pattern
      )
      {
        retvec <- as.vector(c(t_1, t_a))
        return (retvec)
      }

    }
  }

  retvec <- vector("integer", length=0)
  return( retvec )
}


#############################################
sink("D:\\BOOK\\WEBSITE\\ReproducingLo\\report\\Routput.txt", append=TRUE, split=TRUE)
library(np) #non-parametric regression package
library(RODBC) #import data from Excel
library(msProcess) #search for local extrema
          

      TTOPNormalizedGlobal<-vector("numeric")
      TBOTNormalizedGlobal<-vector("numeric")
      BTOPNormalizedGlobal<-vector("numeric")
      BBOTNormalizedGlobal<-vector("numeric")
      HSNormalizedGlobal<-vector("numeric")
      IHSNormalizedGlobal<-vector("numeric")
      RTOPNormalizedGlobal<-vector("numeric")
      RBOTNormalizedGlobal<-vector("numeric")
      DTOPNormalizedGlobal<-vector("numeric")
      DBOTNormalizedGlobal<-vector("numeric")

      UnconditionalNormalizedGlobal<-vector("numeric")
      

#Adidas
print("Adidas")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\Adidas.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)

#Allianz
print("Allianz")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\Allianz.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)

#Daimler
print("Daimler")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\Daimler.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)

#DeutscheBank
print("DeutscheBank")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\DeutscheBank.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)

#DeutscheTelekom
print("DeutscheTelekom")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\DeutscheTelekom.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)


#HeidelbergerZement
print("HeidelbergerZement")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\HeidelbergerZement.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)


#Henkel
print("Henkel")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\Henkel.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)


#Merck
print("Merck")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\Merck.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)


#RWE
print("RWE")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\RWE.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)


#ThyssenKrupp
print("ThyssenKrupp")
channel <- odbcConnectExcel("D:\\BOOK\\WEBSITE\\ReproducingLo\\daily_data\\Jan 2003 - Dec 2010\\ThyssenKrupp.xls")
marketData <- sqlFetch(channel,"table")
odbcClose(channel)
attach(marketData)
findPattern("TBOT")
findPattern("TTOP")
findPattern("BTOP")
findPattern("BBOT")
findPattern("HS")
findPattern("IHS")
findPattern("RTOP")
findPattern("RBOT")
findPattern("DTOP")
findPattern("DBOT")
detach(marketData)



detach("package:RODBC")

ks.test(UnconditionalNormalizedGlobal,  TTOPNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  TBOTNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  BTOPNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  BBOTNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  HSNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  IHSNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  RTOPNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  RBOTNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  DTOPNormalizedGlobal)
ks.test(UnconditionalNormalizedGlobal,  DBOTNormalizedGlobal)
