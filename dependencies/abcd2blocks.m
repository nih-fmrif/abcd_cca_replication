function varargout = abcd2blocks(restrfile,blocksfile,flags,ids,showreport)
    % Takes a "restricted data" CSV file from the HCP and generates
    % a block file that can be used to make permutations in PALM.
    %
    % Usage:
    % [EB,tab] = abcd2blocks(restrfile,blocksfile,flags,ids,showreport)
    %
    % Inputs:
    % restrfile  : CSV file from ABCD/NDAR containing at least these fields:
    %              subjectid, rel_family_id, rel_relationship, zygosity and
    %              age, abcd_site and mri_info_device.serial.number. The last
    %              two are currently not used but this may change in the future.
    % blocksfile : CSV file to be created, with the exchangeability blocks,
    %              ready for used with PALM.
    % flags      : (Optional) A two-element vector interpreted as:
    %              flags(1) == 10:   treat DZ as ordinary sibs.
    %              flags(1) == 100:  treat DZ as a category on its own
    %              flags(2): defines what to do with missing zygosity:
    %              flags(2) == NaN:  remove subject from the dataset.
    %              flags(2) == 10:   treat subject as full sib.
    %              flags(2) == 100:  treat subject as DZ.
    %              flags(2) == 1000: treat subject as MZ.
    %              Defaut is [100 NaN]
    % ids        : (Optional) A cell array of subject IDs. If supplied, only the
    %              subjects with the indicated IDs will be used.
    % showreport : (Op[tional) Boolean indicating whether you want a report
    %              on the types of families and their numbers.
    %
    % Outputs (if requested):
    % EB      : Block definitions, ready for use, in the original order
    %           as in the CSV file.
    % tab     : (Optional) For diagnostic purposes, a table containing these columns:
    %   #1        - Numeric subject ID (to be used internally by this program only).
    %               These IDs match the rows in rawidsm which are the alphanumeric
    %               IDs (i.e., 'NDAR_*').
    %   #2        - Family index, as it comes from ABCD.
    %   #3 and #4 - These two columns jointly represent zygosity and family structure.
    %               These are 'rel_relationship' and 'Zygosity' from ABCD.
    %   #5        - Subject's age.
    %   #6        - Site.
    %   #7        - Scanner.
    %   #8        - Sibling type.
    %   #9        - Family type (sum of sibtypes within family).
    %
    % Reference:
    % * Winkler AM, Webster MA, Vidaurre D, Nichols TE, Smith SM.
    %   Multi-level block permutation. Neuroimage. 2015;123:253-68.
    %
    % _____________________________________
    % Anderson M. Winkler
    % NIH/NIMH 
    % Dec/2013 (first version, for HCP)
    % Jun/2020 (this version, for ABCD)
    % http://brainder.org
    
    warning off backtrace
    
    % Load the data and select what is now needed
    tmp        = strcsvread(restrfile);
    Ntmp       = size(tmp,1)-1;
    
    % Locate the columns with the relevant pieces of info, and keep just them
    % for later use. The variable "tab" will have the following columns:
    % #1        - Numeric subject ID (to be used internally by this program only).
    %             These IDs match the rows in rawidsm which are the alphanumeric
    %             IDs (i.e., 'NDAR_*').
    % #2        - Family index, as it comes from ABCD.
    % #3 and #4 - These two columns jointly represent zygosity and family structure.
    %             These are 'rel_relationship' and 'Zygosity' from ABCD.
    %             See more later down...
    % #5        - Subject's age.
    % #6        - Site.
    % #7        - Scanner.
    % #8        - Sibling type.
    % #9        - Family type (sum of sibtypes within family).
    
    % Locate the relevant column indices from the input file
    egid_col  = strcmpi(tmp(1,:),'subjectid');
    famid_col = find(strcmpi(tmp(1,:),'rel_family_id'));
    rel_col   = find(strcmpi(tmp(1,:),'rel_relationship'));
    zygo_col  = find(strcmpi(tmp(1,:),'zygosity'));
    agey_col  = find(strcmpi(tmp(1,:),'age'));
    site_col  = find(strcmpi(tmp(1,:),'abcd_site'));
    scnr_col  = strcmpi(tmp(1,:),'mri_info_device.serial.number');
    
    % Keep the raw IDs and scanner hashes for later (these are strings)
    ids_raw   = tmp(2:end,egid_col);
    ids_new   = (1:Ntmp)';
    scnr_raw  = tmp(2:end,scnr_col);
    [scnr_new,~] = str2map(scnr_raw);
    
    % Now finally the main table
    tab       = cell2mat(tmp(2:end,[famid_col rel_col zygo_col agey_col site_col]));
    tab       = [ids_new tab scnr_new];
    
    % Further down NaNs are removed as missing, but in col #4, NaN actually has
    % a meaning, so let's replace the meaningful ones for "-1".
    %     1   NaN   singleton
    %     2   NaN   non-twin sibling
    %     3   1     dizygotic
    %     3   2     missing zygosity
    %     3   3     monozygotic
    %     4   NaN   triplet
    idx = tab(:,3) ~= 3 & isnan(tab(:,4));
    tab(idx,4) = -1;
    
    % Create an 8th column for the sib-type.
    if nargin >= 3
        if flags(2) == 100
            flags(2) = flags(1);
        end
    else
        flags = [100 NaN];
    end
    sibtype = zeros(size(tab,1),1);
    sibtype(tab(:,3) == 1) = 10;        % singleton
    sibtype(tab(:,3) == 2) = 10;        % common sib
    sibtype(tab(:,4) == 1) = flags(1);  % DZ sib
    sibtype(tab(:,4) == 2) = flags(2);  % missing zygosity
    sibtype(tab(:,4) == 3) = 1000;      % MZ sib
    sibtype(tab(:,3) == 4) = 10;        % common sib (triplets)
    tab = [tab sibtype];
    
    % Now the NaNs that are meaningless can be marked for exclusion
    % (dropped from 'ids' now, excluded later)
    idxtodel = any(isnan(tab),2);
    idstodel = ids_raw(tab(idxtodel,1));
    if numel(idstodel)
        warning(sprintf([ ...
            'These subjects have data missing in the restricted file and will be removed:\n' ...
            repmat('         %s\n',1,numel(idstodel))],idstodel{:})); %#ok<SPWRN>
    end
    ids_raw(idxtodel) = [];
    tab(idxtodel,:)   = [];
    
    % Subselect subjects as needed
    if nargin == 4 && ~isempty(ids) && islogical(ids(1))
        tab        = tab(ids,:);
    elseif nargin == 4 && ~ isempty(ids)
        [~,miss1,miss2] = cellstrcmpi(ids_raw,ids);
        if any(miss2)
            warning(sprintf([ ...
                'These subjects don''t exist in the input file and will be removed: \n' ...
                repmat('         %d\n',1,sum(miss2))],ids_raw(miss2))); %#ok<SPWRN>
        end
        ids_raw(miss1)   = []; %#ok<NASGU>
        tab    (miss1,:) = [];
    end
    N = size(tab,1);
    
    % Label each family according to their type. The "type" is
    % determined by the number and type of siblings.
    F = unique(tab(:,2));
    famtype = zeros(N,1);
    for f = 1:numel(F)
        fidx = tab(:,2) == F(f);
        famtype(fidx) = sum(tab(fidx,8));
    end
    tab = [tab famtype];
    
    % Twins which pair data isn't available should be treated as
    % non-twins, so fix and repeat computing the family types. But since
    % N has changed after selection of subjects and dropping the ones with
    % missing data, need to take the sibdata again from the current 'tab':
    sibtype = tab(:,8);
    idx = (sibtype == 100  & (famtype >= 100  & famtype <= 199)) ...
        | (sibtype == 1000 & (famtype >= 1000 & famtype <= 1999));
    tab(idx,8) = 10;
    for f = 1:numel(F)
        fidx = tab(:,2) == F(f);
        famtype(fidx) = sum(tab(fidx,8));
    end
    tab(:,9) = famtype;
    
    % Families of the same type can be shuffled, as well as sibs of the same
    % type. To do this, the simplest is to construct the blocks within each
    % family type, then replicate across the families of the same type.
    % Start by sorting
    [~,idx] = sortrows([tab(:,2) tab(:,8) tab(:,5)]);
    [~,idxback] = sort(idx);
    tab     = tab(idx,:);
    famid   = tab(:,2);
    sibtype = tab(:,8);
    famtype = tab(:,9);
    
    % Now make the blocks for each family
    B = cell(numel(F),1);
    for f = 1:numel(F)
        fidx = famid == F(f);
        ft = famtype(find(fidx,1));
        if any(ft == [210 2010])
            B{f} = horzcat(-famid(fidx),sibtype(fidx),tab(fidx,1));
        else
            B{f} = horzcat(famid(fidx),sibtype(fidx),tab(fidx,1));
        end
    end
    
    % Concatenate all. Prepending the famtype ensures that the
    % families of the same type can be shuffled whole-block. Also,
    % add column with -1, for within-block at the outermost level
    B = horzcat(-ones(N,1),famtype,cell2mat(B));
    
    % Sort back to the original order
    B   = B(idxback,:);
    tab = tab(idxback,:);
    
    % Drop columns that are redundant (useful when the supplied ids
    % contain just a few subjects)
    for c = size(B,2):-1:2
        if numel(unique(B(:,c))) == 1
            B(:,c) = [];
        end
    end
    if nargout >= 1
        varargout{1} = B;
    end
    if nargout >= 2
        varargout{2} = tab;
    end
    
    % Save as CSV
    if nargin >= 2 && ~isempty(blocksfile) && ischar(blocksfile)
        dlmwrite(blocksfile,B,'precision','%d');
    end
    
    % Print a simplified report if requested
    if nargin >= 5 && showreport
        fprintf('Family type,Count,Sibship size,Number of subjects,Abbreviated description\n');
        U = unique(B(:,2));
        for u = 1:size(U,1)
            switch U(u)
                case 10,   abbrv = '1 NS';
                case 20,   abbrv = '2 FS';
                case 30,   abbrv = '3 FS';
                case 200,  abbrv = '2 DZ';
                case 210,  abbrv = '2 DZ + 1 FS';
                case 2000, abbrv = '2 MZ';
                case 2010, abbrv = '2 MZ + 1 FS';
            end
            nP = numel(unique(B(B(:,2) == U(u),3)));
            nS = sum(B(:,2) == U(u));
            fprintf('%d,%d,%d,%d,%s\n',U(u),nP,nS/nP,nS,abbrv);
        end
    end
    
    warning on backtrace
    end
    % =========================================================================
    function [mapped,map] = str2map(X)
    % Take a cell array with strings and replace them for integers,
    % while recording the original strings into a map, such that
    % X = map(mapped). Missing values in X are indexed as NaN,
    % meaning that the reverse process isn't trivial as above if there
    % are missing entries.
    inan = cell2mat(cellfun(@checknan,X,'UniformOutput',false));
    X(inan) = {''};
    [map,~,mapped] = unique(X);
    end
    
    % =========================================================================
    function result = checknan(x)
    result = any(isnan(x));
    end
    
    % =========================================================================
    function [equal,miss1,miss2] = cellstrcmpi(C1,C2)
    % Do strcmpi on two vectors of cells.
    size1 = sort(size(C1));
    size2 = sort(size(C2));
    if size1(1) ~= 1 || size2(1) ~= 1
        error('Only cell-vectors are accepted.')
    end
    if size1(2) < size2(2)
        A = C1;
        B = C2;
        equal = false(size2(2),size1(2));
        swapped = false;
    else
        A = C2;
        B = C1;
        equal = false(size1(2),size2(2));
        swapped = true;
    end
    
    for a = 1:numel(A)
        equal(:,a) = strcmpi(A{a},B);
    end
    
    if swapped
        miss1 = ~ any(equal,2);
        miss2 = ~ any(equal,1);
    else
        equal = equal';
        miss1 = ~ any(equal,1);
        miss2 = ~ any(equal,2);
    end
    end
    % =========================================================================
    % That's it! :-)