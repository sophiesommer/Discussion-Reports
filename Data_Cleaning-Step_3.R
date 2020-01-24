# Reload data
data <- read.csv(paste0("./Data/Test_Data_Wk",weeknum,".csv"), 
                 row.names = 1, stringsAsFactors = FALSE)

##CREATE REPORTS

# Load packages
require(knitr)
require(markdown)
require(rmarkdown)

# Save this week's authors, as well as a vector of authors who did not participate
authors <- unique(data$post_author)
non_participants <- setdiff(roster,authors)

# Make reports for the participants this week
for(name in authors){
   rmarkdown::render(input = paste0("./Report_Generator.Rmd"), 
                     output_format = "html_document",
                     output_file = paste("discussion_report_", 
                                         name, 
                                         ".html", 
                                         sep=''),
                     output_dir = paste0("./Reports/"))
}
        


# Generate blank reports for everyone else  
for(name in non_participants){
        rmarkdown::render(input = paste0("./Report_Generator_BLANK.Rmd"), 
                          output_format = "html_document",
                          output_file = paste("discussion_report_", 
                                              name, ".html", 
                                              sep=''),
                          output_dir = paste0("./Reports/"))
}
