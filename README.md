# abcd_cca_replication

This script uses the following tools:

- Connectome Workbench 1.4.2
- FSL version 6.0.1
- ICA+FIX version 1.06.15
- MATLAB 2017b (MCR v93)
- MATLAB 2020a (MCR v98)
- R version 4.0.0

The script uses the following packages:

- FSLNets 0.6.3
- PALM (Alpha version 116)
- PWLING v1.2
- libsvm-3.24
- L1precision

This pipeline has been tested on CentOS Liux 7 (Core)
Other versions of these tools may work, but have NOT been tested.


Other info:

- If running this pipeline from scratch, we *highly* recommend using a computing cluster. This pipeline was developed on a cluster using the SLURM scheduler (NIH Biowulf).
- When running dual_regression, need at least 32gb memory on a node when using the NIH Biowulf cluster (where dual_regression automatically gets batch processed using SLURM scheduler)

pipeline_version_1.6:
this version is used to develop the "winkler" method, which does two things differently than the original pipeline (corrections to the methodology)
1. we use scanner ID hash as a confound instead of abcd_site and scanner manufacturer -- why? because this is a better, more specific confound. BUT, to use this, we need to encode the confounds a bit differently. This is accomplished by the stage_4/VARS.py script.
2. We need to do our CCA pre-processing a bit differently, according to Permutation inference for canonical correlation analysis Winkler Et al. Neuroimage 2020.
