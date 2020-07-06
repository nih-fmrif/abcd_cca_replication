% abcd_perm_agg.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% Each CCA result is saved out to a text file for use in abcd_cca_analysis.m

function abcd_perm_agg(N_perm, N_dim)
    if nargin<2
        N_perm=100000;
        N_dim=70;
    end

    addpath(genpath('./dependencies/'));
    addpath(genpath('./data/'));

    grotRp=zeros(N_perm, N_dim+1);
    clear grotRpval;
    nullNETr=[];
    nullSMr=[];
    nullNETv=[];
    nullSMv=[];
    for perm=1:N_perm
        grotRp      =   load(sprintf('./data/permutations/grotRp_%d',perm));
        nullNETr    =   load(sprintf('./data/permutations/nullNETr_%d',perm));
        nullSMr     =   load(sprintf('./data/permutations/nullSMr_%d',perm));
        nullNETv    =   load(sprintf('./data/permutations/nullNETv_%d',perm));
        nullSMv     =   load(sprintf('./data/permutations/nullSMv_%d',perm));

        grotRp_agg      =   [grotRp_agg grotRp];
        nullNETr_agg    =   [nullNETr_agg nullNETr];
        nullSMr_agg     =   [nullSMr_agg nullSMr];
        nullNETv_agg    =   [nullNETv_agg nullNETv];
        nullSMv_agg     =   [nullSMv_agg nullSMv];
    end

    % Now save
    writematrix(grotRp, sprintf('./data/grotRp'));
    writematrix(grotRp, sprintf('./data/nullNETr'));
    writematrix(grotRp, sprintf('./data/nullSMr'));
    writematrix(grotRp, sprintf('./data/nullNETv'));
    writematrix(grotRp, sprintf('./data/nullSMv'));
end