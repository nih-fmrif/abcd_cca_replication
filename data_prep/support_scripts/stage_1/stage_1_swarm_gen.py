#!/usr/bin/python3

# stage_1_swarm_gen.py
# Created: 6/19/20 (pipeline_version_1.1)
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

import os
import sys

fp_sub_list             =   sys.argv[1] # absolute path to subject list (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_0/subjects_with_rsfmri.txt)
abcd_cca_replication    =   sys.argv[2] # absolute path to abcd_cca_replication folder
script_to_call          =   sys.argv[3] # absolute path to script (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/support_scripts/stage_1/subject_classifier.sh)
swarm_dir               =   sys.argv[4] # absolute path to directory where to print out the swarm file (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/support_scripts/stage_1/)

subjects = [line.rstrip('\n') for line in open(fp_sub_list)]

fp = os.path.join(swarm_dir,'stage_1.swarm')
f_swarm = open(fp, 'w')

# example command
# /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/support_scripts/stage_1/subject_classifier.sh sub-NDARINVxxxxxxxx /data/ABCD_MBDU/goyaln2/abcd_cca_replication/

for subject in subjects:
    cmd = "{} {} {}".format(script_to_call, subject, abcd_cca_replication)
    f_swarm.write(cmd+'\n')
f_swarm.close()