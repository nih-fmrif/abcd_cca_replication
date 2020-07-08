% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/6/20 (made the script into a function)
% 7/7/20 (updated the palm_quickperms call to make it faster)

% n_subs = name of subset folder (e.x. 5013_subs) where the data is/should be saved

% Example call:
% abcd_perm_gen(100000, "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/", "5013_subs")


function abcd_perm_gen(N_perm, abcd_cca_dir, n_subs)
    if nargin<3
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_perm_gen(100000, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', '5013_subs')")
        exit
    end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
    end

    % Generate permutations using the hcp2blocks package
    in_VARS = sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs);
    blocksfile = sprintf('%s/data/%d/blocksfile.csv', abcd_cca_dir, n_subs);
    [EB,tab] = abcd2blocks(in_VARS, blocksfile, [100 10]);

    % NOTE, call palm_quickperms with the following options (for fastest calculations while also finding permutations proper)
    % [Pset,VG] = palm_quickperms(M,EB,P,EE,ISE,CMCx,CMCp)
    % M = [] (no design matrix
    % EB = exchangability blocks from abcd2blocks calc
    % N_perm = number of permutations
    % EE = true (so we do permutations proper)
    % ISE = false (so we don't do sign flips)
    % CMCx = true (this only applies for design matix, so we set to true)
    % CMCp = true (allow duplicate permutations, for speed and since we have nearly infinite possible permutations)
    Pset=palm_quickperms([ ], EB, N_perm, true, false, true, true);
    % Note, Pset is the final matrix of permuations (one permutation per column)

    % Now save Pset to file
    writematrix(Pset, sprintf('%s/data/%d/Pset.txt', abcd_cca_dir, n_subs));
end