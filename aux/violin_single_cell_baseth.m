% violin_single_cell_baseth
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

prompt2=strcat('Group',cellstr(num2str([1:num_groups]')));
title2='Enter the group names, with the basal (control) condition first';
group_names=inputdlg(prompt2,title2,1);
if isempty(group_names);
    return
end
xline=zeros(2,num_groups);
yline=xline;


for i=1:num_groups;
    [filename, filepath]= uigetfile('*.mat',sprintf('Choose %s Analysis file',group_names{i}));
    if isequal(filename,0) || isequal(filepath,0)
        disp('User pressed cancel')
        return;
    end
    load([filepath filename]);
    gname=matlab.lang.makeValidName(group_names{i});
    Tables.(gname)=output.cleansignal_table;
    onecell_ind=Tables.(gname).Cell_Count==1;
    Data.(gname)=Tables.(gname){onecell_ind,4:end};
    question='Do you want to use a different (basal) threshold?';
    button=questdlg(question);
    if strcmpi(button,'yes') %New basal threshold
        [thname, thpath]= uigetfile('*.csv',sprintf('Choose %s Thresholds file',group_names{i}));
        csvpath=([output.filesfolder 'Extracted Data baseth/']);
        Thresholds.(gname)=readtable([thpath thname],'ReadRowNames',1);
    elseif strcmpi(button,'no')
        csvpath=([output.filesfolder 'Extracted Data/']);
        Thresholds.(gname)=readtable([csvpath 'Thresholds.csv'],'ReadRowNames',1);
    elseif strcmpi(button,'cancel')
        return;
    end
%     Thresholds.(gname)=Thresholds.(gname){2,:};
    OnCounts.(gname)=readtable([csvpath 'On Counts.csv'],'ReadRowNames',1);
%     OnCounts.(gname)=OnCounts.(gname){2,2:end};
    xline(:,i)=[i-.45 i+.45]';
end
% xline(:,i)=[0 num_groups+1]';
signal_names=Thresholds.(gname).Properties.VariableNames;
num_signals=length(signal_names);
num_figures=ceil(num_signals/6);
true_groups=fields(Data);
signal_data=cell(1,3);
ontext=cell(1,3);
xtext=1:num_groups;
ytext=zeros(size(xtext));
close all;
for n=1:num_figures;
    hfig{n}=figure;
    hfig{n}.Position=get(0,'Screensize');  %Maximize screen figure.
    set(hfig{n},'Units','centimeters'); %Fix paper size for proper printing
    set(hfig{n},'PaperPositionMode','manual','PaperUnits','centimeters')
    pos=get(hfig{n},'Position');
    
    set(hfig{n},'PaperSize',[pos(3) pos(4)], 'PaperPosition',[0 0 pos(3) pos(4)]);
    set(hfig{n},'Units','normalized');
end

graph_colors={'b','r','g','m','c'};

for j=1:num_signals;
    fignchooser=ceil(j/6);
    figure(hfig{fignchooser})
    k=j-(6*(fignchooser-1));
    haxis.(signal_names{j})=subplot(3,2,k,'Parent',hfig{fignchooser});
    for i=1:num_groups
        signal_data{i}=Data.(true_groups{i})(:,j);
        ontext{i}=sprintf('%.2f%%',OnCounts.(true_groups{i}){2,j+1});
        yline(:,i)=Thresholds.(true_groups{i}){2,j};
    end
%     yline(:,i)=Thresholds{2,j};
    violin.(signal_names{j})=...
        distributionPlot(signal_data,'globalNorm',0,'histOpt',1,... %'divFactor',2,
        'xNames',group_names,'showMM',0,...
        'color',graph_colors(1:num_groups));
    title(signal_names{j},'Interpreter','none')
    haxis.(signal_names{j}).YScale='log';
    line(xline,yline,'Color','k','LineWidth',2,'LineStyle','--');
    ytext(:)=max(cellfun(@max,signal_data));
    text(xtext,ytext,ontext,'horizontalAlignment','center',...
        'verticalAlignment','base','FontWeight','bold','FontSize',12);
end
for f=1:num_figures;
    saveas(hfig{f},sprintf('Violin%d.pdf',f),'pdf')
end







    