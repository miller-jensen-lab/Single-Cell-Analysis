%% Testing in polygon
tic
mainhandles=guidata(Load_fig_handle);


vis_ind=find(mainhandles.output.visibility{1});
vis_wells=mainhandles.output.well_borders{1}(vis_ind);
%Concatenate and linearize for indexing
well_ind=round(vertcat(vis_wells{:}));

%Get image info to make a mask
img_info=imfinfo([imgpath imgname]);
img_width=(mainhandles.output.tab_max(1)-mainhandles.output.tab_min(1))+1;

BW1=false(img_info.Height,img_width);
well_ind_linear=uint64(sub2ind([img_info.Height img_width],well_ind(:,1),well_ind(:,2)));
BW1(well_ind_linear)=1;
%Fill in the holes to generate mask
BW1=imfill(BW1,'holes');


BW2=reg_column==chosen_index(1);
%Multiply by well mask to get signal region in channel
BW2=BW1&BW2;
%Get indeces of the signal region in the channels
[row col]=find(BW2);
%Generate a structure with a 220,14 cell
logical_index_signal=...
    cellfun(@(X) inpolygon(col,row,X(:,2),X(:,1)), vis_wells,'UniformOutput',0);
lin_ind_signal= cellfun(@(X) sub2ind([img_info.Height img_width],row(X),col(X)),...
    logical_index_signal,'UniformOutput',0);
toc


%% Testing multiplication
tic
mainhandles=guidata(Load_fig_handle);
vis_ind=find(mainhandles.output.visibility{1});
vis_wells=mainhandles.output.well_borders{1}(vis_ind);
well_ind=vertcat(vis_wells{:});
BW1=false(img_info.Height,img_width);
well_ind_linear=uint64(sub2ind([img_info.Height img_width],well_ind(:,1),well_ind(:,2)));
BW1(well_ind_linear)=1;
%Fill in the holes to generate mask
BW1=imfill(BW1,'holes');
CC=bwconncomp(BW1);
%Re-orders the wells in appropriate order
[row_wells col_wells]=cellfun(@(X) ind2sub([img_info.Height img_width],X),...
    CC.PixelIdxList,'UniformOutput',0);
well_mins=cellfun(@min, row_wells);
[~,sortindex]=sort(well_mins);
sorted_wells=CC.PixelIdxList(sortindex);
row_wells=row_wells(sortindex);
col_wells=col_wells(sortindex);
clear CC BW1


BW2=sparse(reg_column==chosen_index(1));
lin_ind_signal=cell(length(vis_ind),1);
% BWwells=false(img_info.Height,img_width);
for k=1:length(vis_ind)
    %     BWtemp=BWwells;
    %     BWtemp(sorted_wells{k})=1;
    %Multiply by well mask to get signal region in channel
    BWtemp=sparse(row_wells{k},col_wells{k},true(1),img_info.Height,img_width);
    BW3=BW2&BWtemp;
    lin_ind_signal{k}=find(BW3);
end
toc


