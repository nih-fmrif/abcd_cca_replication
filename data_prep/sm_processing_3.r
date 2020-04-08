# sm_processing.r
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script loads the pre-made .Rds file released by ABCD and:
#   1. keeps only baseline exams
#   2. Filters out only the subjects whose scans were deemed eligible for our CCA analysis (see motion/data/motion_filtered_subjects_R.txt)
#   3. applies basic quantitative filtering criteria to the data

library(dplyr)

mode <- function(x) {
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
}

# NOTE, you must move the .Rds file to abcd_cca_replication/data_prep/data/ for this script to run properly
nda1 <- readRDS("./data/nda2.0.1.Rds")
subject_list <- readLines("./data/motion_filtered_subjects_R.txt")
subject_list <- factor(subject_list)
sm_list <- readLines("./data/subject_measures.txt")
nda2 <- nda1
# Sort by interview date, keep only baseline measurements (based on date)
nda2$interview_date <- as.Date(nda1$interview_date, "%m/%d/%Y")
nda3 <- nda2[order(as.integer(nda2$interview_date),decreasing = FALSE), ]

# Drop the follow up records, keeping only first instance
nda4 <- nda3 %>% distinct(src_subject_id, .keep_all = TRUE)

# Drop subjects not in our list
nda5 <- nda4[nda4$src_subject_id %in% subject_list,]

# Finally, remove any completely empty rows which may have been introduced
nda5 <- nda5[rowSums(is.na(nda5)) != ncol(nda5),]

# Now, lets make a numeric copy
nda_factored <- nda5
for (i in 1:NCOL(nda5)) {
    # column name
    name <- names(nda5)[i]
    if ( is.factor(nda5[,i]) && (name != "subjectid") ) {
        # print(names(nda)[i])
        nda_factored[name] <- as.numeric(nda5[,i])
        next
    }
    nda_factored[name] <- nda5[,i]
}

# Apply quantiative exclusion criteria
# For each column
#   1. find largest equal-values group
#   2. Count number of missing values (i.e. number of NANs)
#   3. Count number of rows that are NOT NANs
#   4. check if more than 50% data missing
#   5. check if largest equal-values group is >95% of entries
#   6. check if SM has extreme outliers (max(Ys) > mean (Ys)*100)
#       Drop if criteria 4, 5, or 6 is met

col_inc_excl <- list()
badcols <- list()

colnames <- list(names(nda_factored))
# NOTE:
# 0 - excluded because all fields empty
# 1 - excluded due to criteria 1, too much missing data >50pct
# 2 - excluded due to criteria 2, too much similar data, over 95pct same
# 3 - excluded due to criteria 3, contains extreme outlier
# 4 - SM passes all quantitative criteria, included

cnt_drop_na <- 0
cnt_drop_var <- 0
cnt_drop_outlier <- 0

num_rows <- NROW(nda_factored)
num_cols <- NCOL(nda_factored)

for (i in 4:NCOL(nda_factored)) {
    col <- colnames[[1]][[i]]
    vec = as.numeric(nda_factored[[col]]) #get the vector of values

    # Get the size of equal-value groups, ignore NAs
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

    # Find outliers
    # Vector Ys = (Xs - median(Xs)).^2
    Ys = (na.omit(vec) - median(na.omit(vec)))^2
    Ys_max <- max(Ys, na.rm = TRUE)
    Ys_mean <- mean(Ys, na.rm = TRUE)*100
    ratio <- Ys_max/Ys_mean

    if ( (num_nan/num_rows) > 0.5){
        # Missing >50% data in this coliumn
        col_inc_excl[[col]] <- 1
        badcols <- c(badcols,col)
        cnt_drop_na <- cnt_drop_na + 1
        next
    } else if ( (eq_vals/num_not_nan)>0.95 ) {
        # too much similar data, over 95% entries same
        col_inc_excl[[col]] <- 2
        badcols <- c(badcols,col)
        cnt_drop_var <- cnt_drop_var + 1
        next
    } else if (ratio > 1) {
        # Contains an extreme outlier
        col_inc_excl[[col]] <- 3
        badcols <- c(badcols,col)
        cnt_drop_outlier <- cnt_drop_outlier + 1
    } else {
        col_inc_excl[[col]] <- 4
    }
}

