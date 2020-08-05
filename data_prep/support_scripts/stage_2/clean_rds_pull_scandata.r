
# clean_rds_pull_scandata.r
# Created: 6/15/20
# Updated: 6/20/20 (pipeline_version_1.2)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

library(dplyr)
library(tidyr)

mode <- function(x) {
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
}

fix_name <- function(x) {
    nx <- sub("NDAR_INV","sub-NDARINV",x)
}

args <- commandArgs(trailingOnly = TRUE)
rds_path <- args[1]
sub_path <- args[2]
out_path <- args[3]

# rds_path="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/nda2.0.1.Rds"
# sub_path="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_1/subjects_keep_0.3mm.txt"

subject_list <- readLines(sub_path)
subject_list <- factor(subject_list)
scan_sm_list <- list("subjectid","iqc_t1_good_ser")

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

# Check which subjects from subject_list ARE NOT PRESENT in the RDS dataframe -- we drop these subjects!
subs_not_in_rds <- setdiff(subject_list,nda3$subjectid)

# Format of strings in these files are sub-NDARINVxxxxxxxx
# Drop subjects not in our list
nda4 <- nda3[nda3$subjectid %in% subject_list,]

subs_in_rds <- list(nda4$subjectid)

# Finally, remove any completely empty rows which may have been introduced
nda5 <- nda4[rowSums(is.na(nda4)) != ncol(nda4),]

# Pull out scan data
nda_scan <- nda5[ , (names(nda5) %in% scan_sm_list)]
# Drop any rows that have NA in the iqc_t1_good_ser column
nda_scan_2 <- nda_scan %>% drop_na(iqc_t1_good_ser)
nda_scan_3 <- nda_scan_2[nda_scan_2["iqc_t1_good_ser"]>0, ]

final_subs <- list(nda_scan_3$subjectid)
dropped_scan_subs <- setdiff(nda_scan$subjectid,nda_scan_3$subjectid)

nda6 <- nda5[nda5$subjectid %in% nda_scan_3$subjectid, ]

# Save updated RDS for later use
saveRDS(nda6, paste(out_path,"nda2.0.1_stage_2.Rds",sep="/"))

# Save list of missing subjects
write.table(subs_not_in_rds,
            file = paste(out_path,"prep_stage_2_missing_rds_subjects.txt",sep="/"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# Save list of dropped subjects
write.table(dropped_scan_subs,
            file = paste(out_path,"prep_stage_2_dropped_rds_scan_subjects.txt",sep="/"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# Save list of subjects available
write.table(final_subs,
            file = paste(out_path,"prep_stage_2_rds_subjects.txt",sep="/"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)