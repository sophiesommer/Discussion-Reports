# Load LIWC results
dataLIWC <- read.csv(paste0("./Data/Test_Data_Wk",weeknum,"_LIWC.csv"), 
                     row.names = 1, stringsAsFactors = FALSE)

# Reload original data
data <- read.csv(paste0("./Data/Test_Data_Wk",weeknum,".csv"), 
                 row.names = 1, stringsAsFactors = FALSE)

# Save LIWC results to dataset
data$wordct <- dataLIWC$WC
data$Analytic <- dataLIWC$Analytic
data$assent <- dataLIWC$assent
data$certain <- dataLIWC$certain
data$power <- dataLIWC$power
data$tentat <- dataLIWC$tentat
data$cause <- dataLIWC$cause
data$insight <- dataLIWC$insight

# Re-save the data file
write.csv(data, file=paste0("./Data/Test_Data_Wk",weeknum,".csv"))