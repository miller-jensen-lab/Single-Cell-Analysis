function signal_alignment(handles)
handles.MasterGUI.Visible='off';
%Load looper
looper='yes';
gobackto='First';
%Load main data
mainhandles=guidata(handles.Load_fig);
%Get the tritc alignment image
num_wells=mainhandles.output.numWells;
hmsg1=msgbox('Choose TRITC microscope Image','help','modal');
uiwait(hmsg1)
[tritcname, tritcpath]= uigetfile('.tif','Choose TRITC microscope Image',...
    mainhandles.output.fitc_imgpath);
if isequal(tritcname,0) || isequal(tritcpath,0)
    disp('User pressed cancel')
    handles.MasterGUI.Visible='on';
    figure(handles.MasterGUI);
    return;
else
    fitcpath=mainhandles.output.fitc_imgpath;
    fitcname=mainhandles.output.fitc_imgname;
    
    
    %Get the Genepix 555 image
    hmsg1=msgbox('Choose GenePix 532nm Image','help','modal');
    uiwait(hmsg1)
    [g555name, g555path]= uigetfile('.tif','Choose GenePix 532nm Image',...
        mainhandles.output.fitc_imgpath);
    if isequal(g555name,0) || isequal(g555path,0)
        disp('User pressed cancel')
        handles.MasterGUI.Visible='on';
        figure(handles.MasterGUI);
        return;
    else
        %Get the Genepix signal data (635)
        hmsg1=msgbox('Choose GenePix 635nm Image','help','modal');
        uiwait(hmsg1)
        [g635name, g635path]= uigetfile('.tif','Choose GenePix 635nm Image',...
            g555path);
        if isequal(g635name,0) || isequal(g635path,0)
            disp('User pressed cancel')
            handles.MasterGUI.Visible='on';
            figure(handles.MasterGUI);
            return;
        else
            clear mainhandles
            %Get channel names
            num_channels=num2cell(1:20)';
            num_channels=cellfun(@num2str, num_channels,'UniformOutput',0);
            prompt=strcat('Channel', {' '}, num_channels,':');
            if handles.align_signal==0;
                signal_names=channel_input;
            elseif handles.align_signal==1;
                signal_names=channel_input(handles.signal_names);
            end
            empty_channels=cellfun(@isempty, signal_names);
            chosen_channels=~empty_channels;
            if sum(chosen_channels)==0;
                handles.MasterGUI.Visible='on';
                figure(handles.MasterGUI);
                return;
            else
                %Specify which channel to use for alignemnt
                choice=choose_ch_dialog(prompt,signal_names,chosen_channels);
                indices=find(chosen_channels);
                align_ch=indices(choice);
                
                %Load Images and adjust contrast
                h=waitbar(.1,'Loading Microscope Image...','WindowStyle','modal');
                fixed=imread([tritcpath tritcname]);
                fixed=im2uint8(imadjust(fixed,stretchlim(fixed,[0.05 0.95])));
                %                 J=histeq(fixed); J=adapthisteq(J); J=adapthisteq(J);
                fixedRGB=cat(3,zeros(size(fixed),'uint8'),fixed,zeros(size(fixed),'uint8'));
                
                waitbar(0.3,h,'Loading GenePix Images...');
                moving555=imread([g555path g555name]);
                moving555=im2uint8(imadjust(moving555));
                
                
                
                moving635=imread([g635path g635name]);
                moving635=im2uint8(imadjust(moving635));
                
                movingRGB=cat(3,moving635,moving555,zeros(size(moving635),'uint8'));
                
                waitbar(0.35,h,'Loading channel overlay...');
                %Read barcode image from file, get channels, and get an
                %image using only the desired alignment channel
                load('Barcode_data.mat');
                %% Do you want to flip barcode? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                barcode=flip(barcode,2);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                CC=bwconncomp(barcode);
                L=labelmatrix(CC);
                real_barcode=barcode;
                delete_pixels=vertcat(CC.PixelIdxList{empty_channels});
                real_barcode(delete_pixels)=0;
                %                 L(delete_pixels)=0;
                align_barcode=L==align_ch;
                RGBbarcode=label2rgb(L,'jet','k');
                delete(h)
                
                %                 contrast_images=Contrast_GUI(moving488,moving635,fixed);
                Rfixed = imref2d(size(fixed));
                Rgenepix= imref2d(size(moving635));
                clear moving635 moving555 fixed CC L delete_pixels;
            end
        end
    end
end

