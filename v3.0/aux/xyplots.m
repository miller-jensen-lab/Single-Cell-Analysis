titlebar='Enter a value';
userprompt={'How many groups are in this experiment?'};
num_groups=NaN;
while isnan(num_groups)
    userinput=inputdlg(userprompt,titlebar,1,{'2'});
    if isempty(userinput)
        %user pressed cancel
        
        return;
    end
num_groups=str2double(userinput);
    if isnan(num_groups)
        hwait=warndlg('Please input a number!','Warning','modal');
        uiwait(hwait);
    end
end

%Name the groups
prompt2=strcat('Group',cellstr(num2str([1:num_groups]')));
title2='Enter the group names';
group_names=inputdlg(prompt2,title2,1);

%Load files and extract the tables and data
for i=1:num_groups;
    [filename, filepath]= uigetfile('*.mat',sprintf(...
        'Choose %s Analysis file',group_names{i}));
    if isequal(filename,0) || isequal(filepath,0)
        disp('User pressed cancel')
        return;
    end
    load([filepath filename]);
    gname=matlab.lang.makeValidName(group_names{i});
    Tables.(gname)=output.cleansignal_table;
        onecell_ind.(gname)=Tables.(gname).Cell_Count==1;
%     twocell_ind=Tables.(gname).Cell_Count~=0 & ...
%        Tables.(gname).Cell_Count~=1;
%     threecell_ind=Tables.(gname).Cell_Count==3;
%     twothreeind=twocell_ind|threecell_ind;
%     Data.(gname)=Tables.(gname){onecell_ind,4:end};
    csvpath=([output.filesfolder output.filename(1:end-4) ...
        ' Extracted Data/']);
    BinaryT.(gname)=readtable([csvpath output.filename(1:end-4) ...
        ' Binary Signal.csv'],'ReadRowNames',0);
    Thresholds.(gname)=readtable([csvpath output.filename(1:end-4) ...
        ' Thresholds.csv'],'ReadRowNames',1);
%     BinaryData.(gname)=BinaryT{onecell_ind,4:end};
end

signal_names=Tables.(gname).Properties.VariableNames(4:end);
mgroup_names=fields(Tables);
%% Graphing
close
hf=figure;
screenpos=get(0,'Screensize')
set(hf, 'Position',[screenpos(1) screenpos(2) screenpos(4) screenpos(4)]); % Maximize figure.
% set(hf,'units','normalized','outerposition',[0 0 1 1]);
% set(hf,'PaperUnits','pixels',...
%      'PaperPosition',get(0,'Screensize'));
set(hf,'Units','centimeters');
set(hf,'PaperPositionMode','manual','PaperUnits','centimeters')
pos=get(hf,'Position');

set(hf,'PaperSize',[pos(3) pos(4)], 'PaperPosition',[0 0 pos(3) pos(4)]);
set(hf,'Units','normalized');
haxtight=tight_subplot(3,3,[0.08 -.5],0.05,-.2);
 for i=1:length(mgroup_names)

cg=mgroup_names{i};
xdata=Tables.(cg).CCL2(onecell_ind.(cg));
ydata=Tables.(cg).CCL5(onecell_ind.(cg));
binaryCCL2=logical(BinaryT.(cg).CCL2(onecell_ind.(cg)));
binaryCCL5=logical(BinaryT.(cg).CCL5(onecell_ind.(cg)));
binaryTNF=logical(BinaryT.(cg).TNF(onecell_ind.(cg)));
binaryIL12=logical(BinaryT.(cg).IL_12(onecell_ind.(cg)));
binaryChi3l3=logical(BinaryT.(cg).Chi3l3(onecell_ind.(cg)));
a=25;
cgray=[0.7 0.7 0.7];
CCL2th=Thresholds.(cg).CCL2(2);
CCL5th=Thresholds.(cg).CCL5(2);
llquad=binaryCCL2==0 & binaryCCL5==0;
ulquad=binaryCCL2==0 & binaryCCL5==1;
urquad=binaryCCL2==1 & binaryCCL5==1;
lrquad=binaryCCL2==1 & binaryCCL5==0;


c=repmat(cgray,length(xdata),1);
c(binaryTNF,1)=1;
c(binaryTNF,2)=0;
c(binaryTNF,3)=0;
zdata=double(binaryTNF);
% hax=tight_subplot(3,3,0.05,0.05,0.05);
axes(haxtight(i))
hax=gca;
hs=scatter(xdata,ydata,a,c,'filled');
set(gca,'XScale','log');
set(gca,'YScale','log');
set(gca,'Box','on');
hs.ZData=zdata;
boundsx=xlim;
boundsy=ylim;
% drawnow
axis square
axespos=plotboxpos(gca);
lineccl2=line([CCL2th CCL2th],boundsy);
lineccl5=line(boundsx,[CCL5th CCL5th]);
xlabel('CCL2','FontSize',14,'FontWeight','bold');
ylabel('CCL5','FontSize',14,'FontWeight','bold');
title([cg ' TNF'],'FontSize',14,'FontWeight','bold');
llstring=sprintf('%.1f%%',(sum(llquad & binaryTNF)./sum(binaryTNF))*100);
ulstring=sprintf('%.1f%%',(sum(ulquad & binaryTNF)./sum(binaryTNF))*100);
urstring=sprintf('%.1f%%',(sum(urquad & binaryTNF)./sum(binaryTNF))*100);
lrstring=sprintf('%.1f%%',(sum(lrquad & binaryTNF)./sum(binaryTNF))*100);
lldim=[axespos(1)+.01 axespos(2) 0.01 0.01];
uldim=[axespos(1)+.01 axespos(2)+axespos(4)-0.01 0.01 0.01];
urdim=[axespos(1)+axespos(3)-0.02 axespos(2)+axespos(4)-0.01 0.01 0.01];
lrdim=[axespos(1)+axespos(3)-0.02 axespos(2) 0.01 0.01];
annotation('textbox',lldim,'String',llstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','FontSize',12);
annotation('textbox',uldim,'String',ulstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','FontSize',12);
annotation('textbox',urdim,'String',urstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','HorizontalAlignment',...
    'right','FontSize',12);
annotation('textbox',lrdim,'String',lrstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','HorizontalAlignment',...
    'right','FontSize',12);

c=repmat(cgray,length(xdata),1);
c(binaryIL12,1)=1;
c(binaryIL12,2)=0;
c(binaryIL12,3)=0;
zdata=double(binaryIL12);
% hax=subplot(3,3,i+3);
axes(haxtight(i+3))
hax=gca;
hs=scatter(xdata,ydata,a,c,'filled');
set(gca,'XScale','log');
set(gca,'YScale','log');
set(gca,'Box','on');
hs.ZData=zdata;
lineccl2=line([CCL2th CCL2th],boundsy);
lineccl5=line(boundsx,[CCL5th CCL5th]);
xlabel('CCL2','FontSize',14,'FontWeight','bold');
ylabel('CCL5','FontSize',14,'FontWeight','bold');
title([cg ' IL12'],'FontSize',14,'FontWeight','bold')
axis square
axespos=plotboxpos(hax);
llstring=sprintf('%.2f%%',(sum(llquad & binaryIL12)./sum(binaryIL12))*100);
ulstring=sprintf('%.2f%%',(sum(ulquad & binaryIL12)./sum(binaryIL12))*100);
urstring=sprintf('%.2f%%',(sum(urquad & binaryIL12)./sum(binaryIL12))*100);
lrstring=sprintf('%.2f%%',(sum(lrquad & binaryIL12)./sum(binaryIL12))*100);
lldim=[axespos(1)+.01 axespos(2) 0.01 0.01];
uldim=[axespos(1)+.01 axespos(2)+axespos(4)-0.01 0.01 0.01];
urdim=[axespos(1)+axespos(3)-0.02 axespos(2)+axespos(4)-0.01 0.01 0.01];
lrdim=[axespos(1)+axespos(3)-0.02 axespos(2) 0.01 0.01];
annotation('textbox',lldim,'String',llstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','FontSize',12);
annotation('textbox',uldim,'String',ulstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','FontSize',12);
annotation('textbox',urdim,'String',urstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','HorizontalAlignment',...
    'right','FontSize',12);
annotation('textbox',lrdim,'String',lrstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','HorizontalAlignment',...
    'right','FontSize',12);


c=repmat(cgray,length(xdata),1);
c(binaryChi3l3,1)=1;
c(binaryChi3l3,2)=0;
c(binaryChi3l3,3)=0;
zdata=double(binaryChi3l3);
% hax=subplot(3,3,i+6);
axes(haxtight(i+6))
hax=gca;
hs=scatter(xdata,ydata,a,c,'filled');
set(gca,'XScale','log');
set(gca,'YScale','log');
set(gca,'Box','on');
hs.ZData=zdata;
lineccl2=line([CCL2th CCL2th],boundsy);
lineccl5=line(boundsx,[CCL5th CCL5th]);
xlabel('CCL2','FontSize',14,'FontWeight','bold');
ylabel('CCL5','FontSize',14,'FontWeight','bold');
title([cg ' Chi3l3'],'FontSize',14,'FontWeight','bold')
axis square
axespos=plotboxpos(hax);
llstring=sprintf('%.2f%%',(sum(llquad & binaryChi3l3)./sum(binaryChi3l3))*100);
ulstring=sprintf('%.2f%%',(sum(ulquad & binaryChi3l3)./sum(binaryChi3l3))*100);
urstring=sprintf('%.2f%%',(sum(urquad & binaryChi3l3)./sum(binaryChi3l3))*100);
lrstring=sprintf('%.2f%%',(sum(lrquad & binaryChi3l3)./sum(binaryChi3l3))*100);
lldim=[axespos(1)+.01 axespos(2) 0.01 0.01];
uldim=[axespos(1)+.01 axespos(2)+axespos(4)-0.01 0.01 0.01];
urdim=[axespos(1)+axespos(3)-0.02 axespos(2)+axespos(4)-0.01 0.01 0.01];
lrdim=[axespos(1)+axespos(3)-0.02 axespos(2) 0.01 0.01];
annotation('textbox',lldim,'String',llstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','FontSize',12);
annotation('textbox',uldim,'String',ulstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','FontSize',12);
annotation('textbox',urdim,'String',urstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','top','HorizontalAlignment',...
    'right','FontSize',12);
annotation('textbox',lrdim,'String',lrstring,'FitBoxToText','on',...
    'LineStyle','none','VerticalAlignment','bottom','HorizontalAlignment',...
    'right','FontSize',12);
end
saveas(hf,'ccl2vsccl5matrix.pdf','pdf')
