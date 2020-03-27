# rds_proc_final.r
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script loads the pre-made .Rds file released by ABCD and:
#   1. keeps only baseline exams
#   2. Filters out only the subjects whose scans were deemed eligible for our CCA analysis (see motion/data/motion_filtered_subjects_R.txt)
#   3. Filters out only the relevant SMs selected for our study
#   4. Removes subjects who were scanned on the Phillips scanner (as on March 2020, these subjects had an error in processing and must be removed from analysis)

library(dplyr)

# Note, you must move the .rds to the working directory of this script!
nda1 <- readRDS("nda2.0.1.Rds")
subject_list <- readLines("../motion/data/motion_filtered_subjects_R.txt")
subject_list <- factor(subject_list)
sm_list <- readLines("../data/subject_measures.txt")

# Drop subjects, keep only baseline measurements (based on date)
nda2 <- nda1[nda1$src_subject_id %in% subject_list,]

# Next drop subjects who were scanned on phillips scanner
nda2 <- nda2[ !(nda2$mri_info_manufacturer=="Philips Medical Systems"), ]

# Sort by interview date
nda2$interview_date <- as.Date(nda2$interview_date, "%m/%d/%Y")
nda3 <- nda2[order(as.integer(nda2$interview_date),decreasing = FALSE), ]

# Drop the follow up records, keeping only first instance
nda4 <- nda3 %>% distinct(src_subject_id, .keep_all = TRUE)

# Now keep only the selected SMs
nda5 <- nda4[ , (names(nda4) %in% sm_list)]

num_rows <- NROW(nda5)
num_cols <- NCOL(nda5)

# Save the final filtered .Rds
saveRDS(nda5, "../data/nda2.0.1_full_proc.Rds")

# Now, we need to save this final matrix as a CSV or TSV file, either is fine.
write.table(nda5,
            file = "../data/VARS.csv",
            sep  = ",",
            row.names = FALSE, 
            col.names = TRUE,
            quote = FALSE)

# Also write a file with final list of subjects
subs_list <- list(nda5$subjectid)
write.table(subs_list, 
            file = "../data/final_subjects.txt", 
            row.names = FALSE, 
            col.names = FALSE,
            quote = FALSE)