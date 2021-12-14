This repository contains all of the code used in the analyses described in the manuscript "The positive-negative mode link between brain connectivity, demographics, and behavior: A pre-registered replication of Smith et al. (2015)" currently in press at [Royal Society Open Science](https://royalsocietypublishing.org/journal/rsos). 

Software used in the code include:
- Matlab
- Connectome Workbench 1.4.2
- FSL version 6.0.1
- ICA+FIX version 1.06.15
- MATLAB 2017b (MCR v93)
- MATLAB 2020a (MCR v98)
- R version 4.0.0
- Python version 3.8.1 
- FSLNets 0.6.3
- [PALM](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/PALM) (Alpha version 116)
- PWLING v1.2
- libsvm-3.24
- L1precision

All software was run on the [NIH High Performance Computing Cluster](https://hpc.nih.gov) where all nodes run CentOS 7 and Slurm is used for job scheduling

### Installing

1. Clone the repo
2. Install the conda environment
```
conda env create -f environment.yml
```
#### Data needed from the NIMH Data Archive

- The NDA RDS file for ABCD Release 2.0.1 is needed here: https://nda.nih.gov/study.html?id=796
- The BIDS formatted release of the ABCD data available in [Collection 3165](https://collection3165.readthedocs.io/en/stable/)

### Running the pipeline
1. Run /create_config.sh/ and provide the absolute paths to:
    - the main abcd_bids folder (On the NIH HPC, */data/ABCD_MBDU/abcd_bids/bids/*)
    - the NDA RDS file
    - the location of the ABCD data reprocessed with the DCAN pipeline
    - the absolute path to the conda environment install of python
2. Navigate to abcd_cca_replication/data_prep/ and run the scripts in this order (and follow the intermediate instructions provided by each script:
    - prep_stage_0.sh
    - prep_stage_1.sh
    - prep_stage_2.sh
    - prep_stage_3.sh 
    - prep_stage_4.sh

### Run Notes:
1. Stage 0 can take up to 24 hours to run completely. 
2. When running FSL's `dual_regression`, jobs will need at least 32gb memory 






