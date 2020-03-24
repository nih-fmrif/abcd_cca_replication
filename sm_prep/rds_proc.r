# rds_proc.r
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script loads the pre-made .Rds file released by ABCD and:
#   1. keeps only baseline exams
#   2. Filters out only the subjects whose scans were deemed eligible for our CCA analysis (see motion/data/motion_filtered_subjects_R.txt)
#   3. applies basic quantitative filtering criteria to the data

library(dplyr)

# Note, you must move the .rds to the working directory of this script!
nda1 <- readRDS("nda2.0.1.rds")
subject_list <- readLines("../motion/data/motion_filtered_subjects_R.txt")
subject_list <- factor(subject_list)

nda2 <- nda1[nda1$src_subject_id %in% subject_list,]

# nda2 = nda1
nda2$interview_date <- as.Date(nda2$interview_date, "%m/%d/%Y")

nda3 <- nda2[order(as.integer(nda2$interview_date),decreasing = FALSE), ]

# Drop the follow up records, keeping only first instance
nda4 <- nda3 %>% distinct(src_subject_id, .keep_all = TRUE)

num_rows <- NROW(nda4)

# Apply quantiative exclusion criteria
# For each column
#   1. find largest equal-values group
#   2. Count number of missing values (i.e. number of NANs)
#   3. Count number of rows that are NOT NANs
#   4. check if more than 50% data missing
#   5. check if largest equal-values group is >95% of entries
#       Drop if criteria 4 or 5 is met

col_inc_excl <- list()
badcols <- list()

colnames <- list(names(nda4))

for (i in 4:NCOL(nda4)) {
    col <- colnames[[1]][[i]]
    vec = nda4[col] #get the vector
    
    # tab <- sort(table(vec,useNA="always"),decreasing=TRUE)

    tab <- sort(table(vec),decreasing = TRUE, useNA = False)

    # Note, in the scenario where a col ONLY has NANs, then tab will be a NULL vector
    if (length(tab)>0){
        eq_vals <- tab[[1]] #size of largest equal-values group (ignoring NANs)
    } else {
        # This col is just NANs, store the name and move on
        col_inc_excl[[col]] <- 0
        badcols <- c(badcols,col)
        next
    }
    
    num_nan <- sum(is.na(vec))
    num_not_nan <- num_rows-num_nan

    if ( (num_nan/num_rows) > 0.5){
        # Missing >50% data in this coliumn
        col_inc_excl[[col]] <- 0
        badcols <- c(badcols,col)
    } else if ( (eq_vals/num_not_nan)>0.95 ) {
        col_inc_excl[[col]] <- 0
        badcols <- c(badcols,col)
    } else {
        col_inc_excl[[col]] <- 1
    }
}

nda5 <- nda4[ , !(names(nda4) %in% badcols)]

saveRDS(nda5, "./data/nda2.0.1_full_proc.rds")
# write.csv(col_inc_excl,"/data/ABCD_MBDU/goyaln2/analysis-nda/notebooks/general/col_inc_excl")

write.table(t(as.data.frame(col_inc_excl)), 
            file = "./data/col_inc_excl.csv", 
            row.names = TRUE, 
            col.names = FALSE,
            quote = FALSE)