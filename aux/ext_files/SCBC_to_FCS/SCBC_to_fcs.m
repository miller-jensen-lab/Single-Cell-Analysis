function SCBC_to_fcs
hmsg1=msgbox('Load Signal csv file to convert to fcs','help','modal');
uiwait(hmsg1)
[filename filepath]=uigetfile('*.xlsx');
xls_to_fcs([filepath filename], [filepath filename(1:end-5) '.fcs']);