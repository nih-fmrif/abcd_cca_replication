% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

addpath(genpath('../dependencies/'));
addpath(genpath('./data/'));

abcd_cca_dir="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/"
hcp_cca_dir="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/hcp_cca_testing/"

% Number of permutations (100,000)
N_perm=100000;
n_subs=461;

VARS=readmatrix(sprintf('%s/data/%d/VARS.txt', hcp_cca_dir, n_subs)); % Subjects X SMs text file


% --- GENERATE PERMUTATIONS ---
EB=hcp2blocks(sprintf('%s/data/%d/r500_m.csv', hcp_cca_dir, n_subs), [ ], false, VARS(:,1));    % Input is the raw restricted file downloaded from Connectome DB
PAPset=palm_quickperms([ ], EB, N_perm, true, false, true, true);                                % the final matrix of permuations


% Now save PAPset to file
writematrix(PAPset, sprintf('%s/data/%d/Pset.txt', hcp_cca_dir, n_subs))