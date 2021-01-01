# abcd_cca_replication

## General notes
This script uses the following tools:

- Connectome Workbench 1.4.2
- FSL version 6.0.1
- ICA+FIX version 1.06.15
- MATLAB 2017b (MCR v93)
- MATLAB 2020a (MCR v98)
- R version 4.0.0
- Python version 3.8.1 (only tested with this version!)

The script uses the following packages:

- FSLNets 0.6.3
- PALM (Alpha version 116)
- PWLING v1.2
- libsvm-3.24
- L1precision

This pipeline has been tested on CentOS Liux 7 (Core). Other versions of these tools may work, *but have NOT been tested*.

Other info:

- If running this pipeline from scratch, we *highly* recommend using a computing cluster. This pipeline was developed on a cluster using the SLURM scheduler (NIH Biowulf).
- When running dual_regression, need at least 32gb memory on a node when using the NIH Biowulf cluster (where dual_regression automatically gets batch processed using SLURM scheduler)

## Using this pipeline
### Getting started
#### Installing this repo:
1. Clone the repo
2. Install the conda environment
```
conda env create -f environment.yml
```
#### The NDA RDS file
You will need to download the NDA RDS file for the associated ABCD release you're interested in analyzing. The ABCD 2.0.1 RDS can be obtained here: https://nda.nih.gov/study.html?id=796

### Running the pipeline
1. Run /create_config.sh/ and provide the absolute paths to:
    - the main abcd_bids folder (for example, for NIH Biowulf users, */data/ABCD_MBDU/abcd_bids/bids/*)
    - the NDA RDS file
    - the location of the ABCD data reprocessed with the DCAN pipeline
    - the absolute path to the conda environment install of python
2. Navigate to abcd_cca_replication/data_prep/ and run the scripts in this order (and follow the intermediate instructions provided by each script:
    - prep_stage_0.sh
    - prep_stage_1.sh
    - prep_stage_2.sh
    - prep_stage_3.sh 
    - prep_stage_4.sh

## Other notes
### pipeline_version_1.6:
this version is used to develop the "winkler" method, which does two things differently than the original pipeline (corrections to the methodology)
1. we use scanner ID hash as a confound instead of abcd_site and scanner manufacturer -- why? because this is a better, more specific confound. BUT, to use this, we need to encode the confounds a bit differently. This is accomplished by the stage_4/VARS.py script.
2. We need to do our CCA pre-processing a bit differently, according to Permutation inference for canonical correlation analysis Winkler Et al. Neuroimage 2020.

### Run Notes:
1. Stage 0 swarm can take up to 24 hours to run completely. In the swarm error logs, you may see the following error, whose cause and effect is unkown, but appears to be irrelevant:
```
slurmstepd: error: _is_a_lwp: open() /proc/24097/status failed: No such file or directory
```

### Future development notes:
1. Modify the pipeline so the user does not need to manually activate the Conda environment, use a path variable in the pipeline.config file
2. Modify the logging system so that there are versioned log files for the pipeline (this functionality could be implemented by the create_config.sh script)





