# DAG: 
library(dagitty)

d1 <- dagitty("dag{ 
  climateChange -> stream_flow -> temp <- restoration
  restoration -> stream_flow
 }")

plot(d1)
backDoorGraph(d1)

adjustmentSets(d1, "stream_flow", "temp") # restoration (of course)