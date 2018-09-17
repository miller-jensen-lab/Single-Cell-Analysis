function outDATA=SC_asinh(varargin)
%Transform SC data using arcsinh, with a cofactor set proportional to
%threshold (background) levels (divided by 0.8)
%Threshold is always asinh(1/0.8)

%Varargin{1} is the data to be transformed
%Varargin{2} is the table containing the thresholds.

if isempty(varargin)
    %Import thresholded csv because it was called externally
    hmsg1=msgbox('Choose CSV to transform','help','modal');
    uiwait(hmsg1)
    [filename, filepath]= uigetfile('*.csv');
    if isequal(filename,0) || isequal(filepath,0)
        disp('User pressed cancel')
        return;
    end
    
    DATA=readtable([filepath filename]);
    
    hmsg2=msgbox('Choose Threshold CSV','help','modal');
    uiwait(hmsg2)
    [threshname, threshpath]= uigetfile('*.csv','Choose Threshold CSV',filepath);
    if isequal(threshname,0) || isequal(threshpath,0)
        disp('User pressed cancel')
        return;
    end
    
    Thresholds=readtable([threshpath threshname],'ReadRowNames',1);
    
else
    DATA=varargin{1};
    Thresholds=varargin{2};
end

%Preallocate variables
signal_data=zeros(size(DATA(:,4:end)));
signal_names=Thresholds.Properties.VariableNames;
num_signals=length(signal_names);

for j=1:num_signals;
        cofactor=Thresholds{1,j}*0.8;
        %Transform data and thresholds via asinh with cofactor
        signal_data(:,j)=asinh(DATA{:,j+3}/cofactor);
end
%Export back totable
outDATA=DATA;
outDATA{:,4:end}=signal_data; %This data contains all transformed data



if isempty(varargin)
    %Only if function called externally without talbe inputes. Otherwise just output the data and
    %save in normalization file.
    %Save files
    newname= [filename(1:end-4) ' asinhTransformed.csv'];
    %Export all data as csv
    writetable(outDATA, [filepath, newname])
    
    outDATA1cell=outDATA(outDATA.Cell_Count==1,:); %This only contains 1 cell data
    %Export as fcs for single cell only
    table_to_fcs(outDATA1cell,[filepath newname(1:end-4)]);
end

