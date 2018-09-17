function detect_wells_fitc(handles)
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
        I4=im2uint8(imadjust(I4)); %15 95 legacy
        
        fig2=figure; imshow(imadjust(I4,stretchlim(I4,[0.15,0.95])));
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
    clear I2
    %% Use a guassian filter to blur the image and correct for uneven illumination
    waitbar(0.3,h,'Correcting Illumination');
    %Block processing of gaussian filter
    fun = @(block_struct) ...
        imgaussfilt(block_struct.data,150);
    B=blockproc(I4,[3000 4000],fun,'UseParallel',0); %Only works if environment has parallel computing 
    %toolbox installed. Otherwise set 'UseParallel' to false.
  
    
            %This was for large image processing
%     B=imgaussfilt(I4,150);
%     background=imopen(I4,strel('disk',10));
    I5=I4-0.95*B;
    I5=imadjust(I5,stretchlim(I5,[0.15 0.9]));
%     tic
%     I6=imsharpen(I5,'Amount',2,'Threshold',0.3,'Radius',3);
%     toc
    %%%%%% Display image and check if background correction worked - for
    % debugging
%     
%     figcheck=figure; imshow(I5), title('Corrected Image, close to continue');
%     uiwait(figcheck)
    clear I4 B
    %     figure, imshow(I2), title('Contrast Adjusted')
    %% Well detection
    while continuecheck==1;
        waitbar(0.4,h,'Detecting wells');
        %     clear I2;
        counter=counter+1;
        corr_factor=0.4;
        if counter>1;
            prompt='Correct threshold by:';
            answer=inputdlg(prompt);
            corr_factor=str2double(answer);
        end
        level=graythresh(I5);
        BW1=im2bw(I5,corr_factor*level);
%                     figure, imshow(BW1);
        
        % figure, imshow(BW), title('Edge detection')
        
       %% Large wells (220)
        if handles.output.numWells==220;
            waitbar(0.5,h,'Cleaning Image...');
            BW2=imfill(BW1,4,'holes');
            clear BW1
            waitbar(0.52,h,'Cleaning Image...');
            BW3=imclearborder(BW2);
            clear BW2
            waitbar(0.54,h,'Cleaning Image...');
            BW4a=imerode(BW3,ones(2));
%             BW4a=bwmorph(BW3,'erode');
            clear BW3
            waitbar(0.56,h,'Cleaning Image...');
            BW4=bwmorph(BW4a,'diag');
            clear BW4a
            
            
            
            
            %% Filter objects Nikon
%             waitbar(0.6,h,'Filtering objects...');
%             BW5=bwpropfilt(BW4,'Area',[15000 50000],4);
%             clear BW4
%             waitbar(0.7,h,'Filtering objects...');
%             BW6=bwpropfilt(BW5,'Orientation',[-30 30],4);
%             clear BW5
%             waitbar(0.8,h,'Filtering objects...');
%             BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500],4);
%             clear BW6
%             waitbar(0.9,h,'Filtering objects...');
%             BW8=bwpropfilt(BW7,'MinorAxisLength',[16 40],4);
%             clear BW7
            
            %% Filter objects ZEISS
            waitbar(0.6,h,'Filtering objects...');
            BW5=bwpropfilt(BW4,'Area',[18000 60000],4);
            clear BW4
            waitbar(0.7,h,'Filtering objects...');
            BW6=bwpropfilt(BW5,'Orientation',[-30 30],4);
            clear BW5
            waitbar(0.8,h,'Filtering objects...');
            BW7=bwpropfilt(BW6,'MajorAxisLength',[1250 1900],4);
            clear BW6
            waitbar(0.9,h,'Filtering objects...');
            BW8=bwpropfilt(BW7,'MinorAxisLength',[20 50],4);
            clear BW7
        %% Small wells (550)    
        elseif handles.output.numWells==550;
            waitbar(0.8,h,'Cleaning Image...');
            BW2=imfill(BW1,'holes');
            clear BW1
            BW3=imclearborder(BW2);
            clear BW2
            %             BW4a=bwmorph(BW3,'erode');
            BW4a=imerode(BW3,ones(2));
            clear BW3
            BW4b=bwmorph(BW4a,'thicken',1);
            BW4=bwmorph(BW4b,'diag');
            clear BW3
            
            %% Filter Objects NIKON
%              waitbar(0.6,h,'Filtering objects...');
%             BW5=bwpropfilt(BW4,'Area',[6000 21000],4);
%             clear BW4
%             waitbar(0.7,h,'Filtering objects...');
%             BW6=bwpropfilt(BW5,'Orientation',[-30 30],4);
%             clear BW5
%             waitbar(0.8,h,'Filtering objects...');
%             BW7=bwpropfilt(BW6,'MajorAxisLength',[1100 1550],4);
%             clear BW6
%             waitbar(0.9,h,'Filtering objects...');
%             BW8=bwpropfilt(BW7,'MinorAxisLength',[6 14],4);
% %             clear BW7
            
             %% Filter Objects ZEISS
            waitbar(0.6,h,'Filtering objects...');
            BW5=bwpropfilt(BW4,'Area',[7000 25000],4);
            clear BW4
            waitbar(0.7,h,'Filtering objects...');
            BW6=bwpropfilt(BW5,'Orientation',[-30 30],4);
            clear BW5
            waitbar(0.8,h,'Filtering objects...');
            BW7=bwpropfilt(BW6,'MajorAxisLength',[1350 1900],4);
            clear BW6
            waitbar(0.9,h,'Filtering objects...');
            BW8=bwpropfilt(BW7,'MinorAxisLength',[7 17],4);
            clear BW7
        end
        %% Detection check
        CC=bwconncomp(BW8,4);
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
    
    %% Detection export
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



