% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

addpath(genpath('../dependencies/'));
addpath(genpath('./data/'));

% Number of permutations (100,000)
N_perm=100000;

% --- GENERATE PERMUTATIONS ---
EB=hcp2blocks('./r500_m.csv', [ ], false, VARS(:,1));    % Input is the raw restricted file downloaded from Connectome DB
PAPset=palm_quickperms([ ], EB, Nperm, true, false, true, true);                                % the final matrix of permuations


% Now save PAPset to file
writematrix(PAPset,'./data/Pset.txt')