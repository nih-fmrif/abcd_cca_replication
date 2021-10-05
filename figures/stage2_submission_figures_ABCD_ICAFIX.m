% Need to have
% /data/NIMH_scratch/abcd_cca/abcd_cca_replication/smith_cca_analysis/abcd_cca_interactive.m in the
% workspace

%% ABCD - Figure 2
% correlation between U and V of mode 1 and 2
% points colored by fluid intelligence

% find fluid intelligence score
index=find(strcmpi(VARS_0(1,:),'nihtbx_fluidcomp_fc'));
g_f=S1(:,index);

figure;

% mode 1
subplot(1,2,1)
g_f_n = palm_inormal(g_f);
scatter(-1.*U(:,1),-1.*V(:,1),15, g_f_n,'filled')
cmap=colormap(jet(100));
cb=colorbar();
cb.Ticks = [min(g_f_n),max(g_f_n)];
cb.TickLabels = {'-3.6','3.6'};
set(cb,'FontSize',17);
%th = title('Mode 1');
%titlePos = get(th,'position');
%titlePos1 = titlePos + [0 1 0];
%set(th, 'position', titlePos1);
xlabel('CCA Weights (Connectomes)');
ylabel('CCA Weights (Subject measures)');
xticks([-5 -3 -1 1 3 5])
xlim([-5 5])
yticks([-5 -3 -1 1 3 5])
ylim([-5 5])
set(gca,'FontSize',16)

% mode 2
subplot(1,2,2)
g_f_n = palm_inormal(g_f);
scatter(-1.*U(:,2),-1.*V(:,2),15, g_f_n,'filled') % NOTE: negated vectors are plotted
cmap=colormap(jet(100));               
cb=colorbar();
cb.Ticks = [min(g_f_n),max(g_f_n)];
cb.TickLabels = {'-3.6','3.6'};
set(cb,'FontSize',17);
ylabel(cb,'Fluid Cognition Score');
%th = title('Mode 2');
%titlePos = get(th,'position');
%titlePos1 = titlePos + [0 1 0];
%set(th, 'position', titlePos1);
xlabel('CCA Weights (Connectomes)');
ylabel('CCA Weights (Subject measures)');
xticks([-5 -3 -1 1 3 5])
xlim([-5 5])
yticks([-5 -3 -1 1 3 5])
ylim([-5 5])
set(gca,'FontSize',16)

% overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=14;
h=5;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);


saveas(gcf, './Figure_2.svg');

%% ABCD - Figure 2 (supplemental) modes 3 and 4

% correlation between U and V of mode 3 and 4
% points colored by fluid intelligence

% find fluid intelligence score
index=find(strcmpi(VARS_0(1,:),'nihtbx_fluidcomp_fc'));
g_f=S1(:,index);

figure;

% mode 3
subplot(1,2,1)
g_f_n = palm_inormal(g_f);
scatter(-1.*U(:,3),-1.*V(:,3),15, g_f_n,'filled')
cmap=colormap(jet(100));
cb=colorbar();
cb.Ticks = [min(g_f_n),max(g_f_n)];
cb.TickLabels = {'-3.6','3.6'};
set(cb,'FontSize',17);
%th = title('Mode 3');
%titlePos = get(th,'position');
%titlePos1 = titlePos + [0 0.15 0];
%set(th, 'position', titlePos1);
xlabel('CCA Weights (Connectomes)');
ylabel('CCA Weights (Subject measures)');
xticks([-5 -3 -1 1 3 5])
xlim([-5 5])
yticks([-5 -3 -1 1 3 5])
ylim([-5 5])
set(gca,'FontSize',16)

% mode 4
subplot(1,2,2)
g_f_n = palm_inormal(g_f);
scatter(-1.*U(:,4),-1.*V(:,4),15, g_f_n,'filled') % NOTE: negated vectors are plotted
cmap=colormap(jet(100));               
cb=colorbar();
cb.Ticks = [min(g_f_n),max(g_f_n)];
cb.TickLabels = {'-3.6','3.6'};
set(cb,'FontSize',17);
ylabel(cb,'Fluid Cognition Score');
%th = title('Mode 4');
%titlePos = get(th,'position');
%titlePos1 = titlePos + [0 0.15 0];
%set(th, 'position', titlePos1);
xlabel('CCA Weights (Connectomes)');
ylabel('CCA Weights (Subject measures)');
xticks([-5 -3 -1 1 3 5])
xlim([-5 5])
yticks([-5 -3 -1 1 3 5])
ylim([-5 5])
set(gca,'FontSize',16)

% overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=14;
h=5;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);

saveas(gcf, './Figure_2_supp.svg');

%% ABCD - Figure 3
% variance and permutation analysis for SM and connectome

% Look at first 20 modes
I=1:20;

