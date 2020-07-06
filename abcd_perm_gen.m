% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/6/20 (made the script into a function)

function abcd_perm_gen(N_perm)
    if nargin<1
        N_perm=100000;
    end

    addpath(genpath('./dependencies/'));
    addpath(genpath('./data/'));

    % Number of permutations (100,000)
    % N_perm=100000;

    % --- GENERATE PERMUTATIONS ---
    % Generate permutations using the hcp2blocks package
    blocksfile='./data/blocksfile.csv';
    [EB,tab] = abcd2blocks('./data/VARS.txt',blocksfile, [100 10])
    PAPset=palm_quickperms([ ], EB, N_perm); 
    % Note, PAPset is the final matrix of permuations (one permutation per column)

    % Now save PAPset to file
    writematrix(PAPset,'./data/PAPset.txt');
end