# Script will remove all files related to ICA+FIX run (use this before runninf ICA+FIX)

show_usage(){
    echo "usage: fix_cleanup.sh <absolute path to subject's highest level directory>"
}
show_example(){
    echo "For example: fix_cleanup.sh /data/ABCD_MBDU/goyaln2/abcd_mini/output/sub-NDARINV7L2M29CY/"
}

# Script will fail if any sub commands fail
set -x

subject=$1
PARENT_DIR=`echo $subject | xargs dirname`

if (( $# < 1 ))
then
    show_usage
    show_example
	exit 1
fi



# Accept either tarballed subjects or folders
if [[ -d $subject ]]; then 
    echo "folder passed as input, now removing ica+fix files."
    DIR=$subject
elif [[ -f $subject ]]; then
    if file $subject | grep -q compressed ; then
        echo "Tarball was passed, unzipping now..."
        tar -zxf $subject -C $PARENT_DIR
        DIR=$(echo $subject | cut -d. -f1)

        # Now make sure that the directory is actually there.
        if [[ -d $DIR ]]; then 
            echo "Subject unzip successful, now removing ica+fix files."
        else
            echo "Subject unzipping failed. Exiting."
            # exit 1
        fi

    else
        echo "File passed is NOT a .tar.gz. Exiting program."
    fi
else
    echo "Input does not exist. Exiting."
    # exit 1
fi

# The following will need to be removed:
# the fix_proc/ folder if it exists
# following files in each of the task-rest0<1,2,3...> directories (here we use task-rest02 as an example)
#   task-rest02_hp2000_clean.nii.gz
#   task-rest02_Atlas_hp2000_clean.README.txt
#   task-rest02_Atlas_hp2000_clean.dtseries.nii
#   task-rest02_dims.txt
#   task-rest02_Atlas_hp2000_vn.dscalar.nii
#   task-rest02_hp2000_vn.nii.gz
#   task-rest02_Atlas_mean.dscalar.nii
#   task-rest02_mean.nii.gz
#   Movement_Regressors_demean.txt
#   task-rest02_hp2000.ica/

# remove fix_proc if exists
if [ -d $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/ ]; then
    rm -r $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/
else
    echo "No fix_proc folder to remove."
fi

# Remove files with 'clean' in the name
#   task-rest02_hp2000_clean.nii.gz
#   task-rest02_Atlas_hp2000_clean.README.txt
#   task-rest02_Atlas_hp2000_clean.dtseries.nii
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "task-rest[0-9][0-9]*clean*" -exec rm {} \;

# Remove files with 'vn' in the name
#   task-rest02_Atlas_hp2000_vn.dscalar.nii
#   task-rest02_hp2000_vn.nii.gz
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "task-rest[0-9][0-9]*vn*" -exec rm {} \;

# Remove files with 'mean' in the name
#   task-rest02_Atlas_mean.dscalar.nii
#   task-rest02_mean.nii.gz
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "task-rest[0-9][0-9]*mean*" -exec rm {} \;

# Remove files with 'dims' in name
#   task-rest02_dims.txt
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "task-rest[0-9][0-9]*dims*" -exec rm {} \;

# Remove anything with 'hp2000' in name
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "task-rest[0-9][0-9]*hp2000*" -exec rm {} \;

# Remove Movement_Regressors_demean.txt
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type f -name "Movement_Regressors_demean.txt" -exec rm {} \;

# Remove the "task-rest02_hp2000.ica/" folder
find $DIR/ses-baselineYear1Arm1/files/MNINonLinear/Results/ -type d -name "task-rest[0-9][0-9]*.ica" -exec rm -r {} \;

echo "$subject is done!"