# random_n_subjects.py
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# Created: 7/7/2020
# Modified:

# Selects a random N-subject subset from the given subject list

import sys
import os
import random

sub_list = sys.argv[1]
out_path = sys.argv[2]
N = int(sys.argv[3])

subs = [line.rstrip('\n') for line in open(sub_list)]

random.shuffle(subs)

# Save the first N subjects from randomized list
with open(out_path, "w") as output:
    for i in range(0,N):
        output.write('%s\n' % subs[i])