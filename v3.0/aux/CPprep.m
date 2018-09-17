function CPprep(mainhandles)
%Cuts the images to prepare for CellProfiler analysis
%Check if all columns have right number of wells
wellspercol=mainhandles.output.numWells;
check_wells=cellfun(@length,mainhandles.output.well_borders);
if all(check_wells==wellspercol)
    newsave_path = [mainhandles.output.filesfolder 'images for CellProfiler/'];
    mkdir(newsave_path);
    %If you haven't loaded the fitc image
    if ~isfield(mainhandles.output,'fitc_imgname')
        hmsg1=msgbox('Load FITC Image','help','modal');
        uiwait(hmsg1)
        [imgname, imgpath]= uigetfile('.tif','Choose FITC Image',...
            handles.output.phase_imgpath);
        if isequal(imgname,0) || isequal(imgpath,0)
            disp('User pressed cancel')
            return
        end
    end
    h=waitbar(1/16,'Loading Image','WindowStyle','modal');
    imgname=mainhandles.output.fitc_imgname;
    imgpath=mainhandles.output.fitc_imgpath;
    J=imread([imgpath imgname]);
    I=im2uint8(imadjust(J,stretchlim(J,0)));
    clear J;
    %Preallocate variables and constants for processing
    num_images=10;
    cut_every=wellspercol/num_images;
    cut_locations=cell(1,14);
    img_info=imfinfo([imgpath imgname]);
    %Iterate through every column
    for i=1:14
        waitbar((i+2)/16,h,sprintf('Preparing column %d',i));
        %Find visibile wells
        vis_ind=find(mainhandles.output.visibility{i});
        
        
        if ~isempty(vis_ind)
            vis_wells=mainhandles.output.well_borders{i}(vis_ind);
            %Concatenate and linearize for indexing
            well_ind=uint64(vertcat(vis_wells{:}));
            %Get image info to make a mask
            img_width=(mainhandles.output.tab_max(i)-mainhandles.output.tab_min(i))+1;
            %Make logical mask of all zeros of appropriate size
            BW1=false(img_info.Height,img_width);
            well_ind_linear=uint64(sub2ind([img_info.Height img_width],well_ind(:,1),well_ind(:,2)));
            BW1(well_ind_linear)=1;
            %Fill in the holes to generate mask (also convert to uint8 for
            %proper saving and processing by CellProfiler
            BW2=imfill(BW1,'holes');
            clear BW1
            %Split into 4 images per column
            for j=1:num_images
                if j==1
                    top_cut=min(mainhandles.output.well_borders{i}{1}(:,1))-1;
                    bottom_cut=max(mainhandles.output.well_borders{i}{cut_every*j}(:,1))+1;
                else
                    top_cut=cut_locations{i}(j-1,2)+1;
                    bottom_cut=max(mainhandles.output.well_borders{i}{cut_every*j}(:,1))+1;
                end
                
                cut_locations{i}(j,:)=round([top_cut bottom_cut]);
                
                %Cut oblique and Mask image to separate into smaller images
                Itemp=I(cut_locations{i}(j,1):cut_locations{i}(j,2),...
                    mainhandles.output.tab_min(i):mainhandles.output.tab_max(i));
                BWtemp=BW2(cut_locations{i}(j,1):cut_locations{i}(j,2),:);
                %Save oblique
                imwrite(Itemp,[newsave_path sprintf('FITC_column_%d_cut_%d.tif',i,j)],'tiff');
                %Save Mask
                imwrite(BWtemp,[newsave_path sprintf('Mask_column_%d_cut_%d.tif',i,j)],'tiff',...
                    'Compression','none');
                
                clear Itemp BWtemp
            end
        end
    end
    waitbar(0.99,h,'Saving data');
    clear I;
    %Set buttons
    set(mainhandles.Prepare_CP_push,'String','Re-do CellProfiler Preparation')
    set(mainhandles.Import_CP_push,'Enable','on')
    mainhandles.output.prepare_CP_push_count=1;
    mainhandles.output.cut_locations=cut_locations;
    %Update handles structure
    guidata(mainhandles.Load_fig, mainhandles);
    %Save to disk
    save([mainhandles.output.filepath mainhandles.output.filename],...
        '-struct','mainhandles','output')
    delete(h)
    
else
    warndlg(sprintf('Make sure all columns have %d wells before continuing',...
        wellspercol),'Warning!','modal');
    return;
end
end
