function extract_signal(Load_fig_handle)

% dbstop in extract_signal.m at 93 if i==11
%% Load Data
h=waitbar(0.1,'Loading Data...','WindowStyle','modal');
set(findall(h,'type','text'),'Interpreter','none');
mainhandles=guidata(Load_fig_handle);
num_wells=mainhandles.output.numWells;
check_wells=cellfun(@length,mainhandles.output.well_borders);
if all(check_wells==num_wells)
    imgname=mainhandles.output.fitc_imgname;
    imgpath=mainhandles.output.fitc_imgpath;
    genepath=mainhandles.output.g635_imgpath;
    genename=mainhandles.output.g635_imgname;
    signal_names=mainhandles.output.signal_names;
    gene635=imread([genepath genename]);
    %Read barcode to generate label matrix to identify individual channels
    load('Barcode_data.mat');
    %% Flip barcode image?? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    barcode=flip(barcode,2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% %%%%%%%%
    empty_channels=cellfun(@isempty, signal_names);
    chosen_channels=~empty_channels;
    %Don't extract signal from alignment channel
    chosen_channels(mainhandles.output.alignment_channel)=0;
    chosen_index=find(chosen_channels);
    CC=bwconncomp(barcode);
    L=labelmatrix(CC);
    delete_pixels=vertcat(CC.PixelIdxList{empty_channels});
    barcode(delete_pixels)=0;
    L(delete_pixels)=0;
    clear CC
    %Register the Labeled barcdoe overlay to the microscope
    waitbar(0.2,h,'Registering barcode and genepix image');
    tform_channels=mainhandles.output.transform.channels;
    tform_signal=mainhandles.output.transform.signal;
    Rgenepix=mainhandles.output.spatialR.genepix;
    Rfixed=mainhandles.output.spatialR.microscope;
    registered_barcode= imwarp(L,tform_channels,'nearest','OutputView',Rgenepix);
    registered_barcode= imwarp(registered_barcode,tform_signal,'nearest','OutputView',Rfixed);
    %Register the 635 signal
    gene635=imwarp(gene635,tform_signal,'nearest','OutputView',Rfixed);
    
    %% Preallocate variables
    cleaned_names=strrep(signal_names(chosen_index),'-','_');
    for ji=1:length(cleaned_names)
        signal.(matlab.lang.makeValidName(cleaned_names{ji}))=...
            NaN(num_wells,14);
        signal_fields=fieldnames(signal);
        cleansignal.(signal_fields{ji})=0;%zeros(num_wells*14,1);
    end
    signal_medians=signal;
    %Variables to get distance to barcode two separate locations
    sig_bar1=signal; sig_bar2=signal;
    dist2bar1=signal; dist2bar2=signal;
    cleansignal_medians=cleansignal;
    Column_n=NaN(num_wells*14,1);
    Row_n=NaN(num_wells*14,1);
    Cell_Count=NaN(num_wells*14,1);
    
    %% Iterate through every column
    for i =1:14
        waitbar((i+2)/16,h,sprintf('Preparing column %d',i));
        %Find visibile wells
        vis_ind=find(mainhandles.output.visibility{i});
        %% Add Row,Column and Cell count variables
        Column_n((1:num_wells)+(num_wells*(i-1)))=ones(num_wells,1)*i;
        Row_n((1:num_wells)+(num_wells*(i-1)))=1:num_wells;
        cellcount=cellfun(@length,mainhandles.output.Cell_Locs.x{i});
        celllocs=mainhandles.output.Cell_Locs.x{i};
        Cell_Count((1:num_wells)+(num_wells*(i-1)))=cellcount;
        
        if ~isempty(vis_ind)
            vis_wells=mainhandles.output.well_borders{i}(vis_ind);
            well_ind=uint64(vertcat(vis_wells{:}));
            %Get image info to make a mask of the wells
            img_info=imfinfo([imgpath imgname]);
            img_left=mainhandles.output.tab_min(i);
            img_right=mainhandles.output.tab_max(i);
            img_width=(img_right-img_left)+1;
            
            BW1=false(img_info.Height,img_width);
            well_ind_linear=uint64(sub2ind([img_info.Height img_width],well_ind(:,1),well_ind(:,2)));
            BW1(well_ind_linear)=1;
            %Fill in the holes to generate mask
            %             BW1=bwmorph(BW1,'bridge');
            BW1=imfill(BW1,'holes');
            CC=bwconncomp(BW1,4);
            %Re-orders the wells in appropriate order
            %Transforms linear CC Pixel indeces to subindices
            [row_wells col_wells]=cellfun(@(X) ind2sub([img_info.Height img_width],X),...
                CC.PixelIdxList,'UniformOutput',0);
            well_mins=cellfun(@min, row_wells);
            [~,sortindex]=sort(well_mins);
            row_wells=row_wells(sortindex);
            col_wells=col_wells(sortindex);
            
            %% Check for broken or overlapping wells
            %Check if you have any broken or overlapping wells by seeing if
            %there are any well regions that are 6*std different from the
            %mean well length
            well_lengths=cellfun(@length,row_wells);
            median_length=median(well_lengths);
            diff_lengths=abs(well_lengths-median_length);
            problem_wells=find(diff_lengths>21*mad(well_lengths,1));
            
            if ~isempty(problem_wells)
                %Correct problem wells in case they are larger than the
                %original vis_ind
                problem_wells(problem_wells>length(vis_ind))=length(vis_ind);
                string_wells=num2str(vis_ind(problem_wells)');
                string_lengths=num2str(well_lengths(problem_wells));
                warndlg(sprintf(...
                    ['General error with wells in column %d\n' ...
                    'Repair Wells: ' string_wells '\n' ...
                    'Length: ' string_lengths '\n' ...
                    'Median Length= %.0f'],i,median_length),...
                    'Error!');
                delete(h);
                return;
            end
            
            %Check if you still have the same number of wells after making
            %the mask (no overlapping wells)
            
            %Broken wells (one well split into two)
            if length(vis_ind)<length(row_wells)
                num_problems=(length(row_wells)-length(vis_ind));
                [~,ind]=sort(well_lengths);
                %Get smallest wells, in order of wells (to get pairs)
                problem_wells=sort(ind(1:(num_problems*2)));
                %Because wells are split, correct counts by substracting 1
                %off of each consecutive pair of wells (except for the
                %first pair)
                corr_factor=(1:num_problems)';
                corr_vector=repmat(corr_factor,1,2)';
                corr_vector=corr_vector(:)'-1;
                corr_wells=problem_wells-corr_vector;
                string_wells=num2str(vis_ind(corr_wells)');
                string_lengths=num2str(well_lengths(problem_wells));
                warndlg(sprintf(...
                    ['Error with broken wells in column %d\n' ...
                    'Repair Wells: ' string_wells '\n' ...
                    'Length: ' string_lengths '\n' ...
                    'Median Length=%.0f'],i,median_length),...
                    'Error!');
                delete(h);
                return;
                
                %Overlapping wells (two wells merge into one)
            elseif length(vis_ind)>length(row_wells)
                num_problems=(length(vis_ind)-length(row_wells));
                [~,ind]=sort(well_lengths);
                %Get largest wells
                problem_wells=ind(end-num_problems:end);
                string_wells=num2str(vis_ind(problem_wells)');
                string_lengths=num2str(well_lengths(problem_wells));
                warndlg(sprintf(...
                    ['Error with overlapping wells in column %d\n' ...
                    'Repair Wells: ' string_wells '\n' ...
                    'Length: ' string_lengths '\n' ...
                    'Median Length=%.0f'],i,median_length),...
                    'Error!');
                delete(h);
                return;
                
            end
            clear CC BW1
            
            
            
            %% Extract data from each row/column
            %Make cutout of barcode for this column
            reg_column=registered_barcode(:,img_left:img_right);
            %Make cutout of genepix image for this column
            gene635_cutout=gene635(:,img_left:img_right);
            %Preallocate cell to store location of pixels
            for j=1:length(chosen_index);
                waitbar((i+2)/16,h,sprintf(['Extracting ' signal_fields{j} ' signal from column %d'],i));
                BWchannel=sparse(reg_column==chosen_index(j));
                %                     lin_ind_signal=cell(length(vis_ind),1);
                for k=1:length(vis_ind)
                    %Make sparse matrix with only one well
                    BWwell=sparse(row_wells{k},col_wells{k},true(1),img_info.Height,img_width);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %% Extract location of barcode if cellcount==1 - for diffusion!!!
%                     if cellcount(vis_ind(k))==1;
%                         %Get location of bars as separate objects
%                         BWbars=full(BWchannel&BWwell);
%                         CC_bars=bwconncomp(BWbars,4);
%                         if CC_bars.NumObjects==2;
%                            %If there are two bars
%                            
%                             %Code to visualize barcode extraction
%                             Green=zeros(size(gene635_cutout),'uint16');
%                             lin_ind_signal=find(BWchannel&BWwell);
%                             a=vertcat(lin_ind_signal);
%                             Green(a)=2^16-1;
%                             BWwellimage=full(BWwell*2^16-1);
%                             I=cat(3,imadjust(gene635_cutout),Green,BWwellimage);
%                             
%                             top=min(row_wells{k})-10; bottom=max(row_wells{k})+10;
%                             
%                             f1=figure; hI=imshow(I(top:bottom,:,:));
%                             title(sprintf([ signal_fields{j} ' signal from column %d'],i));
%                             close(f1)
%                             
% %                             uiwait(f1);
%                         end
%                     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %Get region where well and signal coincide, and get linear
                    %indices                   
                    lin_ind_signal=find(BWchannel&BWwell);
                    %Get mean of (registered) signal at these indices
                    signal.(signal_fields{j})(vis_ind(k),i)=round(mean(gene635_cutout(lin_ind_signal)));
                    signal_medians.(signal_fields{j})(vis_ind(k),i)=round(median(gene635_cutout(lin_ind_signal)));
                    

      
                end
                %Overlay image to look for alignment
                %                                             if i==1&&j==1;
                %                                                         Green=zeros(size(gene635_cutout),'uint16');
                %                                                         a=vertcat(lin_ind_signal);
                %                                                         Green(a)=2^16-1;
                %                                                         I=cat(3,imadjust(gene635_cutout),Green,zeros(size(gene635_cutout),'uint16'));
                %
                %                                                         f1=figure; hI=imshow(I);
                %                                                         title(sprintf([ signal_fields{j} ' signal from column %d'],i));
                %                                                         uiwait(f1);
                %                                             end
            end
            
            
            
            %Get data for txt file
            %             end
        end
    end
    %Save data
    waitbar(0.98,h,'Saving data...');
    mainhandles.output.signal=signal;
    
    %% Clean data (remove empty sets from invisible wells).
    total_visible_index=vertcat(mainhandles.output.visibility{:});
    Column_n(~total_visible_index)=[];
    Row_n(~total_visible_index)=[];
    Cell_Count(~total_visible_index)=[];
    for j=1:length(chosen_index)
        %Make cleansignal output with all columns stacked into one column, and
        %clear invisible wells;
        cleansignal.(signal_fields{j})=reshape(signal.(signal_fields{j}),num_wells*14,1);
        cleansignal_medians.(signal_fields{j})=reshape(signal_medians.(signal_fields{j}),num_wells*14,1);
        cleansignal.(signal_fields{j})(~total_visible_index)=[];
        cleansignal_medians.(signal_fields{j})(~total_visible_index)=[];
        
    end
    %% Construct table to export to csv file as raw signal
    T_signal=struct2table(cleansignal);
    T_signal_medians=struct2table(cleansignal_medians);
    T_1=table(Column_n,Row_n,Cell_Count);
    Tfinal=[T_1,T_signal];
    Tfinal_medians=[T_1,T_signal_medians];
    %Clear any rows that have NaN values (the well didn't overlap with
    %a flow channel, so there is no detected signal)
    rowhasnan=any(isnan(Tfinal{:,:}),2);
    Tfinal(rowhasnan,:)=[];
    Tfinal_medians(rowhasnan,:)=[];
    %Sort T according to cell number
    [~,T_sort_ind]=sort(Tfinal{:,3});
    Tfinal=Tfinal(T_sort_ind,:);
    Tfinal_medians=Tfinal_medians(T_sort_ind,:);
    %Save
    mainhandles.output.cleansignal_table=Tfinal;
    guidata(Load_fig_handle,mainhandles);
    %Save maihandles to disk
    save([mainhandles.output.filepath mainhandles.output.filename],...
        '-struct','mainhandles','output')
    
    %Make new path to save exported files and normalized path
    fileappend=mainhandles.output.filename(1:end-4);
    newsave_path = [mainhandles.output.filesfolder fileappend ...
        ' Extracted Data/'];
    mkdir(newsave_path);
    %     normalized_path=[newsave_path, fileappend ' Normalized/'];
    %     mkdir(normalized_path);
    
    writetable(Tfinal_medians,[newsave_path fileappend ...
        ' Raw Signal_medians.csv']);
    delete(h)
    clearvars -except Tfinal newsave_path fileappend normalized_path
    
    %% Run data stats and normalization to remove noise
    %     data_stats(Tfinal,newsave_path,fileappend);
    Normalization(Tfinal,fileappend,newsave_path);
else
    %if not all columns have 220 wells
    warndlg(sprintf('Make sure all columns have %d wells before continuing',...
        num_wells),'Warning!','modal');
    delete(h);
    return;
end
end




