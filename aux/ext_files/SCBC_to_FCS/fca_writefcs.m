function fca_writefcs(filename, data, marker_names,channel_names,hdr)

if size(data,2)~= length(marker_names) % put the data matrix back to what flow people are familiar with, thin tall matrix
    if size(data,1)== length(marker_names)
        data = data.';
    else
        error('data size and marker_names length do not match!!')
    end
end

%%%strips path from filename for writing in header
slashes=strfind(filename,'/');
if ~isempty(slashes)
    fname=filename(slashes(end)+1:end);
else
    fname=filename;
end
%%%
    
fcsheader_main=['\$BEGINANALYSIS\0\$ENDANALYSIS\0\$BEGINSTEXT\0\$ENDSTEXT\0\$NEXTDATA\0\'];
fcsheader_main = [fcsheader_main,'$TOT\',num2str(size(data,1)),'\']; % number of cells/events
fcsheader_main = [fcsheader_main,'$PAR\',num2str(size(data,2)),'\']; % number of channels
fcsheader_main = [fcsheader_main,'FCSversion\3\'];  % i'm pretending this is a fcs v3 format
fcsheader_main = [fcsheader_main,'CREATOR\PengQiu FCS writer\'];  
fcsheader_main = [fcsheader_main,'$COM\PengQiu FCS writer\'];  
fcsheader_main = [fcsheader_main,'FILENAME\',fname,'\'];  
fcsheader_main = [fcsheader_main,'GUID\1.fcs\ORIGINALGUID\1.fcs\'];  % don't know what this means
fcsheader_main = [fcsheader_main,'$BYTEORD\4,3,2,1\'];  % big-endian ordering -- rfinck added 'b' to fwrite to correspond
fcsheader_main = [fcsheader_main,'$DATATYPE\F\'];  % don't know what this means
fcsheader_main = [fcsheader_main,'$MODE\L\'];  % don't know what this means
if nargin>4  %add in date, start time, end time, instrument ID
    fcsheader_main = [fcsheader_main,'$BTIM\',hdr.starttime,'\']; 
    fcsheader_main = [fcsheader_main,'$ETIM\',hdr.stoptime,'\'];  
    fcsheader_main = [fcsheader_main,'$CYT\',hdr.cytometry,'\'];  
    fcsheader_main = [fcsheader_main,'$DATE\',hdr.date,'\'];  
    if isfield(hdr,'cytsn')
        fcsheader_main = [fcsheader_main,'$CYTSN\',hdr.cytsn,'\'];
    end
    if ~isempty(strfind(hdr.cytometry,'CYTOF'))
        fcsheader_main = [fcsheader_main,'CYTOF_DATA_SHIFT\100\'];
    end
else  %default assumes cytof
    fcsheader_main = [fcsheader_main,'$CYT\DVSSCIENCES-CYTOF\'];  %this is cytof data
    fcsheader_main = [fcsheader_main,'CYTOF_DATA_SHIFT\100\'];
end
for i=1:length(marker_names)
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'B\',num2str(32),'\'];
    if exist('channel_names')
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'N\',channel_names{i},'\'];
    else
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'N\',marker_names{i},'\'];
    end
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'S\',marker_names{i},'\'];
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'R\',num2str(ceil(max(data(:,i)))),'\'];
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'E\','0,0','\'];
end

fid = fopen(filename,'w','b');
HeaderStart = 100;
HeaderStop = HeaderStart + length(fcsheader_main)+100-1;
DataStart = HeaderStop;
DataEnd = DataStart+prod(size(data))*4;
if length(num2str(DataEnd))<=8
fcsheader_1stline  = sprintf('FCS3.0         %3d    %4d    %4d%8d%8d%8d',HeaderStart,HeaderStop,DataStart,DataEnd,0,0);
else
fcsheader_1stline  = sprintf('FCS3.0         %3d    %4d    %4d%8d%8d%8d',HeaderStart,HeaderStop,0,0,0,0);
end    
fcsheader_main = [fcsheader_main,'$BEGINDATA\',num2str(DataStart),'\']; 
fcsheader_main = [fcsheader_main,'$ENDDATA\',num2str(DataEnd),'\']; 
entire_header = [fcsheader_1stline, repmat(char(32),1,HeaderStart-length(fcsheader_1stline)),fcsheader_main];
entire_header = [entire_header, repmat(char(32),1,HeaderStop-length(entire_header))];
fwrite(fid,entire_header,'char');
fwrite(fid,data.','float32','b');
fclose(fid);

return