%Script to extract partial correlations from clean_signal table and thresholded signal
%tables
%Remember to first load the data into a table MOtable and so on

M0_Thresh_Data=M0_Thresh_table{M0_Thresh_table.Cell_Count==1,4:end};
M1_Thresh_Data=M1_Thresh_table{M1_Thresh_table.Cell_Count==1,4:end};
M2_Thresh_Data=M2_Thresh_table{M2_Thresh_table.Cell_Count==1,4:end};

rhoM0Thresh=partialcorr(M0_Thresh_Data,...
    'Rows','pairwise');
rhoM1Thresh=partialcorr(M1_Thresh_Data,...
    'Rows','pairwise');
rhoM2Thresh=partialcorr(M2_Thresh_Data,...
    'Rows','pairwise');

signalnames=M0_Thresh_table.Properties.VariableNames(4:end);
rhoM0table=array2table(rhoM0Thresh,'VariableNames',signalnames,...
    'RowNames',signalnames);
rhoM1table=array2table(rhoM1Thresh,'VariableNames',signalnames,...
    'RowNames',signalnames);
rhoM2table=array2table(rhoM2Thresh,'VariableNames',signalnames,...
    'RowNames',signalnames);

writetable(rhoM0table,'M0_partialcorr.csv','WriteRowNames',1);
writetable(rhoM1table,'M1_partialcorr.csv','WriteRowNames',1);
writetable(rhoM2table,'M2_partialcorr.csv','WriteRowNames',1);