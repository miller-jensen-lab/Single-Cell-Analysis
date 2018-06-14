function xls_to_fcs(xls_filename, fcs_filename)
% xls_to_fcs(xls_filename, fcs_filename)
%
% converts a XLS file to a FCS file.

[ndata, text] = xlsread(xls_filename);

if(size(ndata, 2) ~= length(text))
	error 'Column titles in the Excel file must begin with a non-numeric character'
end

fca_writefcs(fcs_filename, ndata, text, text);

