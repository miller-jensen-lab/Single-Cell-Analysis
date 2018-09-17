%Getting MFI of secreting cells only
function getMFI_SC
hmsg1=msgbox('Choose asinh CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end

T1=readtable([filepath filename]);
T2=T1(T1.Cell_Count==1,4:end);
signal_names=T2.Properties.VariableNames;
numsignals=length(signal_names);

binarydat=T2{:,:}>asinh(1/0.8);
binaryT=array2table(binarydat);
binaryT.Properties.VariableNames=signal_names;

MFI=NaN(1,numsignals);
for i=1:numsignals
    MFI(i)=mean(T2{binaryT{:,i},i});
end

MFI_T=array2table(MFI);
MFI_T.Properties.VariableNames=signal_names;
writetable(MFI_T,['MFI_secretingcells_' filename]);

end

