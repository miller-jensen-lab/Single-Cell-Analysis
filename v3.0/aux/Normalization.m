% Normalization Function
% JWS 4/8/16
function Normalization(DATA_table,Name,Filepath)

Names=DATA_table.Properties.VariableNames;
DATA=table2array(DATA_table);
num_non_data_columns = 3;

% create data object
obj.markers = Names(num_non_data_columns+1:end)';
num_markers = length(obj.markers);
obj.column = DATA(:,1);
num_cols = max(obj.column);
obj.row = DATA(:,2);
num_rows=max(obj.row);
obj.cell_count = DATA(:,3);
obj.data = DATA(:,((num_non_data_columns+1):end));

% data selection
ind1 = obj.cell_count >0;
ind0 = obj.cell_count==0;

obj.control_data = obj.data(ind0,:);
obj.control_row = obj.row(ind0,:);
obj.control_column = obj.column(ind0,:);
obj.control_cell_count = DATA(ind0,3);

obj.data = obj.data(ind1,:);
obj.row = obj.row(ind1,:);
obj.column = obj.column(ind1,:);
obj.cell_count = DATA(ind1,3);

%% Interpolate empty well noise along rows using Gaussian kernel smoothing
% interpolate marker values from empty wells, subtract from both
% one-cell-wells and empty-wells to center marker distributions at 0

temp_data = zeros(num_rows,num_cols,num_markers);
for col_num = min(obj.control_column):1:max(obj.control_column)
    for marker_num = 1:size(obj.data,2)
        control_index = (obj.control_column == col_num);
        x = obj.control_row(control_index);
        y = obj.control_data(control_index,marker_num);
        
        sigma = 5; %default is 5, set to larger if sparse 0-cell wells
        
        xi = 1:num_rows;
        conv = zeros(size(xi));
        for i=1:length(xi)
            x0 = xi(i);
            kf = exp(-(x0-x).^2./(2*sigma^2));
            kf = kf/sum(kf);
            conv(i) = conv(i)+sum(y.*kf);
        end
        temp_data(:,col_num,marker_num) = conv;
    end
end

%% subtracting out the convolution
for col_num = min(obj.control_column):1:max(obj.control_column)
    for marker_num = 1:size(obj.data,2)
        conv = temp_data(:,col_num,marker_num);
        
        data_ind = (obj.column == col_num); %find indices per column
        conv_ind = obj.row(data_ind); %find corresponding elements of the convolution
        obj.data(data_ind,marker_num) = obj.data(data_ind,marker_num)-conv(conv_ind);%subtract
        
        control_ind = find(obj.control_column==col_num);%repeat above for control
        crow_ind = obj.control_row(control_ind);
        obj.control_data(control_ind,marker_num) = obj.control_data(control_ind,marker_num)-conv(crow_ind);
    end
end

A=array2table([DATA(:,1:3),[obj.control_data;obj.data]]);
A.Properties.VariableNames=Names;
writetable(A, [Filepath, Name,' Normalized Signal.csv'])

A1=A(A{:,3}==1,:);
writetable(A1, [Filepath, Name,' Normalized Signal One Cell.csv']);
%Export 1 cell normalized file as fcs file
table_to_fcs(A1,[Filepath, Name,' Normalized Signal One Cell']);
clear A1

%% Add 100 to the data for plotting purposes
%%Also make any value less than 1, equal to 1 for log transformation
obj.dataplus100=obj.data+100;%100
obj.dataplus100(obj.dataplus100<1)=1;
obj.control100=obj.control_data+100;%100
obj.control100(obj.control100<1)=1;

A100=array2table([DATA(:,1:3),[obj.control100;obj.dataplus100]]);
A100.Properties.VariableNames=Names;
writetable(A100, [Filepath, Name,' Plus 100.csv'])
fclose('all');

%Isolate 1 cell wells
A100=A100(A100{:,3}==1,:);
writetable(A100, [Filepath, Name,' Plus 100 One Cell.csv'])
clear A100

