# Script will find the relevant lines from a file ("filepaths") that contain a subject id, then save those lines to a new file

subject_list=$1
filepaths=$2
outdir=$3

while read subject; do

    line=$(cat $filepaths | grep $subject)

    if [ -z "$line" ]; then
        :
    else
        echo "$line" >> $outdir/subset_filepaths.txt
    fi

done < $subject_list

cat $outdir/subset_filepaths.txt | uniq >> $outdir/subset_filepaths_final.txt