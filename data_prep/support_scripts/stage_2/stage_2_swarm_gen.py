#!/usr/bin/python3

# stage_2_swarm_gen.py
# Created: 6/16/20
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020


# Generate commands of the form:
# $SUPPORT_SCRIPTS/stage_2/calc_avg_motion.sh $sub $ABCD_CCA_REPLICATION

import os
import sys

fp_sub_list = sys.argv[1]               # absolute path to file that contains subject ids
abcd_cca_replication = sys.argv[2]      # absolute path to main directory in repo (where pipeline.config located)
swarm_dir = sys.argv[3]                 # where to output swarm file
script_to_call = sys.argv[4]            # name of the script to call (absolute path)

subjects = [line.rstrip('\n') for line in open(fp_sub_list)]

fp = os.path.join(swarm_dir,'stage_2.swarm')
f_swarm = open(fp, 'w')

for subject in subjects:

    cmd = "{} {} {}".format(script_to_call, subject, abcd_cca_replication)
    f_swarm.write(cmd+'\n')
f_swarm.close()