% abcd_perm_agg.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% Each CCA result is saved out to a text file for use in abcd_cca_analysis.m

function abcd_perm_agg(N_perm, N_dim, abcd_cca_dir, n_subs)
    if nargin<3
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_perm_agg(100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 5013)")
        exit
	end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
    end

    grotRp_agg=zeros(N_perm, N_dim+1);
    nullNETr_agg=[];
    nullSMr_agg=[];
    nullNETv_agg=[];
    nullSMv_agg=[];

    for perm=1:N_perm;

        grotRp      =   load(sprintf('%s/data/%d/permutations/grotRp_%d.txt', abcd_cca_dir, n_subs, perm));
        nullNETr    =   load(sprintf('%s/data/%d/permutations/nullNETr_%d.txt', abcd_cca_dir, n_subs, perm));
        nullSMr     =   load(sprintf('%s/data/%d/permutations/nullSMr_%d.txt', abcd_cca_dir, n_subs, perm));
        nullNETv    =   load(sprintf('%s/data/%d/permutations/nullNETv_%d.txt', abcd_cca_dir, n_subs, perm));
        nullSMv     =   load(sprintf('%s/data/%d/permutations/nullSMv_%d.txt', abcd_cca_dir, n_subs, perm));

        grotRp_agg      =   [grotRp_agg;    grotRp' ];
        nullNETr_agg    =   [nullNETr_agg;  nullNETr'];
        nullSMr_agg     =   [nullSMr_agg;   nullSMr'];
        nullNETv_agg    =   [nullNETv_agg;  nullNETv'];
        nullSMv_agg     =   [nullSMv_agg;   nullSMv'];
    end

    % Now save
    writematrix(grotRp_agg,     sprintf('%s/data/%d/grotRp_agg.txt', abcd_cca_dir, n_subs));
    writematrix(nullNETr_agg,   sprintf('%s/data/%d/nullNETr_agg.txt', abcd_cca_dir, n_subs));
    writematrix(nullSMr_agg,    sprintf('%s/data/%d/nullSMr_agg.txt', abcd_cca_dir, n_subs));
    writematrix(nullNETv_agg,   sprintf('%s/data/%d/nullNETv_agg.txt', abcd_cca_dir, n_subs));
    writematrix(nullSMv_agg,    sprintf('%s/data/%d/nullSMv_agg.txt', abcd_cca_dir, n_subs));
end