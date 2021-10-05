addpath(genpath('/data/NIMH_scratch/abcd_cca/abcd_cca_replication/dependencies/FSLNets/'));
addpath(genpath('/usr/local/apps/fsl/6.0.4/etc/matlab'));
SUMPICS_lesssum = '/data/NIMH_scratch/abcd_cca/abcd_cca_replication/data_prep/data/stage_3/5013.gica/melodic_IC_thin';

I=2;  % CCA mode
grotAA = corr(U, N0)';

% display top edges and create weights matrix ZnetMOD
grot=zeros(fslnets_mat.ts.Nnodes);
grot(triu(ones(fslnets_mat.ts.Nnodes),1)>0)=grotAA(:,I);  %%/max(abs(grotAA(:,I)));

ZnetMOD=grot+grot';  

Znet1   =   fslnets_mat.Znet1;
Mnet1   =   fslnets_mat.Mnet1;
Znet2   =   fslnets_mat.Znet2;
Mnet2   =   fslnets_mat.Mnet2;

[hierALL, linkagesALL] = nets_hierarchy( Znet1, Znet2, fslnets_mat.ts.DD, SUMPICS, 1.5);
clustersALL =   cluster(linkagesALL, 'maxclust', 4)';

%%
%mel = read_awv('/data/NIMH_scratch/abcd_cca/abcd_cca_replication/data_prep/data/stage_3/5013.gica/melodic_IC')

%% select top-30 CCA-edges (list of nodes goes into grotDD)
grot=ZnetMOD;

grotTHRESH=prctile(abs(grot(:)),99.885) % top 30 edges

grot(abs(grot)<grotTHRESH)=0;
grotDD=find(sum(grot~=0)>0);

grot=grot(grotDD,grotDD);

grot1=Znet1;
grot1=grot1(grotDD,grotDD);
grot1=grot1/max(abs(grot1(:)));
for i=1:size(grot1,1)
    for j=1:size(grot1,1)
        if clustersALL(grotDD(i)) == clustersALL(grotDD(j))
            grot1(i,j)=grot1(i,j)+1;
        end
    end
end

[hier,linkages] = nets_hierarchy(grot1,grot*3,grotDD,SUMPICS,0.75); 
set(gcf,'PaperPositionMode','auto','Position',[10 10 2800 2000]);   %print('-dpng',sprintf('%s/edgemodhier.png','/home/fs0/steve'));
clusters=cluster(linkages,'maxclust',4)';

%%

netjs_name = 'top30_ABCD';
mkdir(netjs_name)

netjs_subdir = [netjs_name '/data/dataset1'];
mkdir(netjs_subdir)

slicedir = [netjs_subdir '/melodic_IC_sum.sum'];
mkdir(slicedir)

NP = netjs_subdir;

grotZnet4=grot.*sign(Mnet2(grotDD,grotDD));  save(sprintf('%s/Znet4.txt',NP),'grotZnet4','-ascii');
grotZnet3=grot;  save(sprintf('%s/Znet3.txt',NP),'grotZnet3','-ascii');
grotZnet1=Mnet1(grotDD,grotDD);              save(sprintf('%s/Znet1.txt',NP),'grotZnet1','-ascii');
grotZnet2=Mnet2(grotDD,grotDD);              save(sprintf('%s/Znet2.txt',NP),'grotZnet2','-ascii');
save(sprintf('%s/hier.txt',NP),'hier','-ascii');
save(sprintf('%s/linkages.txt',NP),'linkages','-ascii');
save(sprintf('%s/clusters.txt',NP),'clusters','-ascii');
for i=1:length(grotDD)
   system(sprintf('/bin/cp %s/%.4d.png %s/melodic_IC_sum.sum/%.4d.png',SUMPICS,grotDD(i)-1,NP,i-1));
end

nets_netweb(Znet1, Znet2, fslnets_mat.ts.DD, SUMPICS_lesssum, netjs_root)
nets_netweb(grotZnet1, grotZnet2, grotDD, SUMPICS_lesssum, 'top30')

