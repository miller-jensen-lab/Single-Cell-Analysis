%Script to make thresholded asinh files for DREMI
%Will read CSV file, change all data points below threshold to the
%threshold
%Make sure 
clear;
hmsg1=msgbox('Choose asinh CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end
T=readtable([filepath filename]);

data=T{:,4:end};
data(data<asinh(1/0.8))=asinh(1/0.8);

newT=T;
newT{:,4:end}=data;
newTonecell=newT(newT.Cell_Count==1,:);

writetable(newT,[filepath filename(1:end-4) '_denoise.csv']);
writetable(newTonecell,[filepath filename(1:end-4) '_denoise1cell.csv']);
table_to_fcs(newTonecell,[filepath filename(1:end-4) '_denoise1cell']);