function asinh2binary
hmsg1=msgbox('Choose asinh CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end

T1=readtable([filepath filename]);
T2=T1(:,4:end);
signal_names=T1.Properties.VariableNames;
numsignals=length(signal_names);

%Threshold to compare
threshold = asinh(1/0.8);

binarydat=T2{:,:}>threshold;
binaryT=T1;
binaryT{:,4:end}=binarydat;
binaryT.Properties.VariableNames=signal_names;

writetable(binaryT,[filepath 'binary_' filename])
end


