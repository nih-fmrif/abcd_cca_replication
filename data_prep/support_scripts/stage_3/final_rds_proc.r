# final_rds_proc.r
# Created: 6/22/20 (pipeline_version_1.3)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
rds_path <- args[1]
sub_path <- args[2]
sm_path <- args[3]
ica_sm_path <- args[4]
out_path <- args[5]

subject_list <- readLines(sub_path)
subject_list <- factor(subject_list)
sm_list <- readLines(sm_path)
ica_sm_list <- readLines(ica_sm_path)

nda0 <- readRDS(rds_path)

# Drop subjects not in our list
nda <- nda0[nda0$subjectid %in% subject_list,]

# Extract SMs (listed in /data_prep/data/subject_measures.txt
nda1 <- nda[ , (names(nda) %in% sm_list)]

# Now, lets make a numeric copy
nda_numeric <- nda1
for (i in 1:NCOL(nda1)) {
    # column name
    name <- names(nda1)[i]
    if ( is.factor(nda1[,i]) && (name != "subjectid") && (name != "mri_info_device.serial.number") ) {
        # print(names(nda)[i])
        nda_numeric[name] <- as.numeric(nda1[,i])
        next
    }
    nda_numeric[name] <- nda1[,i]
}

# Now verify that all the SMs meet our requirements
col_inc_excl <- list()
badcols <- list()

colnames <- list(names(nda_numeric))

# 0 - excluded because all fields empty
# 1 - excluded due to criteria 1, too much missing data >50pct
# 2 - excluded due to criteria 2, too much similar data, over 95pct same
# 3 - excluded due to criteria 3, contains extreme outlier
# 4 - SM passes all quantitative criteria, included

cnt_drop_na <- 0
cnt_drop_var <- 0
cnt_drop_outlier <- 0

num_rows <- NROW(nda_numeric)
num_cols <- NCOL(nda_numeric)

# Start at 2 so we skip over subjectid column
for (i in 2:NCOL(nda_numeric)) {
    col <- colnames[[1]][[i]]
    vec = as.numeric(nda_numeric[[col]]) #get the vector of values

    ## Get the size of equal-value groups, ignore NAs
    tab <- sort(table(vec),decreasing = TRUE, useNA = False)

    ## Note, in the scenario where a col ONLY has NANs, then tab will be a NULL vector
    if (length(tab)>0){
        eq_vals <- tab[[1]] #size of largest equal-values group (ignoring NANs)
    } else {
        ## This col is just NANs, store the name and move on
        col_inc_excl[[col]] <- 1
        badcols <- c(badcols,col)
        next
    }
    
    num_nan <- sum(is.na(vec))
    num_not_nan <- num_rows-num_nan

    ## Find outliers
    ## Vector Ys = (Xs - median(Xs)).^2
    Ys = (na.omit(vec) - median(na.omit(vec)))^2
    Ys_max <- max(Ys, na.rm = TRUE)
    Ys_mean <- mean(Ys, na.rm = TRUE)*100
    ratio <- Ys_max/Ys_mean

    ## Note, this loop will flag zygosity fields incorrect, fix that here:
    if (col == 'Zygosity' | col == "paired.subjectid" | col == "rel_relationship" | col == "rel_family_id" | col == "rel_group_id"){
        col_inc_excl[[col]] <- 4
    } else if ( (num_nan/num_rows) > 0.5){
        ## Missing >50% data in this coliumn
        col_inc_excl[[col]] <- 1
        badcols <- c(badcols,col)
        cnt_drop_na <- cnt_drop_na + 1
        next
    } else if ( (eq_vals/num_not_nan)>0.95 ) {
        ## too much similar data, over 95% entries same
        col_inc_excl[[col]] <- 2
        badcols <- c(badcols,col)
        cnt_drop_var <- cnt_drop_var + 1
        next
    } else if (ratio > 1) {
        ## Contains an extreme outlier
        col_inc_excl[[col]] <- 3
        badcols <- c(badcols,col)
        cnt_drop_outlier <- cnt_drop_outlier + 1
    } else {
        col_inc_excl[[col]] <- 4
    }
}

if (length(badcols) > 0){
    sprintf("WARNING: One or more SMs did NOT PASS quantitative filtering. Check file col_inc_excl.txt for details.")
} else{
    sprintf("All SMs passed quantitative inclusion.")
}

## Drop any subject who is missing more than 50% of the final 74 SMs
nda_final_1 <- nda_numeric[rowSums(is.na(nda_numeric[,ica_sm_list])) < (length(ica_sm_list)/2),]    #Drop the subjects

# Drop any bad cols
nda_final_2 <- nda_final_1[ , !(names(nda_final_1) %in% badcols)]

# Final subject list
final_subs <- list(nda_final_2$subjectid)

# Final SM list
final_sms <- list(names(nda_final_2))

# Save final rds
saveRDS(nda_final, paste(out_path,"nda2.0.1_final.Rds",sep="/"))

# Save final RDS matrix as a csv
write.table(nda_final,
            file = paste(out_path,"VARS_no_motion.txt",sep="/"),
            sep  = ",",
            row.names = FALSE,
            col.names = TRUE,
            quote = FALSE)

# Save list of subjects available
write.table(final_subs,
            file = paste(out_path,"final_subjects.txt",sep="/"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# Save final SM list
write.table(final_sms, 
            file = "./data/final_sm_list.txt", 
            row.names = FALSE, 
            col.names = FALSE,
            quote = FALSE)

# write info about each SM to file (classification of each)
write.table(t(as.data.frame(col_inc_excl)), 
            file = paste(out_path,"col_incl_excl.txt",sep="/"),
            row.names = TRUE, 
            col.names = FALSE,
            quote = FALSE)