print_line = sprintf("--- RESULTS OF sm_processing_3.r ---")
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("%s",Sys.time())
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("Initial number of SMs: %d", num_cols)
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("SMs dropped due to >50pct missing data: %d", cnt_drop_na)
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("SMs dropped due to >95pct same values: %d", cnt_drop_var)
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("SMs dropped due to extreme outliers: %d", cnt_drop_outlier)
write(print_line, file="log.txt", append=TRUE)

# Drop any bad cols
nda5 <- nda_factored[ , !(names(nda_factored) %in% badcols)]
saveRDS(nda5, "./data/nda2.0.1_preproc.Rds")

print_line = sprintf("Final number of SMs after filtering: %s", NCOL(nda5))
write(print_line, file="log.txt", append=TRUE)

# Save info on good and bad columns
write.table(t(as.data.frame(col_inc_excl)), 
            file = "./data/col_inc_excl.csv", 
            row.names = TRUE, 
            col.names = FALSE,
            quote = FALSE)

# Now just keep the columns we want
# Manually add back in Zygosity
nda6 <- nda5[ , (names(nda5) %in% sm_list)]
nda6['Zygosity'] <- nda5['Zygosity']

print_line = sprintf("Final number of SMs for CCA: %s", NCOL(nda6))
write(print_line, file="log.txt", append=TRUE)

# Drop any subjectd whose row is empty except for their subject id
# before
print_line = sprintf("Number subjects BEFORE dropping any with all SMs missing: %s", NROW(nda5))
write(print_line, file="log.txt", append=TRUE)
# Drop them
nda7 <- nda6[rowSums(is.na(nda6[,2:NCOL(nda6)])) != NCOL(nda6),]
# After
print_line = sprintf("Number subjects AFTER dropping any with all SMs missing: %s", NROW(nda7))
write(print_line, file="log.txt", append=TRUE)

# Save the final .Rds
saveRDS(nda7, "./data/nda2.0.1_full_proc_factored.Rds")

# Get basic demographics before and after
# num subjects
# num subjects male, num female
# age distribution
# number scan sites
# number scanner types
# use nda4 for 11875 subjects
# use nda5 for 7812 subjects
print_line = sprintf("--SUMMARY STATS--:")
write(print_line, file="log.txt", append=TRUE)

print_line = sprintf("-BEFORE FILTERING-:")
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("F %s | M %s",table(nda4['sex'])[[1]],table(nda4['sex'])[[2]])
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("Age: mean %s | median %s | mode %s | range %s-%s | stddev %s", mean(nda4[['age']]), median(nda4[['age']]), mode(nda4[['age']]), range(nda4[['age']])[1], range(nda4[['age']])[2], sd(nda4[['age']]))
write(print_line, file="log.txt", append=TRUE)
print_line = table(nda4[['abcd_site']])
write.table(print_line, file="log.txt", append=TRUE)
print_line = table(nda4[['mri_info_manufacturer']])
write.table(print_line, file="log.txt", append=TRUE)

print_line = sprintf("-AFTER FILTERING-:")
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("F %s | M %s",table(nda5['sex'])[[1]],table(nda5['sex'])[[2]])
write(print_line, file="log.txt", append=TRUE)
print_line = sprintf("Age: mean %s | median %s | mode %s | range %s-%s | stddev %s", mean(nda5[['age']]), median(nda5[['age']]), mode(nda5[['age']]), range(nda5[['age']])[1], range(nda5[['age']])[2], sd(nda5[['age']]))
write(print_line, file="log.txt", append=TRUE)
print_line = table(nda5[['abcd_site']])
write.table(print_line, file="log.txt", append=TRUE)
print_line = table(nda5[['mri_info_manufacturer']])
write.table(print_line, file="log.txt", append=TRUE)

# Now, we need to save this final matrix as a CSV or TSV file, either is fine.
write.table(nda7,
            file = "./data/VARS_no_motion.txt",
            sep  = ",",
            row.names = FALSE,
            col.names = TRUE,
            quote = FALSE)

# Also write a file with final list of subjects
subs_list <- list(nda7$subjectid)
write.table(subs_list,
            file = "./data/final_subjects.txt",
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# And final SMs
# Also write a file with final list of subjects
sm_list <- list(names(nda7))
write.table(sm_list, 
            file = "./data/final_sm_list.txt", 
            row.names = FALSE, 
            col.names = FALSE,
            quote = FALSE)