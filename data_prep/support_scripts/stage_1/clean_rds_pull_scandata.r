
# clean_rds.r
# Created: 6/15/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script does the following:
#   1.  Keeps only baseline scans for subjects
#   2.  Converts subject naming from NDAR_INVxxxxxxxx to sub-NDARINVxxxxxxxx
#   3.  Exports some motion data needed in prep_stage_1 (saves to /data/stage_1/scan_data.txt)

library(dplyr)

mode <- function(x) {
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
}

fix_name <- function(x) {
    nx <- sub("NDAR_INV","sub-NDARINV",x)
}

args <- commandArgs()
rds_path <- args[1]
sub_path <- args[2]
out_path <- args[3]
# sm_path <- args[3]

subject_list <- readLines(sub_path)
subject_list <- factor(subject_list)
scan_sm_list <- list("subjectid","iqc_t1_good_ser","iqc_rsfmri_good_ser","iqc_rsfmri_total_ser")

# Load original RDS file
nda <- readRDS(rds_path)
nda1 <- nda
# Sort by interview date, keep only baseline measurements (based on date)
nda1$interview_date <- as.Date(nda$interview_date, "%m/%d/%Y")
nda2 <- nda1[order(as.integer(nda1$interview_date),decreasing = FALSE), ]
# Drop the follow up records, keeping only first instance
nda3 <- nda2 %>% distinct(subjectid, .keep_all = TRUE)

# Now correct the naming scheme
sub_ids_orig <- list(nda3$subjectid)
sub_ids_new <- lapply(sub_ids_orig, fix_name)
# Now replace the existing subid column with this new one
nda3[["subjectid"]] <- sub_ids_new[[1]]

# Now remove all subjects who are missing their .mat files (specific by file /data/stage_1/subs_with_motion.txt)
# Format of strings in these files are sub-NDARINVxxxxxxxx
# Drop subjects not in our list
nda4 <- nda3[nda3$subjectid %in% subject_list,]

# Finally, remove any completely empty rows which may have been introduced
nda5 <- nda4[rowSums(is.na(nda4)) != ncol(nda4),]

# Pull out scan data
nda_scan <- nda5[ , (names(nda5) %in% scan_sm_list)]

# Now keep subject measures of interest
# nda6 <- nda5[ , (names(nda5) %in% sm_list)]

# Save updated RDS for later use
saveRDS(nda5, paste(out_path,"nda2.0.1_stage_1.Rds",sep="/"))

# Save scan data
write.table(nda_scan,
            file = paste(out_path,"scan_data.txt",sep="/"),
            sep  = ",",
            row.names = FALSE,
            col.names = TRUE,
            quote = FALSE)