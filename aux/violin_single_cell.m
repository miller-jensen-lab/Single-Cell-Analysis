% violin_single_cell
clear;
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
title2='Enter the group names';
group_names=inputdlg(prompt2,title2,1);
if isempty(group_names);
    return
end
xline=zeros(2,num_groups);
yline=xline;


for i=1:num_groups;
    hmsg1=msgbox(sprintf('Choose asinh CSV for %s',group_names{i}),'help','modal');
    uiwait(hmsg1)
    [filename, filepath]= uigetfile('*.csv');
    if isequal(filename,0) || isequal(filepath,0)
        disp('User pressed cancel')
        return;
    end
    %     load([filepath filename]);
    gname=matlab.lang.makeValidName(group_names{i});
    basicname=filename(1:end-21);
    Tables.(gname)=readtable([filepath filename]);
    onecell_ind=Tables.(gname).Cell_Count==1;
    Data.(gname)=Tables.(gname)(onecell_ind,:);
    %Clean the Data to remove cell counts, row numbers, col numbers, and
    %Identifiers if present
    for ci=1:4
        cleancheck={'Column_n','Row_n','Cell_Count','Identifier'};
        if ismember(cleancheck{ci},Data.(gname).Properties.VariableNames)
            Data.(gname).(cleancheck{ci})=[];
        end
    end
    %     csvpath=([output.filesfolder output.filename(1:end-4) ' Extracted Data/']);
    %     Thresholds.(gname)=readtable([filepath basicname ' Thresholds.csv'],'ReadRowNames',1);
    %     Thresholds.(gname)=Thresholds.(gname){2,:};
    %     OnCounts.(gname)=readtable([filepath basicname ' OnCounts.csv'],'ReadRowNames',1);
    %     OnCounts.(gname)=OnCounts.(gname){2,2:end};
    xline(:,i)=[i-.45 i+.45]';
end

signal_names=Data.(gname).Properties.VariableNames;
num_signals=length(signal_names);
num_figures=ceil(num_signals/6);
true_groups=fields(Data);
signal_data=cell(1,num_groups);
ontext=cell(1,num_groups);
xtext=1:num_groups;
ytext=zeros(size(xtext));
% cofactor=150;
thresh=asinh(1/0.8);
close all;

for n=1:num_figures;
    hfig{n}=figure;
    scnsize=get(0,'ScreenSize');
    %     figwidth=(1)*scnsize(4);
    hfig{n}.Position=[0 0 scnsize(4)*0.9*(8.5/11) scnsize(4)*0.9];  %Maximize screen figure to letter size.
    hfig{n}.Units='inches';
    hfig{n}.PaperSize=hfig{n}.Position(3:4);
    hfig{n}.Units='pixels';
    
end
graph_colors={'b','r','g','m','c'};


for j=1:num_signals;
    fignchooser=ceil(j/6);
    figure(hfig{fignchooser})
    k=j-(6*(fignchooser-1));
    haxis.(signal_names{j})=subplot(3,2,k,'Parent',hfig{fignchooser});
    for i=1:num_groups
        %Set cofactor for normalization based on threshold
        %         thresh=Thresholds.(true_groups{i}).(signal_names{j})(1);%thresh=Thresholds.(true_groups{i}){1,j};
        %         cofactor=thresh*0.8;
        % Data is already transformed...
        signal_data{i}=Data.(true_groups{i}).(signal_names{j});%signal_data{i}=Data.(true_groups{i})(:,j);
        yline(:,i)=thresh;
        oncount(i)=(mean(signal_data{i}>thresh))*100;
        ontext{i}=sprintf('%.2f%%',oncount(i));
        %         ontext{i}=sprintf('%.2f%%',OnCounts.(true_groups{i}).(signal_names{j})(2));%OnCounts.(true_groups{i}){2,j+1});
    end
    violin.(signal_names{j})=...
        distributionPlot(signal_data,'globalNorm',0,'histOpt',1,'divFactor',2,...
        'xNames',group_names,'showMM',0,...
        'color',graph_colors(1:num_groups));
    title(signal_names{j},'Interpreter','none')
    %     haxis.(signal_names{j}).YScale='log';
    line(xline,yline,'Color','k','LineWidth',2);
    %     ytext(:)=max(cellfun(@max,signal_data));
    %     ytext(:)=max(cellfun(@max,signal_data))+0.1*ytext(1);
    set(gca,'Box','on','LineWidth',1.5,'FontSize',12,'FontWeight','bold',...
        'XTickLabelRotation',45)
    currax=violin.(signal_names{j}){3};
    ytext(:)=currax.YLim(1)*0.9;
    text(xtext,ytext,ontext,'horizontalAlignment','center',...
        'verticalAlignment','base','FontWeight','bold','FontSize',12);
    
end


