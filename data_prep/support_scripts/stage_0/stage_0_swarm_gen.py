#!/usr/bin/python3

# stage_1_swarm_gen.py
# Created: 6/19/20 (pipeline_version_1.1)
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

import os
import sys

fp_sub_list             =   sys.argv[1] # absolute path to subject list (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_0/subjects_with_rsfmri.txt)
script_to_call          =   sys.argv[2] # absolute path to script (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/support_scripts/stage_0/abcd_censor.py)
FD_th                   =   sys.argv[3] # desired FD Threshold (set in config, default is 0.3mm)
seg                     =   sys.argv[4] # number of consecutive "good" timepoints (i.e. those with FD below 0.3mm) required for this setment to be kept
output_dir              =   sys.argv[5] # absolute path to /abcd_cca_replication/data_prep/data/stage_0/censor_files/
swarm_dir               =   sys.argv[6] # absolute path to directory where to print out the swarm file (/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_0/)

subjects = [line.rstrip('\n') for line in open(fp_sub_list)]

fp = os.path.join(swarm_dir,'stage_0.swarm')
f_swarm = open(fp, 'w')

# example command
# python /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/support_scripts/stage_0/abcd_censor.py -subj <subject ID> -FD_th 0.3 -seg 5 -out <output directory>

for subject in subjects:
    cmd = "python {} -subj {} -FD_th {} -seg {} -out {}".format(script_to_call, subject, FD_th, seg, output_dir)
    f_swarm.write(cmd+'\n')
f_swarm.close()