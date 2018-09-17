function varargout = Master_analysis_GUI(varargin)
% MASTER_ANALYSIS_GUI MATLAB code for Master_analysis_GUI.fig
%      MASTER_ANALYSIS_GUI, by itself, creates a new MASTER_ANALYSIS_GUI or raises the existing
%      singleton*.
%
%      H = MASTER_ANALYSIS_GUI returns the handle to a new MASTER_ANALYSIS_GUI or the handle to
%      the existing singleton*.
%
%      MASTER_ANALYSIS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASTER_ANALYSIS_GUI.M with the given input arguments.
%
%      MASTER_ANALYSIS_GUI('Property','Value',...) creates a new MASTER_ANALYSIS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Master_analysis_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Master_analysis_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Master_analysis_GUI

% Last Modified by GUIDE v2.5 16-Jun-2015 16:22:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Master_analysis_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Master_analysis_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before Master_analysis_GUI is made visible.
function Master_analysis_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Master_analysis_GUI (see VARARGIN)

%Passing the guidata from the main file info into mainhandles.
handles.Load_fig=varargin{1};
%Hides Loading GUI
handles.Load_fig.Visible='off';
handles.caller=varargin{2};
mainhandles=guidata(handles.Load_fig);
handles.images_cut=mainhandles.output.images_cut;
handles.numWells=mainhandles.output.numWells;
handles.align_signal=mainhandles.output.align_signal;
handles.uipanel1.Title=mainhandles.output.filename;
%Make tab group
handles.tabgroup=uitabgroup(handles.uipanel1,...
    'SelectionChangedFcn',@change_tab_callback);
if strcmpi(handles.caller,'wells')
    %Disable cells and signals buttons
    handles.add_remove_cells_toggle.Enable='off';
    handles.align_genepix_push.Enable='off';
    handles.overlay_signal_checkbox.Enable='off';
    handles.channel_names_push.Enable='off';
    handles.extract_signal_push.Enable='off';
    %Load FITC Image
    h=waitbar(0.1,'Loading Image','WindowStyle','modal');
    imgname=mainhandles.output.fitc_imgname;
    imgpath=mainhandles.output.fitc_imgpath;
    J=imread([imgpath imgname]);
    waitbar(0.2,h,'Adjusting Contrast');
    J=im2uint8(imadjust(J,stretchlim(J,[0.1 0.95])));% legacy 0.1 .95)
    waitbar(0.3,h,'Converting to RGB');
    I=cat(3,J,J,J);
    clear J;
    if mainhandles.output.images_cut==0;
        waitbar(0.33,h,'Loading detected mask');
        BW=imread(mainhandles.output.temp_mask_path);
        %Make directory to save cut images (one image per column of wells)
        %         mkdir(save_path);
    elseif mainhandles.output.images_cut==1;
        waitbar(0.2,h,'Loading previous data...','WindowStyle','modal');
        %Copy the relevant data to the current handles
        handles.BWcol_border=mainhandles.output.well_borders;
        %%Compatibility to make sure older versions are converted to single precision
        if strcmpi(class(handles.BWcol_border{1}{1}),'double')
            for i=1:14
                handles.BWcol_border{i}=cellfun(@single,handles.BWcol_border{i},'UniformOutput',0);
            end
        end
        handles.tab_min=mainhandles.output.tab_min;
        handles.tab_max=mainhandles.output.tab_max;
        handles.visibility=mainhandles.output.visibility;
    end
    %Delete mainhandles to free space
    clear mainhandles
elseif strcmpi(handles.caller,'cellsandsignal')
    %Load Oblique Image
    h=waitbar(0.08,'Loading Phase Image','WindowStyle','modal');
    imgname=mainhandles.output.phase_imgname;
    imgpath=mainhandles.output.phase_imgpath;
    J=imread([imgpath imgname]);
