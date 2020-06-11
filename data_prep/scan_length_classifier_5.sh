#! /bin/bash

# Scan length crawler
# Tool does the following:
#   1.  Iterates over the scans (raw data) for all subjects, and determines how long their scans are (stores as one file per subject)
#       [generate file: NDARINVxxxxxxx_scan_lengths.txt]
#   2.  Determines a group average scan length (omitting scans with length < 50, based on observation these scans fail the ICA+FIX high pass stage)
#   3.  Based on group average scan length calculated, it will classify scans as 0 (exclude, scan length < 0.75*380)
#       or 1 (include, scan length >= 0.75*380) [generate file: NDARINVxxxxxxx_scan_classified.txt]
#   4.  Based on the scan lengths [NDARINVxxxxxxx_scan_lengths.txt] and scan include/exclude [NDARINVxxxxxxx_scans_to_use.txt] clean their censor file
#       (this calls a separate script called clean_censors.py, input is a list of subjects)
# Based on scan length, scans will be classified as 0 for exclude (scan has less than ), 1 for include.

# NOTE: this script must be called from the abcd_cca_replicaton/data_prep/ folder

# Inputs:
#   1. Absolute path to location of the sub-NDARINVxxxxxxxx/ RAW data folders (/data/ABCD_MBDU/abcd_bids/bids/)
#   2. Absolute path to location of the sub-NDARINVxxxxxxxx/ PROCCESSED data folders (/abcd_bids/bids/derivatives/dcan_reproc/)

# function average_scan_len {
# PYTHON_ARG="$1" python - <<END
# import os
# with open(os.environ['PYTHON_ARG'],'r') as f:
#     data = [float(line.rstrip()) for line in f.readlines()]
#     f.close()
# mean = float(sum(data))/len(data) if len(data) > 0 else float('nan')
# print(int(mean))
# END
# }

show_usage(){
    echo "usage scan_length_classifier_5.sh <absolute/path/to/folder/with/RAW/subjectdata/> <absolute/path/to/folder/with/PROCESSED/subjectdata/>"
}
show_example(){
    echo "usage scan_length_classifier_5.sh /data/ABCD_MBDU/abcd_bids/bids/ /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/"
}

# Verbose output (debugging)
# set -x

RAWDATA_PATH=$1
# PROCDATA_PATH=$2

if (( $# < 1 ))
then
    show_usage
    show_example
	exit 1
fi

DATAFOLDER=$PWD/data/scan_length_proc/
ICAFIX_CMDS=$PWD/data/icafix_cmds/

if [[ -d $PWD/censoring_data_subset/ ]]; then
    rm -r $PWD/censoring_data_subset/
    mkdir $PWD/censoring_data_subset/
else
    mkdir $PWD/censoring_data_subset/
fi


if [[ -d $DATAFOLDER ]]; then
    rm -r $DATAFOLDER
    mkdir $DATAFOLDER
else
    mkdir $DATAFOLDER
fi

if [[ -d $ICAFIX_CMDS ]]; then
    rm -r $ICAFIX_CMDS
    mkdir $ICAFIX_CMDS
else
    mkdir $ICAFIX_CMDS
fi



# Get a list of the raw data folders (these are absolute paths since $RAWDATA_PATH is an absolute path)
# find $RAWDATA_PATH -maxdepth 1 -type d -name "sub-NDARINV*" >> $DATAFOLDER/rawdata_folder_paths.txt

# Now remove any subjects that are NOT in our list of 7810 to process

# Now, iterate over the subjects and collect their scan length data (this can collect data for scans labeled 00 to 99, assumes 2 digit naming convention)
# format of subject id in final_subjects.txt is NDAR_INVxxxxxxxx
echo "Fetching scan length data for each subject and classifying scans for inclusion/exclusion."
subs_dropped=0
while read NDAR_INV
do
    # format sub-NDARINVxxxxxxxx
    subNDARINV=$(echo $NDAR_INV | cut -d"_" -f2 | sed 's|^|sub-NDAR|g')

    # NDARINVxxxxxxxx
    NDARINV=$(echo $subNDARINV | cut -d"-" -f2)

    # summary file, all subject ids + scan lengths
    echo $subNDARINV >> $DATAFOLDER/timepoints_subs.txt

    # Pull scan lengths from all available scans (format sub-NDARINVFL02R0H4_ses-baselineYear1Arm1_task-rest_run-[0-9][0-9]_bold.nii.gz)
    # Note, values are written to file in ascending order (i.e. scan 1 length on line one, scan 2 on line 2, etc...)
    find $RAWDATA_PATH/$subNDARINV/ses-baselineYear1Arm1/func/ -type f -name "*task-rest_run*[0-9][0-9]_bold.nii.gz" | sort | xargs -L 1 fslnvols | tee -a $DATAFOLDER/timepoints_subs.txt | tee -a $DATAFOLDER/timepoints_no_subs.txt | tee $DATAFOLDER/${NDARINV}_scan_lengths.txt >/dev/null
    
    # Create classifier file for each subject

    # Keep track of which scan we're looking at
    count=1 
    # total timepoints for valid scans for a subject
    total_tps=0
    cmd_str=""
    while read len
    do
        if [[ $len -lt 285 ]]; then
            echo 0 >> $DATAFOLDER/${NDARINV}_scans_classified.txt
        elif [[ $len -ge 285 ]]; then
            echo 1 >> $DATAFOLDER/${NDARINV}_scans_classified.txt

            # Aggregate their cmd string
            if [[ $count -lt 10 ]]; then
                # Prepend a 0 
                cmd_str=$cmd_str@task-rest0$count/task-rest0$count.nii.gz
            else
                # No need to prepend 0
                cmd_str=$cmd_str@task-rest$count/task-rest$count.nii.gz
            fi

            # Sum their total timepoints to make sure they are still valid subjects
            ((total_tps=total_tps+len))

        else
            echo "An error occured classifying scan $count for subject $sub_id"
            echo "ERR" >> $DATAFOLDER/${NDARINV}_scans_classified.txt
        fi
        ((count++))

        if [[ $total_tps -lt 750 ]]; then
            echo "WARNING: subject $subNDARINV has only $total_tps timepoints. Subject will be dropped."
            ((subs_dropped++))
        else
            # Since we can still use this subject, write their ICA+FIX cmd and total tps to file
            # format is cmd,total_tps
            # Save the filename as sub-NDARINVxxxxxxxx.txt (easier to use when we generate the ICA+FIX swarm cmds)
            echo $cmd_str,$total_tps > $ICAFIX_CMDS/$subNDARINV.txt

            # Since we can use this subject, save their name (won't bother cleaning censors for bad subjects)
            echo $NDARINV >> $DATAFOLDER/subjects.txt
            # echo $NDARINV >> $DATAFOLDER/NDARINV_subjects.txt
            # echo $subNDARINV >> $DATAFOLDER/subNDARINV_subjects.txt
        fi
    done < $DATAFOLDER/${NDARINV}_scan_lengths.txt

done < $PWD/data/final_subjects.txt
echo "Lengths acquired, now cleaning censor files for all subjects available"

# Now that scans are classified, clean the censors for subjects we have available
# python clean_censors.py $DATAFOLDER/NDARINV_subjects.txt
python clean_censors.py $DATAFOLDER/subjects.txt

echo "Done cleaning censor files!"