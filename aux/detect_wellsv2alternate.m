function detect_wellsv2alternate(handles)
%Detect wells using oblique image
[imgname, imgpath]= uigetfile('.tif','Choose Darkfield Image',...
    handles.output.filepath);
if isequal(imgname,0) || isequal(imgpath,0)
    disp('User pressed cancel')
    return
else
    handles.output.oblique_imgname=imgname;
    handles.output.oblique_imgpath=imgpath;
    h=waitbar(0.1,'Loading Image...','WindowStyle','modal');
    I2=imread([imgpath imgname]);
    
    waitbar(0.3,h,'Adjusting contrast');
    I2=im2uint8(imadjust(I2,stretchlim(I2,0)));
    % figure, imshow(I2), title('Contrast Adjusted')
    waitbar(0.5,h,'Detecting edges');
    [~, thresh]=edge(I2,'sobel');
    BW=edge(I2,'sobel',0.6*thresh);
    clear I2;
    % figure, imshow(BW), title('Edge detection')
    waitbar(0.6,h,'Closing Image');
    BW1=bwmorph(BW,'close',Inf);
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
        %Change these dimensions for small wells!
    BW5=bwpropfilt(BW4,'Area',[20000 50000]);
    clear BW4
    BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
    clear BW5
    BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
    clear BW6
    BW8=bwpropfilt(BW7,'MinorAxisLength',[18 30]);
    clear BW7
    
    
    handles.output.temp_mask_path=[handles.output.filesfolder ...
        handles.output.filename(1:end-4) ' tempMask.tif'];
    waitbar(0.95,h,'Saving Mask Image...');
    imwrite(BW8,handles.output.temp_mask_path,'tiff');
    handles.output.images_cut=0;
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