% Connectomes variance
figure;
subplot(2,1,1); 
hold on;
% Draw the rectangles for null distributions per mode
for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_NET(2,i) 1 variance_data_NET(4,i)-variance_data_NET(2,i)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
end
plot(variance_data_NET(3,I),'k');
plot(variance_data_NET(1,I),'b');
plot(variance_data_NET(1,I),'b.');
th1 = title({'Connectome variance explained by CCA modes';''});
%ylabel('% variance');
xlabel('CCA Mode')
xlim([0 21])
ylim([0.05 0.10])
yticks([0.06 0.07 0.08 0.09 0.10])
ytickformat('%.2f')
set(gca,'FontSize',12)


% Subject measures variance
subplot(2,1,2); 
hold on;
for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_VARS(2,i) 1 variance_data_VARS(4,i)-variance_data_VARS(2,i)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
end
plot(variance_data_VARS(3,I),'k');
plot(variance_data_VARS(1,I),'b');
plot(variance_data_VARS(1,I),'b.');
th1 = title({'SM variance explained by CCA modes';''});
%ylabel('% variance');
xlabel('CCA Mode');
xlim([0 21])
ylim([0 6])
yticks([0.00 1.00 2.00 3.00 4.00 5.00 6.00])
ytickformat('%.2f')
set(gca,'FontSize',12)

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=7;
h=7;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
saveas(gcf, './Figure_3.svg');

%% ABCD - Figure 4 positive-negative axis

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode2_thresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=12;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './Figure_4.svg');

%% positive-negative axis threshold Mode 1

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode1_thresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=4;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode1_thresh.svg');

%% positive-negative axis threshold Mode 3

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode3_thresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=8;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode3_thresh.svg');

%% positive-negative axis threshold Mode 4

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode4_thresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=6;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode4_thresh.svg');

%% ABCD - Mode 1 positive-negative axis no thresh

figure;
load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode1_nothresh.mat')

% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=16;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode1_nothresh.svg');

%% positive-negative axis no threshold Mode 2

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode2_nothresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=16;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode2_nothresh.svg');

%% positive-negative axis no threshold Mode 3

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode3_nothresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=16;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode3_nothresh.svg');

%% positive-negative axis no threshold Mode 4

load('./pneg_tables/ABCD_ICA-FIX_Pneg_Mode4_nothresh.mat')

figure;
% visual settings/controls
xmax = 10 ;
fsizemin = 12 ;
fsizemax = 32 ;
inccolor = [0.0 0.4470 0.7410] ;
exccolor = [0.5 0.5000 0.5000] ;
VA = 'top' ;

% normalization of font sizes
varmin = min(t.variance) ;
varmax = max(t.variance) ;
slope = (fsizemax - fsizemin) / (varmax - varmin) ;
intercept = fsizemin - (slope*varmin) ;

crossover = true;
for i = 1:height(t)
    if t.correlation(i) < 0 && crossover==true
        midpos = ypos ;
        ypos = ypos-fsizemax ;
        contpos = ypos ;
        crossover = false ;
    end

    fsize=round( slope*t.variance(i) + intercept ) ;

    if i==1
        ypos = 0 ;
    else
        ypos = ypos-fsize ;
    end

    if t.include(i)=='1'
        color = inccolor ;
    else
        color = exccolor ;
    end

    text(xmax/2, ypos, t.name{i}, ...
        'FontSize', fsize, ...
        'Color', color, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'none') ;

end

fsize = round((fsizemax-fsizemin)/2);
text(xmax/10, midpos, 'Included in CCA', ...
    'FontSize', fsize, ...
    'Color', inccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = midpos-fsizemin ;
text(xmax/10, newpos, 'Excluded', ...
    'FontSize', fsize, ...
    'Color', exccolor, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, 'Variance explained:', ...
    'FontSize', fsize, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-fsizemin ;
text(xmax/10, newpos, [num2str(round(varmin*100)) '%'], ...
    'FontSize', fsizemin, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

newpos = newpos-floor(fsizemin/2) ;
text(xmax/10, newpos, [num2str(round(varmax*100)) '%'], ...
    'FontSize', fsizemax, ...
    'Color', 'black', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', VA, ...
    'Interpreter', 'none') ;

xlim([0 xmax])
ylim([ypos 0])

% Overall figure settings
set(gcf, 'Units', 'inches');
papersize = get(gcf, 'PaperSize');
w=10;
h=16;
left = (papersize(1)- w)/2;
bottom = (papersize(2)- h)/2;
myfiguresize = [left, bottom, w, h];
set(gcf, 'Position', myfiguresize);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', myfiguresize);
set(gca, 'visible', 'off');
saveas(gcf, './ABCD-ICAFIX_Pneg_Mode4_nothresh.svg');

