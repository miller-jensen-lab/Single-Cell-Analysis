%Working with binary data
clear;
hmsg1=msgbox('Choose Binary CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end
binaryT=readtable([filepath filename]);
binaryT1cell=binaryT(binaryT.Cell_Count==1,:);

%Get percentages on CCL2 CCL3 and CCL5 combination
%Preallocate table
T2=cell2table({});

%CCL2+, CCL3-, CCL5-
ind=binaryT1cell.CCL2 & ~binaryT1cell.CCL3 & ~binaryT1cell.CCL5;
T2.CCL2negneg=sum(ind)/length(ind);
%CCL2+, CCL3+, CCL5-
ind=binaryT1cell.CCL2 & binaryT1cell.CCL3 & ~binaryT1cell.CCL5;
T2.CCL2CCL3neg=sum(ind)/length(ind);
%CCL2+, CCL3+, CCL5+
ind=binaryT1cell.CCL2 & binaryT1cell.CCL3 & binaryT1cell.CCL5;
T2.CCL2CCL3CCL5=sum(ind)/length(ind);
%CCL2-, CCL3+, CCL5-
ind=~binaryT1cell.CCL2 & binaryT1cell.CCL3 & ~binaryT1cell.CCL5;
T2.negCCL3neg=sum(ind)/length(ind);
%CCL2-, CCL3+, CCL5+
ind=~binaryT1cell.CCL2 & binaryT1cell.CCL3 & binaryT1cell.CCL5;
T2.negCCL3CCL5=sum(ind)/length(ind);
%CCL2-, CCL3-, CCL5+
ind=~binaryT1cell.CCL2 & ~binaryT1cell.CCL3 & binaryT1cell.CCL5;
T2.negnegCCL5=sum(ind)/length(ind);
%CCL2-, CCL3-, CCL5-
ind=~binaryT1cell.CCL2 & ~binaryT1cell.CCL3 & ~binaryT1cell.CCL5;
T2.negnegneg=sum(ind)/length(ind);
%CCL2+, CCL3-, CCL5+
ind=binaryT1cell.CCL2 & ~binaryT1cell.CCL3 & binaryT1cell.CCL5;
T2.CCL2negCCL5=sum(ind)/length(ind)