while strcmpi(looper,'yes')
    %Load from beginning
    if strcmpi(gobackto,'first')
        
        h=waitbar(0.4,'Loading point selection interface...','WindowStyle','modal');
        
        
        %% Register the channel overlay to the Genepix Image %%%
        hmsg=msgbox('Choose 22 points to align with between the two pictures',...
            'help','modal');
        %Get control points
        [movingPoints_ch, fixedPoints_ch]=cpselect(align_barcode,movingRGB,'wait',true);
        %Close helpbox if it hasn't been closed
        if exist('hmsg','var')
            delete(hmsg);
        end
        
        
        %Estimate transformation as projective due to PDMS deformation
        tform_channels=fitgeotrans(movingPoints_ch,fixedPoints_ch,'projective');
        %Register the barcode binary align channel image to the Genepix space
        registered_align_barcode=imwarp(barcode,tform_channels,'nearest','OutputView',Rgenepix);
        %Get outline of properly registered channel (outside perimeter using
        %dilation)
        reg_barcode_outline=bwmorph(registered_align_barcode,'dilate',1);
        reg_barcode_outline=logical(reg_barcode_outline-registered_align_barcode);
        %Overlay perimeter on RGB genepix image
        reg_barcode_outline=repmat(reg_barcode_outline,[1 1 3]);
        temp_Genepix=movingRGB;
        temp_Genepix(reg_barcode_outline)=255;
        clear reg_barcode_outline;
    end
    
    %% Register the Genepix Signal to the Microscope Image%%%%
    
    hmsg=msgbox('Choose 6 points to align with between the two pictures',...
        'help','modal');
    %Get control points
    [movingPoints, fixedPoints]=cpselect(temp_Genepix,fixedRGB,'wait',true);
    %Close helpbox if it hasn't been closed
    if exist('hmsg','var')
        delete(hmsg);
    end
    
    waitbar(0.7,h,'Transforming images and overlaying outlines...');
    %Estimate transformation as a non-reflective similarity (translation,
    %rotation and scale only).
%     clear temp_Genepix
    tform_signal=fitgeotrans(movingPoints,fixedPoints,'nonreflectivesimilarity');
    %Register the Genepix Signal into the microscope space
    registered = imwarp(movingRGB,tform_signal,'nearest','OutputView',Rfixed);
    
    
    %Register the barcode overlay to the microscope
    registered_barcode= imwarp(real_barcode,tform_channels,'nearest','OutputView',Rgenepix);
    registered_barcode= imwarp(registered_barcode,tform_signal,'nearest','OutputView',Rfixed);
    %Get outline using dilation
    reg_barcode_outline=bwmorph(registered_barcode,'dilate',1);
    reg_barcode_outline=logical(reg_barcode_outline-registered_barcode);
    
    %Overaly on final registered RGB image
    %Red = 635 genepix, Green = 488 genepix, Blue = FITC microscope
    reg_barcode_outline=repmat(reg_barcode_outline,[1 1 3]);
    registeredRGB=cat(3,registered(:,:,1),registered(:,:,2),fixedRGB(:,:,2));
    registeredRGB(reg_barcode_outline)=255;
    delete(h)
    hfig1=figure; imshow(registeredRGB); title('Red=Genepix635, Green=Genepix555, Blue=Microscope TRITC... Close Figure when done');
    uiwait(hfig1)
    quest_ans=questdlg(...
        'Is the alignment ok?',...
        'Alignment Check!','Yes','No','No');
    if strcmp(quest_ans,'Yes')
        h=waitbar(0.2,'Making registered image...','WindowStyle','modal');
        %Remake RGB without outlines and with FITC image to save to file
        if num_wells==220
            upperlim=0.99;
        elseif num_wells==550;
            upperlim=0.95;
        end
        fitc=imread([fitcpath fitcname]);
        fitc=im2uint8(imadjust(fitc,stretchlim(fitc,[0.10 upperlim])));
        registeredRGB=cat(3,registered(:,:,1),registered(:,:,2),...
            fitc);
        clear fixedRGB  movingRGB registered temp_Genepix
        looper='no';
        %Save transform and spatial reference to mainhandles GUI
        waitbar(0.5,h,'Saving data...');
        mainhandles=guidata(handles.Load_fig);
        %         mainhandles.output.fitc_imgpath=fitcpath;
        %         mainhandles.output.fitc_imgname=fitcname;
        mainhandles.output.g555_imgpath=g555path;
        mainhandles.output.g555_imgname=g555name;
        mainhandles.output.g635_imgpath=g635path;
        mainhandles.output.g635_imgname=g635name;
        mainhandles.output.transform.channels=tform_channels;
        mainhandles.output.transform.signal=tform_signal;
        mainhandles.output.spatialR.microscope=Rfixed;
        mainhandles.output.spatialR.genepix=Rgenepix;
        mainhandles.output.align_signal=1;
        mainhandles.output.RGBname='registered_signal.jpg';
        mainhandles.output.reg_barcode_outline=reg_barcode_outline(:,:,1);
        mainhandles.output.signal_names=signal_names;
        mainhandles.output.alignment_channel=align_ch;
        guidata(handles.Load_fig,mainhandles);
        mainhandles.extract_export_push.Enable='on';
        waitbar(0.8,h,'Writing images to disk')
        %Save image to disk
        imwrite(registeredRGB,[mainhandles.output.filesfolder ...
            'registered_signal.jpg'],'jpg');
        %Save maihandles to disk
        save([mainhandles.output.filepath mainhandles.output.filename],...
            '-struct','mainhandles','output')
        clear mainhandles
        %Update MasterGUI handles
        waitbar(0.9,h,'Updating Master GUI...');
        handles.registeredRGB=registeredRGB;
        handles.registeredRGB(reg_barcode_outline)=255;
        handles.align_signal=1;
        handles.signal_names=signal_names;
        handles.overlay_signal_checkbox.Enable='on';
        handles.extract_signal_push.Enable='on';
        handles.channel_names_push.Enable='on';
        guidata(handles.MasterGUI,handles);
        delete(h)
    else
        gobackto=questdlg(...
            'Re-do from First or Second Alignment?',...
            'Alignment Check!','First','Second','First');
    end
end
handles.MasterGUI.Visible='on';
figure(handles.MasterGUI);
end






