% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/6/20 (made the script into a function)

function abcd_perm_gen(N_perm, working_dir)
    if nargin<2
        print("ERROR, not enough arguments. Please input number of permutations and the path to /abcd_cca_replication/")
        print("Example: abcd_perm_gen 1000 /data/ABCD_MBDU/goyaln2/abcd_cca_replication/")
        exit
    end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', working_dir)));
        addpath(genpath(sprintf('%s/data/', working_dir)));
    end

    % --- GENERATE PERMUTATIONS ---
    % Generate permutations using the hcp2blocks package
    blocksfile = sprintf('%s/data/blocksfile.csv', working_dir);
    % blocksfile='/data/blocksfile.csv';
    % sprintf('%s/data/VARS.txt', working_dir)
    [EB,tab] = abcd2blocks(sprintf('%s/data/VARS.txt', working_dir), blocksfile, [100 10])

    % NOTE, call palm_quickperms with the following options (for fastest calculations while also finding permutations proper)
    % [Pset,VG] = palm_quickperms(M,EB,P,EE,ISE,CMCx,CMCp)
    % M = [] (no design matrix
    % EB = exchangability blocks from abcd2blocks calc
    % N_perm = number of permutations
    % EE = true (so we do permutations proper)
    % ISE = false (so we don't do sign flips)
    % CMCx = true (this only applies for design matix, so we set to true)
    % CMCp = true (allow duplicate permutations, for speed and since we have nearly infinite possible permutations)
    PAPset=palm_quickperms([ ], EB, N_perm, true, false, true, true);
    % Note, PAPset is the final matrix of permuations (one permutation per column)

    % Now save PAPset to file
    writematrix(PAPset,sprintf('%s/data/PAPset.txt', working_dir));
end