%     waitbar(0.12,h,'Loading FITC Image');
%     fitcname=mainhandles.output.fitc_imgname;
%     fitcpath=mainhandles.output.fitc_imgpath;
%     K=imread([fitcpath fitcname]);
    waitbar(0.15,h,'Adjusting Contrast');
    J=im2uint8(imadjust(J,stretchlim(J,0)));
    waitbar(0.17,h,'Converting to RGB');
    I=cat(3,J,J,J);
    clear J;
    %Copy the relevant data to the current handles
    handles.BWcol_border=mainhandles.output.well_borders;
    %%Compatibility to make sure older versions are converted to single precision
    if strcmpi(class(handles.BWcol_border{1}{1}),'double')
        for i=1:14
            handles.BWcol_border{i}=cellfun(@single,handles.BWcol_border{i},'UniformOutput',0);
        end
    end
    handles.tab_min=mainhandles.output.tab_min;
    handles.tab_max=mainhandles.output.tab_max;
    handles.visibility=mainhandles.output.visibility;
    handles.Cell_Locs=mainhandles.output.Cell_Locs;
    %Enable or disable signal alignment
    if handles.align_signal==1
        waitbar(0.2,h,'Loading Signal image');
        handles.overlay_signal_checkbox.Enable='on';
        handles.registeredRGB=imread([mainhandles.output.filesfolder ...
            mainhandles.output.RGBname]);
%         handles.registeredRGB(:,:,3)=I(:,:,1);
        reg_barcode_outline=repmat(mainhandles.output.reg_barcode_outline,...
            [1 1 3]);
        handles.registeredRGB(reg_barcode_outline)=255;
        clear reg_barcode_outline
        handles.signal_names=mainhandles.output.signal_names;
    elseif handles.align_signal==0
        handles.overlay_signal_checkbox.Enable='off';
        handles.extract_signal_push.Enable='off';
        handles.channel_names_push.Enable='off';
    end
    
    %Delete mainhandles to free space
    clear mainhandles
end

