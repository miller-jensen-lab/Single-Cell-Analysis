function detect_wells_registration(handles)
h=msgbox('Load Oblique Image','help','modal');
uiwait(h)
[imgname, imgpath]= uigetfile('.tif','Choose Oblique Image',...
    handles.output.filepath);
if isequal(imgname,0) || isequal(imgpath,0)
    disp('User pressed cancel')
    return
else
    num_wells=handles.output.numWells;
    handles.output.oblique_imgname=imgname;
    handles.output.oblique_imgpath=imgpath;
    h=waitbar(0.1,'Loading Image...','WindowStyle','modal');
    J=imread([imgpath imgname]);
    waitbar(0.2,h,'Adjusting contrast');
    J=im2uint8(imadjust(J,stretchlim(J,0)));
    waitbar(0.3,h,'Converting to RGB');
    I=cat(3,J,J,J);
    clear J;
    if num_wells==220
        load('35um_microwell_data.mat')
    elseif num_wells==550;
        load('15um_microwell_data.mat')
    end
    %Get spatial reference
    Rfixed = imref2d(size(I(:,:,1)));
    Rwells= imref2d(size(BWmicrowell));
    %Get control points
    [movingPoints, fixedPoints]=cpselect(BWmicrowell,I,'wait',true);
    %Estimate transformation as projective due to PDMS deformation
%     save('testreg.mat','fixedPoints', 'movingPoints','num_wells','I','BWmicrowell','Rfixed','Rwells')
    waitbar(0.4,h,'Tranforming Well Image...');
    tform_wells=fitgeotrans(movingPoints,fixedPoints,'affine');
%     tform2=estimateGeometricTransform(movingPoints,fixedPoints,'projective');
    %Register the well binary image and the well label matrix to the
    %Nikon image space.
    Reg_BWmicrowell=imwarp(BWmicrowell,Rwells,tform_wells,'nearest','OutputView',Rfixed);
%     Reg_L=imwarp(L,tform_wells,'nearest','OutputView',Rfixed);
    
%     %Get perimeter of wells using 4 connectivity;
%     Reg_Perim=bwperim(Reg_BWmicrowell,4);
%     
%     %Get perimeter of labels:
%     Reg_L(~Reg_Perim)=0;
    
    %Get row and column indeces of each well
    handles.output.well_borders=cell(1,14);
    well_borders=bwboundaries(Reg_BWmicrowell,4,'noholes');
    well_bord_linear=cellfun(@(X) sub2ind(size(Reg_BWmicrowell),X(:,1),...
        X(:,2)),well_borders,'UniformOutput',0);
    I2=Reg_BWmicrowell;
%     w2=repmat(Reg_BWmicrowell,[1 1 3]);
    I2(BWmicrowell)=255; figure, imshow(I2);
    well_mins=cellfun(@min,well_bord_linear);
    [~,ind]=sort(well_mins);
    
    for i=1:14
        handles.output.well_borders{i}=...
            well_borders(ind(1+num_wells*(i-1):num_wells+num_wells*(i-1)));
    end
    
    %Sort the wells appropriately
%     max_each=zeros(220,1);
%     min_each=zeros(220,1);
%      for i=1:14
%          waitbar(0.4 + (i/28),h,'Numbering wells...');
%          handles.output.well_borders{i}=cell{220,1};
%          for j=1:num_wells;
%              [r, c] = find(Reg_L==(j+(num_wells*(i-1))));
%              handles.output.well_borders{i}{j}=...
%                  [r c];
%              max_each(j)=max(c);
%              min_each(j)=min(c);
%          end
%          handles.output.tab_min(i)=min(min_each)-250;
%          handles.output.tab_max(i)=max(max_each)+250;
%          for k=1:num_wells
%              handles.output.well_border{i}{k}(:,2)=...
%                  handles.output.well_border{i}{k}(:,2)-handles.output.tab_min+1;
%          end
%      end
    

    
%     handles.output.temp_mask_path=[handles.output.filesfolder ...
%         handles.output.filename(1:end-4) ' tempMask.tif'];
%     waitbar(0.95,h,'Saving Mask Image...');
%     imwrite(BW11,handles.output.temp_mask_path,'tiff');
    handles.output.images_cut=1;
    set(handles.Detect_wells_push,'String','Re-do Well Detection')
    set(handles.Edit_wells_push,'Enable','on')
    handles.output.detect_wells_push_count=1;
    waitbar(0.98,h,'Saving Data...');
    %Update guidata
    guidata(handles.Load_fig, handles);
    %Save
    save([handles.output.filepath ...
        handles.output.filename],'-struct','handles','output')
    delete(h)
end
end



