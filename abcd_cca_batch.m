% abcd_cca_batch.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/9/20
% Modified: 7/10/20 (modified to do some calcuations on the set of perms (percentiles, means))

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% This script is given a start index and the number of permutations to calculate
% NOTE: this script is COMPILED, and it expects input args to be strings (from cmd line), so we type cast the args

% How to compile this script on NIH biowulf using the mcc2 utility:
% mcc2 -m abcd_cca_batch.m -d compiled_scripts/ -nojvm -a ./dependencies/palm-alpha116/palm_inormal.m

% And to run a SINGLE INSTANCE of it (this is NOT how it is called on slurm):
%{
export XAPPLRESDIR=MR/v98/X11/app-defaults
export LD_LIBRARY_PATH=MR/v98/runtime/glnxa64:MR/v98/bin/glnxa64:MR/v98/sys/os/glnxa64:MR/v98/sys/opengl/lib/glnxa64
./run_abcd_cca_batch.sh /usr/local/matlab-compiler/v98 1 1000 70 /data/ABCD_MBDU/goyaln2/abcd_cca_replication/ 500
%}

% To see the command structure for HPC slurm for this script, see gen_batch_permutation_ica_swarm.py

% The output of this script is a .mat file that contains data necessary for null distribution permutation testing
% For the sake of aggregating this data, some computations are done here (finding percentiles and means) on the num_perms calculated (reduces memory and computational overhead later in analysis when we need to use this data)

function abcd_cca_batch(start_idx_in, num_perms_in, N_dim_in, abcd_cca_dir, n_subs_in)
    if nargin<5
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_cca_batch(1, 1000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 1000)")
        return
	end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
        start_idx   =   start_idx_in;
        num_perms   =   num_perms_in;
        N_dim   =   N_dim_in;
        n_subs  =   n_subs_in;
    elseif isdeployed
        % When compiled matlab, it reads the command line args all as strings so we need to convert
        start_idx   =   str2num(start_idx_in);
        num_perms   =   str2num(num_perms_in);
        N_dim   =   str2num(N_dim_in);
        n_subs  =   str2num(n_subs_in);
    end
        
    % Load data
    % Matrix S1 (only ICA sms)
    s1  =   sprintf('%s/data/%d/S1.txt', abcd_cca_dir, n_subs);
    % Matrix S5 (post-PCA SM matrix)
    s5  =   sprintf('%s/data/%d/S5.txt', abcd_cca_dir, n_subs);
    % Matrix N0 (raw connectome data)
    n0  =   sprintf('%s/data/%d/N0.txt', abcd_cca_dir, n_subs);
    % Matrix N5 (post-PCA connectome matrix)
    n5  =   sprintf('%s/data/%d/N5.txt', abcd_cca_dir, n_subs);

    S1  =   load(s1); 
    S5  =   load(s5);
    N0  =   load(n0);
    N5  =   load(n5);
  
    % Permutation matrix
    pset=sprintf('%s/data/%d/Pset.txt', abcd_cca_dir, n_subs);
    Pset=load(pset);

    % Temporary version of VARS used for permutation calcs
    grotvars=palm_inormal(S1);
    grotvars(:,std(grotvars)<1e-10)=[];
    grotvars(:,sum(isnan(grotvars)==0)<20)=[];


    % Varibles we calculate for each permutation:
    % r = the vector r for the permutation
    % nullNETr  =   the permutation's mode 1 connectome weights correlation to the RAW connectome matrix
    % nullNETv  =   for this permutation, the summation of the correlation values between each mode's connectome weights and the RAW connectome matrix
    % nullSMr   =   for this permutation, CCA mode 1 SM weights correalated against the S1 matrix
    % nullSMv   =   for this permutation, the summation of the correlation values between each mode's SM weights and the S1 matrix
    
    % Aggregation variables
    r_agg           =   [];
    nullNETr_agg    =   [];
    nullNETv_agg    =   [];
    nullSMr_agg     =   [];
    nullSMv_agg     =   [];

    r=zeros(N_dim+1, 1);
    for perm = start_idx:(start_idx+num_perms-1)
        % Note, need to range from start_idx:(start_idx+num_perms-1) because without the -1 on the final iteration perm will exceed 100,000 becoming 100,001 and causing an error
        % Also, need the -1 for only num_perms permutations to be ran
        [A, B, r(1:end-1), U, V, stats] = canoncorr(N5,S5(Pset(:,perm),:));
        r(end)=mean(r(1:end-1));
    
        nullNETr    =   corr(U(:,1),N0)';
        nullNETv    =   sum(corr(U,N0).^2,2);

        nullSMr     =   corr(V(:,1),grotvars(Pset(:,perm),:),'rows','pairwise')';
        nullSMv     =   sum(corr(V,grotvars(Pset(:,perm),:),'rows','pairwise').^2,2);

        r_agg           =   [r_agg;         r' ];
        nullNETr_agg    =   [nullNETr_agg;  nullNETr'];
        nullNETv_agg    =   [nullNETv_agg;  nullNETv'];
        nullSMr_agg     =   [nullSMr_agg;   nullSMr'];
        nullSMv_agg     =   [nullSMv_agg;   nullSMv'];

    end

    % Now find the summary variables for these 1000 permutatations
    % These are what we need to compute (taken from Steve Smith's code):
    % NOTE - these are percentiles of the columns - the result should be a 1xN_dim vector (where the N_dim columns are CCA modes)
    % prctile(nullNETv,5,1) mean(nullNETv,1) prctile(nullNETv,95,1)
    % prctile(nullSMv,5,1) mean(nullSMv,1) prctile(nullSMv,95,1)
    % prctile( max(abs(nullSMr)) ,95)
    % prctile( max(abs(nullNETr)) ,95)

    s = struct( 'start_idx',                {}, ...
                'num_perms',                 {}, ...
                'nullNETv_prctile_95',      {}, ...
                'nullNETv_prctile_5',       {}, ...
                'nullNETv_mean',            {}, ...
                'nullSMv_prctile_95',       {}, ...
                'nullSMv_prctile_5',        {}, ...
                'nullSMv_mean',             {}, ...
                'nullNETr_prctile_95',      {}, ...
                'nullSMr_prctile_95',       {}, ...
                'r',                        {}  );

    s(1).start_idx             =   start_idx;
    s(1).num_perms             =   num_perms;

    s(1).nullNETv_prctile_95   =   prctile(nullNETv_agg,95,1);
    s(1).nullNETv_prctile_5    =   prctile(nullNETv_agg,5,1);
    s(1).nullNETv_mean         =   mean(nullNETv_agg,1);

    s(1).nullSMv_prctile_95    =   prctile(nullSMv_agg, 95, 1);
    s(1).nullSMv_prctile_5     =   prctile(nullSMv_agg, 5, 1);
    s(1).nullSMv_mean          =   mean(nullSMv_agg, 1);

    s(1).nullNETr_prctile_95   =   prctile( max(abs(nullNETr_agg)) ,95);
    s(1).nullSMr_prctile_95    =   prctile( max(abs(nullSMr_agg)) ,95);
    s(1).r                     =   r_agg;

    % Save .mat file with the permutations
    save(sprintf('%s/data/%d/permutations/permutations_%d.mat', abcd_cca_dir, n_subs, start_idx), 's');

end