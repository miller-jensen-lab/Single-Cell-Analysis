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
data1cell=binaryT{T.Cell_Count==1,4:end};
signal_names=binaryT.Properties.VariableNames(4:end);

numsignals=size(data1cell,2);
Numcells=size(data1cell,1);
pandb=zeros(numsignals);
pa_x_pb=zeros(numsignals);
chiresults=zeros(numsignals);

for a=1:numsignals
    for b=1:numsignals
        pandb(a,b)=mean(data1cell(:,a)&data1cell(:,b));
        pa_x_pb(a,b)=mean(data1cell(:,a))*mean(data1cell(:,b));
        [~,~,chi2]=crosstab(data1cell(:,a),data1cell(:,b));
        chiresults(a,b)=chi2;
    end
end

log2FC_p=log2(pandb./pa_x_pb);
T_pandb=array2table(pandb,'VariableNames',signal_names,'RowNames',signal_names);
T_paxpb=array2table(pa_x_pb,'VariableNames',signal_names,'RowNames',signal_names);
T_log2FC=array2table(log2FC_p,'VariableNames',signal_names,'RowNames',signal_names);
T_chi=array2table(chiresults,'VariableNames',signal_names,'RowNames',signal_names);