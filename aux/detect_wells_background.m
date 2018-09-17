function detect_wells_background(handles)
hmsg1=msgbox('Load Darkfield Image','help','modal');
uiwait(hmsg1)
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
    
    waitbar(0.3,h,'Adjusting contrast...');
    I2=im2uint8(imadjust(I2,stretchlim(I2,0)));
    %     background=intmax('uint8')*graythresh(I2);
    %     I3=I2-background;
    figok='no';
    continuecheck=1;
    fig1=figure; imshow(I2);
%     while continuecheck==1;
        while strcmpi(figok,'no')
            figure(fig1);
            hmsg2=msgbox('Click and drag a tight box around the well region');
            uiwait(hmsg2)
            rect1=round(getrect(fig1));
            waitbar(0.33,h,'Adjusting contrast of cut-out image...');
            figure(h);
            xmin=rect1(1);
            xmax=rect1(1)+rect1(3);
            ymin=rect1(2);
            ymax=rect1(2)+rect1(4);
            I3=I2(ymin:ymax,xmin:xmax);
            I4=imadjust(I3,stretchlim(I3,[0.20 0.99])); %changed from 20 98 legacy
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
        %     figure, imshow(I2), title('Contrast Adjusted')
        waitbar(0.5,h,'Detecting edges');
        [~, thresh]=edge(I4,'sobel');
        if handles.output.numWells==220
            BW=edge(I4,'sobel',0.20*thresh); %0.21 is legacy
        elseif handles.output.numWells==550;
            BW=edge(I4,'sobel',0.18*thresh);
        end
        %     clear I2;
        
        %     level=graythresh(I2);
        %     BWv1=im2bw(I2,2*level);
        %     figure, imshow(BWv1);
        
        % figure, imshow(BW), title('Edge detection')
        
        %Change these dimensions for small wells!
        if handles.output.numWells==220;
            waitbar(0.6,h,'Closing Image...');
            BW1=bwmorph(BW,'bridge',1);
            clear BW
            waitbar(0.7,h,'Filling Holes...');
            BW2=imfill(BW1,'holes');
            clear BW1
            waitbar(0.8,h,'Clearing Borders...');
            BW3=imclearborder(BW2);
            clear BW2
            BW4=bwmorph(BW3,'erode',2);
            clear BW3
            waitbar(0.9,h,'Filtering objects...');
            BW5=bwpropfilt(BW4,'Area',[20000 50000]);
            clear BW4
            BW6=bwpropfilt(BW5,'Orientation',[-30 30]);
            clear BW5
            BW7=bwpropfilt(BW6,'MajorAxisLength',[1000 1500]);
            clear BW6
            BW8=bwpropfilt(BW7,'MinorAxisLength',[16 40]);
            clear BW7
            BW9=bwmorph(BW8,'thicken',1);
            clear BW8
            BW10=bwmorph(BW9,'open',1);
            clear BW9
            BW11=bwpropfilt(BW10,'Area',[20000 50000]);
            clear BW10
        elseif handles.output.numWells==550;
            waitbar(0.6,h,'Closing Image...');
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
            waitbar(0.8,h,'Clearing Borders...');
            BW3=imclearborder(BW2);
            clear BW2
            BW4=bwmorph(BW3,'erode',2);
            clear BW3
            waitbar(0.9,h,'Filtering objects...');
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
        CC=bwconncomp(BW11);
        wellsdetected=CC.NumObjects;
        prompt=sprintf('Detected %d out of %d wells. Continue?',wellsdetected,...
            handles.output.numWells*14);
        hmsg3=msgbox(prompt,'Check Detection','help');
%         if strcmpi(answer2,'yes');
%             continuecheck=0;
%         elseif strcmpi(answer2,'cancel');
%             delete(h);
%             return;
%         end
%     end
    BW12=false(size(I2));
    BW12(ymin:ymax,xmin:xmax)=BW11;
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



