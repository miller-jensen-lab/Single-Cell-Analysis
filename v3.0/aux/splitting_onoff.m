%extract CCL2+ and CCL2- populations
function splitting_onoff(targetname)
%Extracts SC data and splits it into two csv files, positive and negative
%for a desired target. Intput is desired target to use for splitting.
if ~ischar(targetname)
    disp('Error - enter a string')
else
hmsg1=msgbox('Choose asinh CSV');
uiwait(hmsg1)
[filename, filepath]= uigetfile('*.csv');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
    return;
end

T=readtable([filepath filename]);
target=matlab.lang.makeValidName(targetname);
ind_on=T.(target)>asinh(1/0.8);

Ton=T(ind_on,:);
Toff=T(~ind_on,:);

newfolder=[filepath targetname '_split/'];
mkdir(newfolder);
newfileON=[filename(1:end-4) targetname '_ON.csv'];
newfileOFF=[filename(1:end-4) targetname '_OFF.csv'];    
writetable(Ton,[newfolder newfileON]);
writetable(Toff,[newfolder newfileOFF]);
end
end





