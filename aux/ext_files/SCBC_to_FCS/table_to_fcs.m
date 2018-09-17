function table_to_fcs(T,filename)
% table_to_fcs(Table, )
%
% converts a CSV file to a FCS file.

ndata=T{:,:};
text=T.Properties.VariableNames;

if(size(ndata, 2) ~= length(text))
	error 'Column titles in the Excel file must begin with a non-numeric character'
end
fcs_filename=[filename '.fcs'];
fca_writefcs(fcs_filename, ndata, text, text);