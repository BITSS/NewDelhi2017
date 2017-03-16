######## INFO ########

# Purpose: De-identify data by creating a random unique ID
# Created: 15 March by Julia Clark
# Inputs: none
# Outputs: "survey_data_restricted.csv", "id_map.csv", "survey_data_public.csv"

######## SETUP ########

  rm(list = ls()) # clear workspace
  setwd("~/Documents/RA/India_BITSS")

######## PACKAGES ########

# Check system and install packages user doesn't have, load needed packages

  need <- c("dplyr") # list packages needed
  have <- need %in% rownames(installed.packages()) # checks packages you have
  if(any(!have)) install.packages(need[!have]) # install missing packages
  invisible(lapply(need, library, character.only=T)) # load needed packages

######## CREATE SOME DATA ########

# First, set our seed for randomization --- CENSOR THIS when sharing code if used to de-identify  
  set.seed(92103)
  
# Let's pretend we sampled 1000 adults from 100 villages and recorded their ID number, gender, and age  
  n <- 1000
  
# Create some variables
  personal_ID <- NA
  village <- NA
  female <- NA
  age <- NA
  
# Populate variables    
  for(i in 1:n){ 
    personal_ID[i] <- as.numeric(paste(sample(seq(1:9), 8, replace = T), collapse="")) 
    village[i] <- sample(seq(1,100), 1, replace = T)
    female[i] <- sample(c(0,1), 1, replace = T)
    age[i] <- sample(seq(18,100), 1, replace = T)
  }

# Create dataframe from variables
  survey <- data.frame(personal_ID, village, female, age)
  head(survey)
  
# Save data to csv so people can use it in Stata
  write.csv(survey, "survey_data_restricted.csv", row.names=F)
  
# Summarize data
  survey_table <- survey %>% # create a summary table based on survey
    arrange(village, age) %>% # order by village, then age
    group_by(village, age) %>% # group by village and age
    summarise(count_female = sum(female)) # count number of women by village, age
  print(survey_table, n=30) # print first 30 rows of table
  table(survey_table$count_female) # Looks like each village-age group only has a few women, possible issue for indirect identifiers if we're tracking other sensitive data  
  
######## PSEUDONIMIZE ID NUMBER ########
# There are many ways to do this, here is one...
  
# Create a random pseudo ID number for each participant
  pseudo_ID <- sample( seq(1:n), n, replace = F) # generate 1000 new random ID numbers
  survey$pseudo_ID <- pseudo_ID # join pseudo ID to dataframe

# Save the map of pseudo_IDs to personal IDs
# MOVE THIS FILE out of the replication folder, do not share!!!
  id_map <- select(survey, personal_ID, pseudo_ID) # save only the two ID columns
  write.csv(id_map, "id_map.csv", row.names=F)

# Drop personal ID number from the dataset  
  pseudo_survey <- select(survey, -personal_ID) 
  pseudo_survey <- pseudo_survey[c(4,1,2,3)] # reorder so ID is first
 
# Save new public file
  write.csv(pseudo_survey, "survey_data_public.csv", row.names=F)
  
######## ADD RANDOM NOISE ########
  
# Set range of noise to be added  
  range <- seq(-5:5) 

# Create new variable that adds noise to each value of age    
  noisy_survey <- mutate(pseudo_survey, random_age = age + sample(range, 1, replace = T))

# Make a new table
  noisy_table <- noisy_survey %>% 
    arrange(village, random_age) %>% 
    group_by(village, random_age) %>% 
    summarise(count_female = sum(female)) 
  print(noisy_survey_table, n=30)
  table(noisy_table$count_female) # Hmmm, this didn't really help with our k-anonymity ...  

######## REDUCE INFORMATION ########

# Create a new, binned age variable  
  noisy_survey$age_range <- cut(noisy_survey$age,c(18,40,60,80,100), 
      labels = c("18-40", "40-60", "60-80","over 80"), 
      include.lowest = T)

# Make table again
  binned_age_table <- noisy_survey %>% 
    arrange(village, age_range) %>% 
    group_by(village, age_range) %>% 
    summarise(count_female = sum(female)) # count number of women by village, age
  print(binned_age_table, n=30) # print first 30 rows of table
  table(binned_age_table$count_female) # Better! But we're loosing lots of information  
  
