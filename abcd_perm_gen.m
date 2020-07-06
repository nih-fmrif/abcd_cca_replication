% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

addpath(genpath('./dependencies/'));
addpath(genpath('./data/'));

% Number of permutations (100,000)
N_perm=100000;

% --- GENERATE PERMUTATIONS ---
% Generate permutations using the hcp2blocks package
% EB=hcp2blocks_abcd(tmp, [ ], false, VARS(:,1));
[EB,tab] = abcd2blocks('./data/VARS.txt',blocksfile)
PAPset=palm_quickperms([ ], EB, N_perm); 
% Note, PAPset is the final matrix of permuations (one permutation per column)

% Now save PAPset to file
writetable(PAPset,'./data/PAPset.txt')