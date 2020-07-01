% abcd_perm_gen.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

addpath(genpath('./dependencies/'));

function abcd_permutation(VARSpath, blocksfilepath, outpath)
    % Note, the arg "outpath" should be an absolute path to where we save the permutations matrix

    % Number of permutations (100,000)
    N_perm=100000;

    % --- GENERATE PERMUTATIONS ---
    % Generate permutations using the hcp2blocks package
    % EB=hcp2blocks_abcd(tmp, [ ], false, VARS(:,1));
    % blocksfile='./data/blocksfile.csv';
    [EB,tab] = abcd2blocks(VARSpath,blocksfilepath)
    PAPset=palm_quickperms([ ], EB, N_perm); 
    % Note, PAPset is the final matrix of permuations (one permutation per column)

    % Now save PAPset to file
    writetable(PAPset,outpath)

end






