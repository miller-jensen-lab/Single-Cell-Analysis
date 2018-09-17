function detect_wells_fitc_edge(handles)
hmsg1=msgbox('Load FITC Image','help','modal');
uiwait(hmsg1)
[imgname, imgpath]= uigetfile('.tif','Choose FITC Image',...
    handles.output.filepath);
if isequal(imgname,0) || isequal(imgpath,0)
    disp('User pressed cancel')
    return
else
    %     handles.output.darkfield_imgname=imgname;
    %     handles.output.darkfield_imgpath=imgpath;
    handles.output.fitc_imgpath=imgpath;
    handles.output.fitc_imgname=imgname;
    h=waitbar(0.1,'Loading Image...','WindowStyle','modal');
    I2=imread([imgpath imgname]);
    
    waitbar(0.3,h,'Adjusting contrast...');
    I3=im2uint8(imadjust(I2,stretchlim(I2,[0.2,0.95])));
    %     figure, imshow(I3)
%     clear I2;
    %     background=intmax('uint8')*graythresh(I2);
    %     I3=I2-background;
    figok='no';
    continuecheck=1;
    fig1=figure; imshow(I3);
    
    while strcmpi(figok,'no')
        figure(fig1);
        hmsg2=msgbox('Click and drag a tight box around the well region');
        uiwait(hmsg2)
        rect1=round(getrect(fig1));
        waitbar(0.33,h,'Cutting out image');
        figure(h);
        xmin=rect1(1);
        xmax=rect1(1)+rect1(3);
        ymin=rect1(2);
        ymax=rect1(2)+rect1(4);
        I4=I2(ymin:ymax,xmin:xmax);
        I4=imadjust(I4,stretchlim(I4,[0.25 0.9])); %changed from 15 95 legacy
        fig2=figure; imshow(I4)
        answer=questdlg('Does this image cover all the wells?','Check Image');
        if strcmpi(answer,'yes');
            figok=answer;
        elseif strcmpi(answer,'cancel');
            delete(fig1), delete(fig2), delete(h);
            return;
        end
        delete(fig2);
    end
    delete(fig1);
    counter=0;
    %     figure, imshow(I2), title('Contrast Adjusted')
    while continuecheck==1;
        waitbar(0.4,h,'Detecting wells');
        %     clear I2;
        counter=counter+1;
        corr_factor=2.2;
        if counter>1;
            prompt='Correct threshold by:';
            answer=inputdlg(prompt);
            corr_factor=str2double(answer);
        end
        [~,thresh]=edge(I4,'canny');
        BW1=edge(I4,'canny',thresh.*[1.2 corr_factor]);
%                     figure, imshow(BW1);
        
        % figure, imshow(BW), title('Edge detection')
        
        %Change these dimensions for small wells!
        if handles.output.numWells==220;
            waitbar(0.5,h,'Cleaning Image...');
            BW2a=bwmorph(BW1,'bridge');
            BW2=imfill(BW2a,'holes');
            clear BW1
            waitbar(0.52,h,'Cleaning Image...');
            BW3=imclearborder(BW2);
            clear BW2
            waitbar(0.56,h,'Cleaning Image...');
            BW4=bwmorph(BW3,'diag');
            clear BW4a
            
            
            
            
            
            
            
            waitbar(0.6,h,'Filtering objects...');
            BW5=bwpropfilt(BW4,'Area',[20000 50000]);
            clear BW4
            waitbar(0.7,h,'Filtering objects...');
            BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
            clear BW5
            waitbar(0.8,h,'Filtering objects...');
            BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
            clear BW6
            waitbar(0.9,h,'Filtering objects...');
            BW8=bwpropfilt(BW7,'MinorAxisLength',[16 40]);
            clear BW7
            
        elseif handles.output.numWells==550;
            waitbar(0.8,h,'Cleaning Image...');
            BW2=imfill(BW1,'holes');
            clear BW1
            BW3=imclearborder(BW2);
            clear BW2
%             BW4a=bwmorph(BW3,'erode');
%             clear BW3
            BW4=bwmorph(BW3,'diag');
            clear BW3
            
            waitbar(0.6,h,'Filtering objects...');
            BW5=bwpropfilt(BW4,'Area',[7000 20000]);
            clear BW4
            waitbar(0.7,h,'Filtering objects...');
            BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
            clear BW5
            waitbar(0.8,h,'Filtering objects...');
            BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
            clear BW6
            waitbar(0.9,h,'Filtering objects...');
            BW8=bwpropfilt(BW7,'MinorAxisLength',[7 14]);
            clear BW7
            
        end
        CC=bwconncomp(BW8);
        wellsdetected=CC.NumObjects;
        figure_check=figure; imshow(BW8)
        prompt=sprintf('Detected %d out of %d wells with %.2f threshold correction. Continue?',...
            wellsdetected,handles.output.numWells*14,corr_factor);
        answer2=questdlg(prompt,'Check Detection');
        if strcmpi(answer2,'yes');
            continuecheck=0;
        elseif strcmpi(answer2,'cancel');
            delete(h);
            delete(figure_check)
            return;
        end
        delete(figure_check)
    end
    BW12=false(size(I3));
    BW12(ymin:ymax,xmin:xmax)=BW8;
    handles.output.temp_mask_path=[handles.output.filesfolder ...
        handles.output.filename(1:end-4) ' tempMask.tif'];
    waitbar(0.95,h,'Saving Mask Image...');
    imwrite(BW12,handles.output.temp_mask_path,'tiff');
    handles.output.images_cut=0;
    set(handles.Detect_wells_push,'String','Re-do Well Detection')
    set(handles.Edit_wells_push,'Enable','on')
    handles.images_menu.Enable='on';
    handles.relocate_menu.Enable='on';
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



