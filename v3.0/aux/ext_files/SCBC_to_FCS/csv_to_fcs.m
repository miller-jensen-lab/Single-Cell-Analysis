function csv_to_fcs
% csv_to_fcs(xls_filename, fcs_filename)
%
% converts a CSV file to a FCS file.

hmsg1=msgbox('Load Signal csv file to convert to fcs','help','modal');
uiwait(hmsg1)
[filename filepath]=uigetfile('*.csv');
T=readtable([filepath filename]);
ndata=T{:,:};
text=T.Properties.VariableNames;

if(size(ndata, 2) ~= length(text))
	error 'Column titles in the Excel file must begin with a non-numeric character'
end
fcs_filename=[filepath filename(1:end-4) '.fcs'];
fca_writefcs(fcs_filename, ndata, text, text);