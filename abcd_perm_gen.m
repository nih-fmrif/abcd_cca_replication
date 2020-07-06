% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/6/20 (made the script into a function)

function abcd_perm_gen(N_perm, working_dir)
    if nargin<2
        N_perm=100000;
        working_dir='./'
    end

    % addpath(genpath(sprintf('%s/dependencies/', working_dir)));
    % addpath(genpath(sprintf('%s/data/', working_dir)));

    % Number of permutations (100,000)
    % N_perm=100000;

    % --- GENERATE PERMUTATIONS ---
    % Generate permutations using the hcp2blocks package
    blocksfile = sprintf('%s/data/blocksfile.csv', working_dir);
    % blocksfile='/data/blocksfile.csv';
    % sprintf('%s/data/VARS.txt', working_dir)
    [EB,tab] = abcd2blocks(sprintf('%s/data/VARS.txt', working_dir), blocksfile, [100 10])
    PAPset=palm_quickperms([ ], EB, N_perm); 
    % Note, PAPset is the final matrix of permuations (one permutation per column)

    % Now save PAPset to file
    writematrix(PAPset,sprintf('%s/data/PAPset.txt', working_dir));
end