function data_stats_baseth(T,csvpath,newpath)
h=waitbar(0.3,'Analyzing data...','WindowStyle','modal');
Variable_Names=T.Properties.VariableNames;
signal_fields=Variable_Names(4:end);
%Make variables for index of cell counts (e.g. index_cell_counts{1} is 
%index of %rows with 0 cells, {2} is for 1 cell, etc...);
index_cell_counts=cell(max(T.Cell_Count)+1,1);
row_names=index_cell_counts;
Thresholds_T=readtable([csvpath 'Thresholds.csv'],'ReadRowNames',1);
for k=1:length(index_cell_counts)
    index_cell_counts{k}=T.Cell_Count==k-1;
    row_names{k}=sprintf('%d_cell',k-1);
end
row_names_all=vertcat(row_names,strcat(row_names,'thresholded'));
%Preallocate variables for thresholds
threshold=Thresholds_T{1,:};
threshold98=Thresholds_T{2,:};
%Get matrix with signal data alone
clean_signal=T{:,4:end};
thresh_signal=zeros(size(clean_signal));
for j=1:size(clean_signal,2);
    thresh_signal(:,j)=round(clean_signal(:,j)-threshold98(j));
end
%Set all values below zero in thresholded signal =0;
thresh_signal(thresh_signal<0)=0;
%Make binary results, where all values above 0 are set to 1
binary_signal=thresh_signal>0;


%Iterate through the indeces of cell counts to get stats for number of
%cells
%Preallocate variables;
signal_means=zeros(length(index_cell_counts),size(clean_signal,2));
counts_cellpwell=zeros(length(index_cell_counts),1);
signal_medians=signal_means;
signal_std=signal_means;
thsignal_means=signal_means;
thsignal_medians=signal_means;
thsignal_std=signal_means;
onstats=signal_means;
thonstats=signal_means;
oncounts=signal_means;
for i=1:length(index_cell_counts);
    signal_means(i,:)=mean(clean_signal(index_cell_counts{i},:));
    signal_medians(i,:)=median(clean_signal(index_cell_counts{i},:));
    signal_std(i,:)=std(clean_signal(index_cell_counts{i},:));
    thsignal_means(i,:)=mean(thresh_signal(index_cell_counts{i},:));
    thsignal_medians(i,:)=median(thresh_signal(index_cell_counts{i},:));
    thsignal_std(i,:)=std(thresh_signal(index_cell_counts{i},:));
    index_onstats=bsxfun(@and,binary_signal,index_cell_counts{i});
    temp_signal=clean_signal;
    temp_signal(~index_onstats)=NaN;
    onstats(i,:)=nanmean(temp_signal);
    temp_signal=thresh_signal;
    temp_signal(~index_onstats)=NaN;
    thonstats(i,:)=nanmean(temp_signal);
    counts_cellpwell(i)=sum(index_cell_counts{i});
    oncounts(i,:)=(sum(binary_signal(index_cell_counts{i},:),1)./...
        counts_cellpwell(i))*100;
end
%Make pearson correlation matrix for 1 cell data
pearson_corr=corr(clean_signal(index_cell_counts{2},:));
%Round oncounts to two decimal points only
oncounts=round(oncounts*100)/100;

%Make tables for export
%Thresholded signal (all signal - thresh, negative values set to 0
Tthresh=T;
Tthresh{:,4:end}=thresh_signal;
%Binary signal, 1 if above threshold
Tbinary=T;
Tbinary{:,4:end}=binary_signal;

T_means=array2table(vertcat(round(signal_means),round(thsignal_means)),'RowNames',...
    row_names_all,'VariableNames',signal_fields);
T_medians=array2table(vertcat(round(signal_medians),round(thsignal_medians)),'RowNames',...
    row_names_all,'VariableNames',signal_fields);

T_std=array2table(vertcat(round(signal_std),round(thsignal_std)),'RowNames',...
    row_names_all,'VariableNames',signal_fields);

T_pearson=array2table(pearson_corr,'RowNames',signal_fields,...
    'VariableNames',signal_fields);
T_oncounts=array2table([counts_cellpwell,oncounts],'RowNames',...
    row_names,'VariableNames',[{'Total_num_of_wells'},signal_fields]);
T_thresholds=array2table(vertcat(threshold,threshold98),'RowNames',...
    [{'Threshold'} {'Threshold for 98%'}],'VariableNames',signal_fields);
T_onstats=array2table([counts_cellpwell,round(onstats)],'RowNames',...
    row_names,'VariableNames',[{'Total_num_of_wells'},signal_fields]);

waitbar(0.8,h,'Exporting data to CSV files...');
writetable(T,[newpath 'Raw Signal.csv']);
writetable(Tthresh,[newpath 'Thresholded Signal.csv']);
writetable(Tbinary,[newpath 'Binary Signal.csv']);
writetable(T_means,[newpath 'Means.csv'],'WriteRowNames',1);
writetable(T_medians,[newpath 'Medians.csv'],'WriteRowNames',1);
writetable(T_std,[newpath 'StdDev.csv'],'WriteRowNames',1);
writetable(T_pearson,[newpath 'Pearson Correlation.csv'],'WriteRowNames',1);
writetable(T_oncounts,[newpath 'On Counts.csv'],'WriteRowNames',1);
writetable(T_onstats,[newpath 'OnStats.csv'],'WriteRowNames',1);
delete(h);
end