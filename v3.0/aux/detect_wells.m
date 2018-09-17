function detect_wells(handles)
msgbox('Choose Darkfield image','help','modal');
[imgname, imgpath]= uigetfile('.tif','Choose Darkfield Image',...
    handles.output.filepath);
if isequal(imgname,0) || isequal(imgpath,0)
    disp('User pressed cancel')
    return
else
    handles.output.darkfield_imgname=imgname;
    handles.output.darkfield_imgpath=imgpath;
    h=waitbar(0.1,'Loading Image...','WindowStyle','modal');
    I2=imread([imgpath imgname]);
    
    waitbar(0.3,h,'Adjusting contrast');
    I2=im2uint8(imadjust(I2,stretchlim(I2,[.05 0.98])));
%     figure, imshow(I2), title('Contrast Adjusted')
    waitbar(0.5,h,'Detecting edges');
    [~, thresh]=edge(I2,'sobel');
    if handles.output.numWells==220
        BW=edge(I2,'sobel',0.30*thresh);
    elseif handles.output.numWells==550;
        BW=edge(I2,'sobel',0.18*thresh);
    end
%     clear I2;
    
    %     level=graythresh(I2);
%     BWv1=im2bw(I2,2*level);
%     figure, imshow(BWv1);

    % figure, imshow(BW), title('Edge detection')
   
    %Change these dimensions for small wells!
    if handles.output.numWells==220;
        waitbar(0.6,h,'Closing Image');
        BW1=bwmorph(BW,'bridge',1);
        clear BW
        waitbar(0.7,h,'Filling Holes');
        BW2=imfill(BW1,'holes');
        clear BW1
        waitbar(0.8,h,'Clearing Borders');
        BW3=imclearborder(BW2);
        clear BW2
        BW4=bwmorph(BW3,'erode',2);
        clear BW3
        waitbar(0.9,h,'Filtering objects');
        BW5=bwpropfilt(BW4,'Area',[20000 50000]);
        clear BW4
        BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
        clear BW5
        BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
        clear BW6
        BW8=bwpropfilt(BW7,'MinorAxisLength',[18 30]);
        clear BW7
        BW9=bwmorph(BW8,'thicken',1);
        clear BW8
        BW10=bwmorph(BW9,'open',1);
        clear BW9
        BW11=bwpropfilt(BW10,'Area',[20000 50000]);
        clear BW10
    elseif handles.output.numWells==550;
        waitbar(0.6,h,'Closing Image');
        %Version 1
        BW1=bwmorph(BW,'clean',1);
        BW1a=bwmorph(BW1,'spur',1); %original 2
        BW1b=bwmorph(BW1a,'bridge',2);
        %Version 2
%         BW1=bwmorph(BW,'bridge',1);
%         BW1a=bwmorph(BW1,'clean',1);
%         BW1b=bwmorph(BW1a,'spur',2);
%         BW1c=bwmorph(BW1b,'bridge',1);
        
%         BW1c=bwmorph(BW1b,'shrink',1);
%         BW1a=bwmorph(BW1,'open',1);
%         BW1b=bwmorph(BW1a,'close',1);
%         BW1c=bwmorph(BW1b,'diag',inf);
%         BW1d=bwmorph(BW1c,'bridge',inf);
% BW1b=bwmorph(BW1a,'dilate',2);
% BW1c=bwmorph(BW1b,'erode',1);
        
%         BW1e=bwmorph(BW1d,'shrink',1);
%         clear BW
%         waitbar(0.7,h,'Filling Holes');
        BW2=imfill(BW1b,'holes');
        clear BW1
        waitbar(0.8,h,'Clearing Borders');
        BW3=imclearborder(BW2);
        clear BW2
        BW4=bwmorph(BW3,'erode',2);
        clear BW3
        waitbar(0.9,h,'Filtering objects');
        BW5=bwpropfilt(BW4,'Area',[7000 20000]);
        clear BW4
        BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
        clear BW5
        BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
        clear BW6
        BW8=bwpropfilt(BW7,'MinorAxisLength',[7 14]);
        clear BW7
        BW9=bwmorph(BW8,'thicken',1);
        clear BW8
        BW10=bwmorph(BW9,'open',1);
        clear BW9
        BW11=bwpropfilt(BW10,'Area',[7000 20000]);
        clear BW10
    end
    
    
    handles.output.temp_mask_path=[handles.output.filesfolder ...
        handles.output.filename(1:end-4) ' tempMask.tif'];
    waitbar(0.95,h,'Saving Mask Image...');
    imwrite(BW11,handles.output.temp_mask_path,'tiff');
    handles.output.images_cut=0;
    set(handles.Detect_wells_push,'String','Re-do Well Detection')
    set(handles.Edit_wells_push,'Enable','on')
    handles.output.detect_wells_push_count=1;
    handles.images_menu.Enable='on';
    handles.relocate_menu.Enable='on';
    waitbar(0.98,h,'Saving Data...');
    %Update guidata
    guidata(handles.Load_fig, handles);
    %Save
    save([handles.output.filepath ...
        handles.output.filename],'-struct','handles','output')
    delete(h)
end
end



