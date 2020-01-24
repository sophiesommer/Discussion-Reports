# Load packages
require(dplyr)
require(lubridate)
require(readr)

# Load raw data
raw <- read.csv(paste0("./Data/rawdata.csv"), stringsAsFactors=FALSE)
topics <- read.csv(paste0("./Data/rawdata-topics.csv"), stringsAsFactors=FALSE)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## THIS SECTION REQUIRES MANUAL INPUT ##

# Roster
# Note: names should match first name as it is written in data/NYU Classes
# If two people have the same first name, we will need to make some changes in the future to account for this
roster <- c("Cindy", "Trevor", "Sarah", "Adrian", "Sabrina", "Taylor", 
            "Natalie", "Sophie", "Liz", "Beth", "Ariana", "Christopher")

# Facilitators need to be manually entered for each week below
facilitators <- list(c(NA, NA))

# Fill in week number
# Note that this is an index, not week of the semester
# So, the first week of online discussion is "week 1" even if it is week 2 of the semester
weeknum <- i <- 1

# The for-loop below can be used to repeat this process for all weeks up to the week of interest
# If all these datasets have already been saved, you can set i=weeknum and only run code inside loop
for(i in 1:weeknum){
        # Determine the topic ID for the given week number
        # Note: this should be checked and can be entered manually if necessary
        topicIDs <- topics$ID[grep(paste("Week", i), topics$TITLE)]
        weekID <- "12643205"
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ## INITIAL DATA CLEANING ##
        
        # Filter data so that it's just from the desired week
        data <- raw %>% filter(TOPIC_ID==weekID)
        
        # Convert column names from upper case to lower case
        colnames(data) <- tolower(colnames(data))
        
        # Create new column called created_day: day of the week that a post was made
        data$created_day <- as.POSIXlt(data$created, format="%m/%d/%Y %H:%M")$wday
        
        # Convert all of the date/time stamps to readable format
        # data <- data %>%
        #         mutate(created = as.POSIXct(created, format="%m/%d/%Y %H:%M")) %>%
        #         mutate(modified= as.POSIXct(modified, format="%m/%d/%Y %H:%M")) %>%
        #         mutate(lastthreadate = as.POSIXct(lastthreadate, format="%m/%d/%Y %H:%M"))
        
        # Keep only the first name of authors
        data$author <- sub(" .*", "", data$author)
        
        # Remove html tags from post_text
        data$post_text <- gsub("</?[^>]+>", " ", data$post_text)
        
        # Select only interesting columns and convert ids to character strings
        data <- data %>%
                dplyr::select(title,
                       post_text,
                       created,
                       modified,
                       modifier_netid,
                       num_readers,
                       post_id,
                       author,
                       parent_post_id,
                       top_thread_post_id,
                       created_day) %>%
                dplyr::mutate(parent_post_id = as.character(parent_post_id),
                       top_thread_post_id = as.character(top_thread_post_id))
        
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ## CLEANING PART 2 -- ADDING SOME NEW COLUMNS AND DELETING IRRELEVANT DATA ##
        
        # Note: the code below is solely to save the question IDs
        # There were issues with missing data being coded differently in some weeks 
        # So this can be checked and fixed manually if necessary
        possQids1 <- as.character(data$post_id[is.na(data$parent_post_id)])
        possQids2 <- as.character(data$post_id[grep("Question",
                                                    data$title, 
                                                    ignore.case=T)])
        possQids3 <- as.character(data$post_id[grep("\\(?[0-9]",data$title)]) 
        all_qids <- intersect(possQids1,intersect(possQids2, possQids3))
        nqs <- length(all_qids)
        questions <- rep(NA, nqs)
        for(j in 1:nqs){
           questions[j] <-  all_qids[grep(paste(j), 
                                          data$title[data$post_id %in% all_qids])]    
        }
        questions <- as.numeric(questions)

        
        # Create new column called parent_author: the author of the parent post 
        # Then save author as post_author to differentiate
        authorlist <- data %>% 
                      dplyr::select(post_id, author) %>%
                      dplyr::rename(post_author = author) %>% 
                      dplyr::mutate(post_id = as.character(post_id))
        
        data <- data %>% 
                left_join(authorlist, by=c("parent_post_id" = "post_id")) %>%
                rename(parent_author = post_author,post_author = author)
        
        
        # Create new column (type) which differentiates initial posts and replies
        # Questions/welcome messages are coded as "parent", initial repsponses are coded as "direct", replies as "reply"
        data$type <- NA
        firstlevel <- data$parent_post_id %in% questions
        data$type <- "reply"
        data$type[data$parent_post_id==""|data$parent_post_id=="(null)"] <- "parent"
        data$type[firstlevel] <- "direct"
        
        # Get rid of question posts, welcome messages, and responses to welcome messages
        data <- data[data$type!="parent",] 
        data <- data[data$top_thread_post_id %in% questions,] 
        
        # Add a column (question) that identifies which question each post was related to
        questionlist <- data.frame(top_thread_post_id=as.character(questions),
                                   question=paste0("Q", 1:nqs))
        data <- left_join(data, questionlist, by="top_thread_post_id")
        
        # Create new column identifying (T or F) whether the post author is a facilitator
        data <- data %>% 
                mutate(facilitator=post_author %in% facilitators[[i]])
        
        # Create cleaned csv file to run through LIWC
        write.csv(data, file=paste0("./Data/Test_Data_Wk",i,".csv"))
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##RUN THE MOST RECENT WEEK'S DATA THROUGH LIWC AND RESAVE FILE TO SAME DIRECTORY with _LIWC ADDED TO FILE NAME, THEN OPEN STEP 2##