for i=1:14
    if strcmpi(handles.caller,'wells')
        %Cut out ROI for first column
        if handles.images_cut==0
            waitbar((i+3)/18,h,sprintf('Loading tab #%d',i));
            if i==1
                %If first iteration, run the bwconncomp on the original large
                %image
                BWtemp=BW;
                %Calculate well orientation to calculate where to cut
                %images for each column of wells
                well_orientation=regionprops(BWtemp,'Orientation');
                well_orientation=mean([well_orientation.Orientation]);
                if handles.numWells==220;
                    tilt_offset=sind(well_orientation)*(75/1.3)*220; %1.6 for nikon, 1.3 for zeiss
                elseif handles.numWells==550;
                    tilt_offset=sind(well_orientation)*(40/1.3)*550; 
                end
                
                cut_left=350;
                cut_right=round(abs(tilt_offset)+550);
                
            end
            %Identify the left-most well by finding the minimum linear index for
            %each object. This will represent the left-most pixel of each well.
            CCtemp=bwconncomp(BWtemp);
            minimums=cellfun(@min, CCtemp.PixelIdxList);
            [min_row, min_col]=ind2sub(CCtemp.ImageSize,minimums);
            maximums=cellfun(@max, CCtemp.PixelIdxList);
            [max_row, max_col]=ind2sub(CCtemp.ImageSize,maximums);
            %Find the left most out of all identified object to find the first
            %column of this image (or the first column after erasing previous
            %identified columns when i>1).
            [left_well, ind] =min(min_col);
            %Cut out 200 pixels from the left and the required number of  
            %pixels (depending on the well tilt) from the right of the 
            %left-most well.
            handles.tab_min(i)=left_well-cut_left;
            handles.tab_max(i)=max_col(ind)+cut_right;
            if i==1
                if handles.tab_min(i)<=0
                    handles.tab_min=1;
                end
            end
            if i==14
                if handles.tab_max(i)>length(I)
                    handles.tab_max(i)=length(I);
                end
            end
            %Make small image with only this column of wells (of the logical image
            %for object ID and of the original darkfield image.
            handles.BWcol=BW(:,handles.tab_min(i):handles.tab_max(i));
            Itemp=I(:,handles.tab_min(i):handles.tab_max(i),:);
            %Save darkfield cut-out image;
            %             imwrite(Itemp,[save_path sprintf('Darkfield_column_%d.tif',i)],'tiff');
            
            %% Clear borders and identify borders and objects
            handles.BWcol=imclearborder(handles.BWcol);
            handles.BWcol_border{i}=bwboundaries(handles.BWcol,4,'noholes');
            %*****Convert to single********
            handles.BWcol_border{i}=cellfun(@single,handles.BWcol_border{i},'UniformOutput',0);
            %**********************************
            handles.CCcol=bwconncomp(handles.BWcol,4);
            
            
            %Sort wells in appropriate order
            well_mins=cellfun(@(X) min(X(:,1)), handles.BWcol_border{i});
            [~,sortindex]=sortrows(well_mins);
            handles.BWcol_border{i}=handles.BWcol_border{i}(sortindex);
            
            %Is there a need to sort the pixelidxlist?
%             handles.CCcol.PixelIdxList=handles.CCcol.PixelIdxList(sortindex);
            
%             %Get only half of the border values to decrease matrix size
%             %(speed up calculations).(how to do this but keep
%             handles.BWcol_border{i}=cellfun(@(X) X(1:2:end,:),...
%                 handles.BWcol_border{i},'UniformOutput',0);
            
            
            %Make a new visible matrix
            handles.visibility{i}=true(length(handles.BWcol_border{i}),...
                1);
            
            %%%%%%%%This part of the code is to make an RGB image instead of plot
            %%%%%%%%overlay%%%%%%%%%%%%%%%5
            %     transB=cellfun(@(X) X(:,[2,1])', handles.BWcol_border,'UniformOutput',0);
            %     newB=cellfun(@(X) reshape(X,1,[]), transB,'UniformOutput',0);
            %     RGB=insertShape(I(:,handles.tab_min(i):handles.tab_max(i)),'polygon',newB);
            %%%%%%%%%%%%%%%%%%%%%%
            
            %Erase identified wells to identify next column of wells.
            linearindex=vertcat(handles.CCcol.PixelIdxList{:});
            [rt, ct]=ind2sub(handles.CCcol.ImageSize,linearindex);
            ct=ct+handles.tab_min(i)-1;
            linearindex=sub2ind(CCtemp.ImageSize,rt,ct);
            BWtemp(linearindex)=0;
            
        elseif handles.images_cut==1;
            waitbar((i+3)/18,h,sprintf('Loading tab #%d',i));
            Itemp=I(:,handles.tab_min(i):handles.tab_max(i),:);
            
        end
        
        
    elseif strcmpi(handles.caller,'cellsandsignal')
        %Cut out RGB image
        waitbar((i+3)/18,h,sprintf('Loading tab #%d',i));
        Itemp=I(:,handles.tab_min(i):handles.tab_max(i),:);
    end
    
    %Make panel for display, use cut out image and identified wells
    handles.tab(i)=uitab(handles.tabgroup,'Title',sprintf('Column %d',i));
    handles.uipaneltab(i)=uipanel('Parent',handles.tab(i));
    handles.axes_tab(i)=axes('Parent',handles.uipaneltab(i));
    handles.Image_tab(i)=imshow(Itemp,[],'Parent',handles.axes_tab(i));
    handles.axes_tab(i).NextPlot='add';
    
    %Set callback function to uninterruptible to prevent corrupted
    %well/cell counts
    handles.Image_tab(i).Interruptible='off';
    
    %Make scroll panel
    handles.hscroll(i)=imscrollpanel(handles.uipaneltab(i),...
        handles.Image_tab(i));
    handles.api_scroll(i)=iptgetapi(handles.hscroll(i));
    handles.api_scroll(i).setVisibleLocation(1,1);
    if handles.numWells==550;
        handles.api_scroll(i).setMagnification(1.2);
    end
    %% Plot well outlines
    handles.hplot{i}=cellfun(@(X) plot(handles.axes_tab(i),X(:,2),X(:,1),...
        'r-','PickableParts','none'), handles.BWcol_border{i},...
        'UniformOutput',0);
    %Insert text
    sorted_well_mins=double(cell2mat(cellfun(@(X) X(find(X(:,2)==min(X(:,2)),1),:), handles.BWcol_border{i},...
                'UniformOutput',0)));
%     sorted_well_mins=cell2mat(cellfun(@min, handles.BWcol_border{i},...
%         'UniformOutput',0));
    well_nums=num2cell(1:length(handles.BWcol_border{i}))';
    well_nums=cellfun(@num2str, well_nums,'UniformOutput',0);
    
    if strcmpi(handles.caller,'wells')
        %% Make labels with well numbers
        labels=strcat('Well\_',well_nums);
        not_visible=find(handles.visibility{i}==0);
        labels(not_visible)=strcat('Invisible\_',labels(not_visible));
        handles.htext{i}=text(sorted_well_mins(:,2)-80,sorted_well_mins(:,1),labels,'Parent',...
            handles.axes_tab(i),'Color','r','FontSize',14,'PickableParts','none');
        
    elseif strcmpi(handles.caller,'cellsandsignal')
        %Make labels with well numbers and cell counts
        cell_count=cellfun(@length,handles.Cell_Locs.x{i},'UniformOutput',0);
        cell_count=cellfun(@num2str,cell_count,'UniformOutput',0);
        labels=strcat('Well\_',well_nums,' (', cell_count, ' cells)');
        not_visible=find(handles.visibility{i}==0);
        labels(not_visible)=strcat('Invisible\_',labels(not_visible));
        handles.htext{i}=text(sorted_well_mins(:,2)-160,sorted_well_mins(:,1),labels,'Parent',...
            handles.axes_tab(i),'Color','r','FontSize',14,'PickableParts','none');
        %Display the cell outlined in circles
        cell_centers=[vertcat(handles.Cell_Locs.x{i}{:}) ...
            vertcat(handles.Cell_Locs.y{i}{:})];
        if ~isempty(cell_centers);
            radii_vec=ones(size(cell_centers,1),1).*12;
            handles.vis_circles_tab(i)=viscircles(handles.axes_tab(i),cell_centers,...
                radii_vec);
            handles.vis_circles_tab(i).PickableParts='none';
        end
        if handles.align_signal==1
            handles.RGB_tab(i)=imshow(handles.registeredRGB(:,...
                handles.tab_min(i):handles.tab_max(i),:),[],...
                'Parent',handles.axes_tab(i));
            handles.RGB_tab(i).AlphaData=1;
            handles.RGB_tab(i).PickableParts='none';
            handles.RGB_tab(i).Visible='off';
            uistack(handles.RGB_tab(i),'bottom')
        end
    end
    
    %Set to green if all  wells have been identified
    if length(handles.BWcol_border{i})==handles.numWells
        set(handles.htext{i},'Color','g');
        cellfun(@(X) set(X,'Color','g'),handles.hplot{i});
    end
    
   
    
end
%clear loaded images from memory
if handles.images_cut==0 && strcmpi(handles.caller,'wells')
    clear I Itemp CCtemp BWtemp BW;
    handles=rmfield(handles,[{'BWcol'} {'CCcol'}]);
    handles.images_cut=1;
elseif handles.images_cut==1
    clear I Itemp
    if handles.align_signal==1 && strcmpi(handles.caller,'cellsandsignal')
        handles=rmfield(handles,'registeredRGB');
    end
end

%Update the text in GUI and set output
delete(h);
handles.zoom_text.String=100;

% Choose default command line output for Master_analysis_GUI
handles.output=1;
handles.MasterGUI.OuterPosition=[0 0 1 1];
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Master_analysis_GUI wait for user response (see UIRESUME)
% uiwait(handles.MasterGUI);

end

% --- Executes when pressing a new tab ---%
function change_tab_callback(hObject, eventdata);
tabname=eventdata.NewValue.Title;
i=sscanf(tabname,'%*s%d');
handles=guidata(hObject);
handles.zoom_text.String=num2str(handles.api_scroll(i).getMagnification()*100);
well_pushstate=handles.add_remove_wells_toggle.Value;
cell_pushstate=handles.add_remove_cells_toggle.Value;

if well_pushstate==1
    set(handles.Image_tab(i),'ButtonDownFcn',{@wbdn_normalx, handles.MasterGUI});
    
elseif cell_pushstate==1;
    set(handles.Image_tab(i),'ButtonDownFcn',{@wbdn_cells, handles.MasterGUI});
elseif cell_pushstate==0 && well_pushstate==0
    set(handles.Image_tab(i),'ButtonDownFcn',[]);
end

if isfield(handles,'RGB_tab')
    overlay_value=handles.RGB_tab(i).Visible;
    if strcmpi(overlay_value,'off')
        handles.overlay_signal_checkbox.Value=0;
    elseif strcmpi(overlay_value,'on')
        handles.overlay_signal_checkbox.Value=1;
    end
end
end


% --- Outputs from this function are returned to the command line.
function varargout = Master_analysis_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% Get default command line output from handles structure
if isempty(handles)
else
    varargout{1} = handles.output;
end
end


% --- Executes on button press in add_remove_wells_toggle.
function add_remove_wells_toggle_Callback(hObject, eventdata, handles)
% hObject    handle to add_remove_wells_toggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of add_remove_wells_toggle
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
if get(hObject,'Value')==1
    set(handles.Image_tab(i),'ButtonDownFcn',{@wbdn_normalx, handles.MasterGUI});
    set(handles.add_remove_cells_toggle,'Value',0);
    handles.add_remove_wells_toggle.FontWeight='bold';
    handles.add_remove_cells_toggle.FontWeight='normal';
elseif get(hObject,'Value')==0;
    set(handles.Image_tab(i),'ButtonDownFcn',[]);
    handles.add_remove_wells_toggle.FontWeight='normal';
end
end


% --- Executes on button press in zoomin_push.
function zoomin_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoomin_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
currmag=handles.api_scroll(i).getMagnification();
handles.api_scroll(i).setMagnification(currmag+0.05);
handles.zoom_text.String=num2str(handles.api_scroll(i).getMagnification()*100);
end


% --- Executes on button press in zoomout_push.
function zoomout_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoomout_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
currmag=handles.api_scroll(i).getMagnification();
handles.api_scroll(i).setMagnification(currmag-0.05);
handles.zoom_text.String=num2str(handles.api_scroll(i).getMagnification()*100);
end

function zoom_text_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zoom_text as text
%        str2double(get(hObject,'String')) returns contents of zoom_text as a double
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
input=str2double(handles.zoom_text.String);
if isnan(input)
else
    handles.api_scroll(i).setMagnification(input/100);
end
end

% --- Executes during object creation, after setting all properties.
function zoom_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zoom_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%OLD CODE FOR CONTAST SLIDER
% % --- Executes on slider movement.
% function contrast_slider_Callback(hObject, eventdata, handles)
% % hObject    handle to contrast_slider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% tabname=handles.tabgroup.SelectedTab.Title;
% i=sscanf(tabname,'%*s%d');
% contrast_value=get(hObject,'Value');
% caxis(handles.axes_tab(i),[min(min(handles.Image_tab(i).CData))+contrast_value ...
%     max(max(handles.Image_tab(i).CData))-contrast_value]);
% end



% OLD CODE FOR CONTRAST SLIDER
% % --- Executes during object creation, after setting all properties.
% function contrast_slider_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to contrast_slider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
%
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% set(hObject,'Value',0);
% set(hObject,'SliderStep',[.1 .2]);
% set(hObject,'Max',10);
% end

% --- Executes on button press in done_push.
function done_push_Callback(hObject, eventdata, handles)
% hObject    handle to done_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


buttonName=questdlg('Do you want to save the new wells?', 'Save...');
if strcmpi(buttonName,'yes')
    %Load the guidata from the loading gui and update with relevant data
    mainhandles=guidata(handles.Load_fig);
    h=waitbar(0.5,sprintf('Saving file: %s ...\n',mainhandles.output.filename),...
        'WindowStyle','modal');
    mainhandles.output.tab_min=handles.tab_min;
    mainhandles.output.tab_max=handles.tab_max;
    mainhandles.output.images_cut=handles.images_cut;
    mainhandles.output.well_borders=handles.BWcol_border;
    mainhandles.output.visibility=handles.visibility;
    if strcmpi(handles.caller,'cellsandsignal')
        mainhandles.output.Cell_Locs=handles.Cell_Locs;
    end
    %Save the guidata of the loading GUI and the main file to disk
    guidata(mainhandles.Load_fig,mainhandles);
    
    save([mainhandles.output.filepath ...
        mainhandles.output.filename],'-struct','mainhandles','output')
    delete(h);
    close(handles.MasterGUI);
elseif strcmpi(buttonName,'no')
    close(handles.MasterGUI);
elseif strcmpi(buttonName,'cancel')
end
end

% --- Executes on scroll wheel click while the figure is in focus.
function MasterGUI_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to MasterGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
set(hObject,'Units','normalized');
set(handles.uipanel1,'Units','normalized');
mouse_pos=get(hObject,'CurrentPoint');
uipanel_pos=get(handles.uipanel1,'Position');
set(hObject,'Units','default');
set(handles.uipanel1,'Units','default');

if mouse_pos(1)>=uipanel_pos(1) && mouse_pos(1)<=uipanel_pos(1)+uipanel_pos(3)...
        && mouse_pos(2)>=uipanel_pos(2) && mouse_pos(2)<=uipanel_pos(2)+uipanel_pos(4);
    % if get(hObject,'CurrentObject')==handles.Image;
    loc=handles.api_scroll(i).getVisibleLocation();
    loc(2)=loc(2)+eventdata.VerticalScrollCount*20;
    
    if loc(2)<=0;
        loc(2)=1;
    end
    handles.api_scroll(i).setVisibleLocation(loc);
end
end

% --------------------------------------------------------------------
function save_push_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to save_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Load the guidata from the loading gui and update with relevant data
mainhandles=guidata(handles.Load_fig);
h=waitbar(0.5,sprintf('Saving file: %s ...\n',mainhandles.output.filename),...
    'WindowStyle','modal');
mainhandles.output.tab_min=handles.tab_min;
mainhandles.output.tab_max=handles.tab_max;
mainhandles.output.images_cut=handles.images_cut;
mainhandles.output.well_borders=handles.BWcol_border;
mainhandles.output.visibility=handles.visibility;
if strcmpi(handles.caller,'cellsandsignal')
    mainhandles.output.Cell_Locs=handles.Cell_Locs;
end
%Save the guidata of the loading GUI and the main file to disk
guidata(mainhandles.Load_fig,mainhandles);

save([mainhandles.output.filepath ...
    mainhandles.output.filename],'-struct','mainhandles','output')
delete(h);
end


% --- Executes on button press in add_remove_cells_toggle.
function add_remove_cells_toggle_Callback(hObject, eventdata, handles)
% hObject    handle to add_remove_cells_toggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of add_remove_cells_toggle
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
if get(hObject,'Value')==1
    set(handles.Image_tab(i),'ButtonDownFcn',{@wbdn_cells,handles.MasterGUI});
    set(handles.add_remove_wells_toggle,'Value',0);
    handles.add_remove_cells_toggle.FontWeight='bold';
    handles.add_remove_wells_toggle.FontWeight='normal';
elseif get(hObject,'Value')==0;
    set(handles.Image_tab(i),'ButtonDownFcn',[]);
    handles.add_remove_cells_toggle.FontWeight='normal';
end
end


% --- Executes on button press in align_genepix_push.
function align_genepix_push_Callback(hObject, eventdata, handles)
% hObject    handle to align_genepix_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.align_signal==0
    signal_alignment(handles);
elseif handles.align_signal==1;
    quest_ans=questdlg(...
        'Are you sure you want to re-do the GenePix signal alignment?',...
        'Warning!','Yes','No','No');
    if strcmp(quest_ans,'Yes')
        for i=1:14
            delete(handles.RGB_tab(i));
        end
        handles=rmfield(handles,'RGB_tab');
        handles.overlay_signal_checkbox.Value=0;
        signal_alignment(handles);
        
    end
end
end




% --- Executes on button press in overlay_signal_checkbox.
function overlay_signal_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to overlay_signal_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of overlay_signal_checkbox
value=get(hObject,'Value');
tabname=handles.tabgroup.SelectedTab.Title;
j=sscanf(tabname,'%*s%d');
%If the RGB image hasn't been displayed (right after alignment);
if isfield(handles,'RGB_tab')==0
    h=waitbar(0.2,'Loading Signal image','WindowStyle','modal');
    mainhandles=guidata(handles.Load_fig);
    reg_barcode_outline=repmat(mainhandles.output.reg_barcode_outline,...
        [1 1 3]);
    handles.registeredRGB(reg_barcode_outline)=255;
    clear reg_barcode_outline mainhandles
    for i=1:14;
        waitbar((i+2)/16,h,sprintf('Updating tab #%d',i));
        handles.RGB_tab(i)=imshow(handles.registeredRGB(:,...
            handles.tab_min(i):handles.tab_max(i),:),[],...
            'Parent',handles.axes_tab(i));
        handles.RGB_tab(i).AlphaData=1;
        handles.RGB_tab(i).PickableParts='none';
        handles.RGB_tab(i).Visible='off';
        uistack(handles.RGB_tab(i),'bottom')
    end;
    handles=rmfield(handles,'registeredRGB');
    delete(h)
end

if value==1
    
    handles.RGB_tab(j).Visible='on';
    handles.Image_tab(j).AlphaData=0.4;
    
elseif value==0
    handles.RGB_tab(j).Visible='off';
    handles.Image_tab(j).AlphaData=1;
    
end
guidata(handles.MasterGUI,handles);
end


% --- Executes when user attempts to close MasterGUI.
function MasterGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to MasterGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
handles.Load_fig.Visible='on';
figure(handles.Load_fig);
delete(hObject);
clear vars
end


% --- Executes on button press in channel_names_push.
function channel_names_push_Callback(hObject, eventdata, handles)
% hObject    handle to channel_names_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mainhandles=guidata(handles.Load_fig);
prev_names=handles.signal_names;
signal_names=channel_input(handles.signal_names);

empty_channels=cellfun(@isempty, signal_names);
chosen_channels=~empty_channels;


prev_empty=cellfun(@isempty, prev_names);
prev_chosen=~prev_empty;

%If you chose different channels to have an antibody, re-transform image to
%overlay (not necessary for signal extraction);
if sum(chosen_channels)==0;
    return
else
    
    if ~isequal(chosen_channels,prev_chosen)
        h=waitbar(0.2,'Updating the RGB image overlay','WindowStyle','modal');
        %Read barcode and use only the new selected channels
        load('Barcode_data.mat');
        %Do you want to flip barcode? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        barcode=flip(barcode,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        CC=bwconncomp(barcode);
        delete_pixels=vertcat(CC.PixelIdxList{empty_channels});
        barcode(delete_pixels)=0;
        clear CC delete_pixels
        %Register the barcode overlay to the microscope
        waitbar(0.3,h,'Registering new barcode')
        tform_channels=mainhandles.output.transform.channels;
        tform_signal=mainhandles.output.transform.signal;
        Rgenepix=mainhandles.output.spatialR.genepix;
        Rfixed=mainhandles.output.spatialR.microscope;
        registered_barcode= imwarp(barcode,tform_channels,'nearest','OutputView',Rgenepix);
        registered_barcode= imwarp(registered_barcode,tform_signal,'nearest','OutputView',Rfixed);
        clear barcode;
        %Find outline and save
        waitbar(0.4,h,'Overlaying channel outlines...');
        reg_barcode_outline=bwmorph(registered_barcode,'dilate',1);
        reg_barcode_outline=logical(reg_barcode_outline-registered_barcode);
        reg_barcode_outline=repmat(reg_barcode_outline,[1 1 3]);
        waitbar(0.5,h,'Loading signal image...')
        handles.registeredRGB=imread([mainhandles.output.filesfolder ...
            mainhandles.output.RGBname]);
        handles.registeredRGB(reg_barcode_outline)=255;
        mainhandles.output.reg_barcode_outline=reg_barcode_outline(:,:,1);
        clear reg_barcode_outline;
        %Delete the current overlay and displays the new one
        for i=1:14
            delete(handles.RGB_tab(i));
            waitbar((i+5)/19,h,sprintf('Updating tab #%d',i));
            handles.RGB_tab(i)=imshow(handles.registeredRGB(:,...
                handles.tab_min(i):handles.tab_max(i),:),[],...
                'Parent',handles.axes_tab(i));
            handles.RGB_tab(i).AlphaData=1;
            handles.RGB_tab(i).PickableParts='none';
            uistack(handles.RGB_tab(i),'bottom')
            if handles.overlay_signal_checkbox.Value==1
                handles.RGB_tab(i).Visible='on';
                handles.Image_tab(i).AlphaData=0.4;
            elseif handles.overlay_signal_checkbox.Value==0
                handles.RGB_tab(i).Visible='off';
                handles.Image_tab(i).AlphaData=1;
            end
        end;
        handles=rmfield(handles,'registeredRGB');
        delete(h)
    end
    %     Update outlines in main handles
    mainhandles.output.signal_names=signal_names;
    handles.signal_names=signal_names;
    guidata(handles.Load_fig,mainhandles);
    guidata(handles.MasterGUI,handles);
end

end

% --- Executes on button press in extract_signal_push.
function extract_signal_push_Callback(hObject, eventdata, handles)
% hObject    handle to extract_signal_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extract_signal(handles.Load_fig);

end

% --- Executes on key press with focus on MasterGUI or any of its controls.
function MasterGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to MasterGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');

if strcmpi(eventdata.Character,'w')
    
    if handles.add_remove_wells_toggle.Value==1
        handles.add_remove_wells_toggle.Value=0;
        handles.add_remove_wells_toggle.FontWeight='normal';
        handles.Image_tab(i).ButtonDownFcn=[];
    elseif handles.add_remove_wells_toggle.Value==0
        handles.add_remove_wells_toggle.Value=1;
        handles.add_remove_wells_toggle.FontWeight='bold';
        handles.Image_tab(i).ButtonDownFcn={@wbdn_normalx, handles.MasterGUI};
        handles.add_remove_cells_toggle.Value=0;
        handles.add_remove_cells_toggle.FontWeight='normal';
    end
    
elseif strcmpi(eventdata.Character,'c')
    
    if strcmpi(handles.caller,'cellsandsignal')
        if handles.add_remove_cells_toggle.Value==1
            handles.add_remove_cells_toggle.Value=0;
            handles.add_remove_cells_toggle.FontWeight='normal';
            handles.Image_tab(i).ButtonDownFcn=[];
        elseif handles.add_remove_cells_toggle.Value==0
            handles.add_remove_cells_toggle.Value=1;
            handles.add_remove_cells_toggle.FontWeight='bold';
            handles.Image_tab(i).ButtonDownFcn={@wbdn_cells, handles.MasterGUI};
            handles.add_remove_wells_toggle.Value=0;
            handles.add_remove_wells_toggle.FontWeight='normal';
        end
    end
        
elseif strcmpi(eventdata.Character,'g')
    if strcmpi(handles.caller,'cellsandsignal')
        if handles.align_signal==1;
            value=handles.overlay_signal_checkbox.Value;
            if value==1
                handles.overlay_signal_checkbox.Value=0;
                handles.RGB_tab(i).Visible='off';
                handles.Image_tab(i).AlphaData=1;
                
            elseif value==0
                handles.overlay_signal_checkbox.Value=1;
                handles.RGB_tab(i).Visible='on';
                handles.Image_tab(i).AlphaData=0.4;
                
            end
        end
    end
end

end


%%%%%%%%
%OLD CODE FOR CONTAST SLIDER
% % --- Executes on slider movement.
% function contrast_slider_Callback(hObject, eventdata, handles)
% % hObject    handle to contrast_slider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% tabname=handles.tabgroup.SelectedTab.Title;
% i=sscanf(tabname,'%*s%d');
% contrast_value=get(hObject,'Value');
% caxis(handles.axes_tab(i),[min(min(handles.Image_tab(i).CData))+contrast_value ...
%     max(max(handles.Image_tab(i).CData))-contrast_value]);
% end



% OLD CODE FOR CONTRAST SLIDER
% % --- Executes during object creation, after setting all properties.
% function contrast_slider_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to contrast_slider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
%
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% set(hObject,'Value',0);
% set(hObject,'SliderStep',[.1 .2]);
% set(hObject,'Max',10);
% end
