function outTable=removesilentcells(varargin)
%Removes completely silent cells from 1 cell data
if isempty(varargin)
    %Import thresholded csv because it was called externally
    hmsg1=msgbox('Choose Normalized CSV','help','modal');
    uiwait(hmsg1)
    [filename, filepath]= uigetfile('*.csv');
    if isequal(filename,0) || isequal(filepath,0)
        disp('User pressed cancel')
        return;
    end
    
    DATA=readtable([filepath filename]);
    thresholded_name=[filename(1:end-22) ' Thresholded Signal.csv'];
    
    ThreshDATA=readtable([filepath thresholded_name]);
    
else
    %Function called within SC software, DATA passed directly
    DATA=varargin{1};
    ThreshDATA=varargin{2};
end

%Find only non-zero rows
ind=sum(ThreshDATA{:,4:end},2)>0;
%Combine with 1 cell index
finalind=ind & DATA{:,3}==1;

%This inclues all cells with at least one active cytokine for 1 cell data
%only
outTable=DATA(finalind,:);

%Only if called externally do you save files
if isempty(varargin)
    %Save files
    newname= [filename(1:end-22) ' OnlyON.csv'];
    writetable(outTable, [filepath, newname])
    %Export as fcs
    table_to_fcs(outTable,[filepath newname(1:end-4)]);
end