%% fit gaussian to noise for each marker and set threshold at 99 percentile
obj.threshold=zeros(1,size(obj.data,2));
obj.data_th=zeros(size(obj.data));
obj.control_data_th=zeros(size(obj.control_data));
for marker_num = 1:size(obj.data,2)
    y = obj.control_data(:,marker_num);
    threshold = prctile(y,99);
    obj.threshold(marker_num)=threshold;
    %Subtract threshold from elements in data
    obj.data_th(:,marker_num)=obj.data(:,marker_num)-threshold;
    obj.control_data_th(:,marker_num)=obj.control_data(:,marker_num)-threshold;
end
obj.data_th(obj.data_th<0)=0;
obj.control_data_th(obj.control_data_th<0)=0;

%% Export Thresholded Data (not transformed with asinh)
B=array2table([DATA(:,1:3),[obj.control_data_th;obj.data_th]]);
B.Properties.VariableNames=Names;
writetable(B, [Filepath, Name,' Thresholded Signal.csv'])

%Isolate 1 cell wells
B1=B(B.Cell_Count==1,:);
writetable(B1, [Filepath, Name,' Thresholded Signal One Cell.csv'])
clear B1

%% Ouput Thresholds
obj.thresholdplus100=obj.threshold+100;%100
D=[obj.threshold;obj.thresholdplus100];
D=array2table(D);
D.Properties.VariableNames=[Names((num_non_data_columns)+1:end)];
D.Properties.RowNames=[{'Thresholds'},{'Thresholds plus 100'}];
writetable(D, [Filepath, Name,' Thresholds.csv'],'WriteRowNames',true)
fclose('all');

%% Transform data using asinh and cofactor dependent on threshold. (1/0.8) 
%Save as fcs for 1 cell data only
Tdata=SC_asinh(A,D);
writetable(Tdata, [Filepath, Name,' asinhTransformed.csv']);
Tdata1cell=Tdata(Tdata.Cell_Count==1,:);
table_to_fcs(Tdata1cell,[Filepath, Name, ' asinhTransformed']);

%% Remove cells not secreting anything and export as csv and fcs for transformed data
%Only 1cell data for both csv and fcs processec by removesilentcells
E=removesilentcells(Tdata,B);
writetable(E, [Filepath, Name,' OnlyON.csv']);
table_to_fcs(E,[Filepath, Name, ' OnlyON']);
clear D

%% Compute oncounts (fix in future with thresholded data)
%Make binary data from thresholded data
obj.data_th(obj.data_th>0)=1;
obj.control_data_th(obj.control_data_th>0)=1;

%Calculate %ON
obj.oncounts=zeros(max(obj.cell_count)+1,size(obj.data_th,2)+2);
obj.oncounts(1,3:end)=round(sum(obj.control_data_th,1)/size(obj.control_data_th,1)*100,2);
obj.oncounts(1,2)=size(obj.control_data_th,1);
for i=1:max(obj.cell_count)
    temp=obj.cell_count==i;
    obj.oncounts(i+1,2)=sum(temp);
    obj.oncounts(i+1,3:end)=round(sum(obj.data_th(temp,:),1)./size(obj.data_th(temp,:),1)*100,2);
end
A=num2cell(obj.oncounts);
for i=1:max(obj.cell_count)+1
    A{i,1}=[num2str(i-1) '_cell'];
end
A=cell2table(A);
A.Properties.VariableNames=['Type',Names((num_non_data_columns):end)];
writetable(A, [Filepath, Name,' OnCounts.csv'])

%% Export Binary Data (not transformed with asinh)
Bin=array2table([DATA(:,1:3),[obj.control_data_th;obj.data_th]]);
Bin.Properties.VariableNames=Names;
writetable(Bin, [Filepath, Name,' Binary Signal.csv'])

%Isolate 1 cell wells
Bin1=Bin(Bin.Cell_Count==1,:);
writetable(Bin1, [Filepath, Name,' Binary Signal One Cell.csv'])
clear Bin Bin1


end