%SC_multifunctionality
clear all
hmsg1=msgbox('Choose Binary CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end

%% 
binaryT=readtable([filepath filename]);
binaryTonecell=binaryT(binaryT.Cell_Count==1,:);
%% only to remove variables you don't want included
% binaryTonecell.TNF_a=[];
% binaryTonecell.TGF_b=[];
%%
binarymat=binaryTonecell{:,4:end-1};

output=NaN(4,1);
output(1)=sum(sum(binarymat,2)==0)/length(binarymat);
output(2)=sum(sum(binarymat,2)==1)/length(binarymat);
output(3)=sum(sum(binarymat,2)==2)/length(binarymat);
output(4)=sum(sum(binarymat,2)>=3)/length(binarymat);
rowlbls={'0','1','2','3+'}';
T=table(rowlbls,round(output*100,2));
T.Properties.VariableNames={'Secreting_num','Fraction_cells'}

