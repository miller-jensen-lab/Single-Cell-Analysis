%Binary conditional probabilites
%Working with binary data
clear all;
hmsg1=msgbox('Choose asinh CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end
T=readtable([filepath filename]);
% binaryT=T;
% binaryT{:,:}=T{:,:}>0;

%Alternate version if you're loading non-thresholded file
binaryT=T;
binaryT{:,4:end}=T{:,4:end}>asinh(1/0.8);
% binaryT{:,4:end}=T{:,4:end}>2;

data1cell=binaryT{T.Cell_Count==1,4:end};
signal_names=binaryT.Properties.VariableNames(4:end);

numsignals=size(data1cell,2);
Numcells=size(data1cell,1);
condp=zeros(numsignals);
condpneg=zeros(numsignals);
%Conditional prob for + cells
for a=1:numsignals
    for b=1:numsignals
        pandb=sum(data1cell(:,a)&data1cell(:,b))/Numcells;
        pb=sum(data1cell(:,b))/Numcells;
        condp(a,b)=round((pandb/pb)*100,2);
    end
end
%Conditional prob for - cells
for a=1:numsignals
    for b=1:numsignals
        pandb=sum(data1cell(:,a)&~data1cell(:,b))/Numcells;
        pb=sum(~data1cell(:,b))/Numcells;
        condpneg(a,b)=round((pandb/pb)*100,2);
    end
end

T_condp=array2table(condp,'VariableNames',signal_names,'RowNames',signal_names);
T_condpneg=array2table(condpneg,'VariableNames',signal_names,'RowNames',signal_names);


log2FC_cp=log2(T_condp{:,:}./T_condpneg{:,:});
T_log2FC=array2table(log2FC_cp,'VariableNames',signal_names,'RowNames',signal_names);
writetable(T_log2FC,'M1+M2_24hrhigh2_log2FC.csv','WriteRowNames',1);


