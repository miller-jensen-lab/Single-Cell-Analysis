function varargout = Loading_GUI(varargin)
% LOADING_GUI MATLAB code for Loading_GUI.fig
%      LOADING_GUI, by itself, creates a new LOADING_GUI or raises the existing
%      singleton*.
%
%      H = LOADING_GUI returns the handle to a new LOADING_GUI or the handle to
%      the existing singleton*.
%
%      LOADING_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOADING_GUI.M with the given input arguments.
%
%      LOADING_GUI('Property','Value',...) creates a new LOADING_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Loading_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Loading_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Loading_GUI

% Last Modified by GUIDE v2.5 05-Nov-2015 13:46:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Loading_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Loading_GUI_OutputFcn, ...
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

% --- Executes just before Loading_GUI is made visible.
function Loading_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Loading_GUI (see VARARGIN)

%Disable all push buttons before loading or making new analysis file
handles.Prepare_CP_push.Enable='off';
handles.Import_CP_push.Enable='off';
handles.Save_push_button.Enable='off';
handles.Detect_wells_push.Enable='off';
handles.Edit_wells_push.Enable='off';
handles.Edit_cells_push.Enable='off';
handles.extract_export_push.Enable='off';
% Choose default command line output for Loading_GUI
% handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Loading_GUI wait for user response (see UIRESUME)
% uiwait(handles.Load_fig);
end


% --- Outputs from this function are returned to the command line.
function varargout = Loading_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    clear vars
else
    varargout{1} = 1;
end
end


% --- Executes on button press in New_push.
function New_push_Callback(hObject, eventdata, handles)
% hObject    handle to New_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, filepath] = uiputfile('...single cell analysis.mat',...
    'Save new analysis as...');

if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
else
    %clear handles.output if file was already open
    if isfield(handles,'output')
        handles=rmfield(handles,'output');
    end
    %Choose the size of the wells used
    %First, supress warning so we can set no default answer
    id='MATLAB:questdlg:StringMismatch';
    warning('off',id);
    button=questdlg('What type of chip are you using?','Size of chip',...
        'Large (220 wells per column)','Small (550 wells per column)',...
        '');
    if isempty(button)
        disp('User pressed cancel')
    else
        if strcmpi(button,'Large (220 wells per column)')
            handles.output.numWells=220;
        elseif strcmpi(button,'Small (550 wells per column)')
            handles.output.numWells=550;
        end
        %Reset buttons (in case program was already open on a file)
        handles.Prepare_CP_push.Enable='off';
        handles.Import_CP_push.Enable='off';
        handles.Save_push_button.Enable='off';
        handles.Detect_wells_push.Enable='off';
        handles.Edit_wells_push.Enable='off';
        handles.Edit_cells_push.Enable='off';
        handles.extract_export_push.Enable='off';
        handles.images_menu.Enable='off';
        handles.relocate_menu.Enable='off';
        
        %Reset strings in buttons
        handles.Detect_wells_push.String='Detect Wells';
        handles.Prepare_CP_push.String='Prepare for CellProfiler';
        handles.Import_CP_push.String='Import CellProfiler Data';
        
        %Set all push button detectors to zero indicating a brand new file.
        handles.output.prepare_CP_push_count=0;
        handles.output.detect_wells_push_count=0;
        handles.output.import_CP_push_count=0;
        handles.output.align_signal=0;
        %Store filename and path, diplay on GUI.
        handles.output.filename=filename;
        handles.output.filepath=filepath;
        handles.Loaded_text.String=['File loaded: '...
            handles.output.filename];
        
        %Generate folder to put analysis files in
        handles.output.filesfolder= [filepath filename(1:end-4) ...
            ' analysis files/'];
        mkdir(handles.output.filesfolder);
        %Save general file
        save([filepath filename],'-struct','handles','output')
        %Enable the detect wells and save buttons
        handles.Save_push_button.Enable='on';
        handles.Detect_wells_push.Enable='on';
        % Update handles structure
        guidata(handles.Load_fig, handles);
    end
end
end

% --- Executes on button press in Load_push.
function Load_push_Callback(hObject, eventdata, handles)
% hObject    handle to Load_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Re-set all push buttons


%Get .mat file to load all analysis info
[filename, filepath]= uigetfile('*.mat','Choose Analysis file');
if isequal(filename,0) || isequal(filepath,0)
    disp('User pressed cancel')
else
    h=waitbar(0.5,['Loading file: ' filename],'WindowStyle','modal');
    %Reset buttons (in case program was already open on a file)
    handles.Prepare_CP_push.Enable='off';
    handles.Import_CP_push.Enable='off';
    handles.Save_push_button.Enable='off';
    handles.Detect_wells_push.Enable='off';
    handles.Edit_wells_push.Enable='off';
    handles.Edit_cells_push.Enable='off';
    handles.extract_export_push.Enable='off';
    handles.images_menu.Enable='off';
    handles.relocate_menu.Enable='off';
    
    %Reset strings in buttons
    handles.Detect_wells_push.String='Detect Wells';
    handles.Prepare_CP_push.String='Prepare for CellProfiler';
    handles.Import_CP_push.String='Import CellProfiler Data';
    %Reassign loaded output variable to handles output, display loaded file
    load([filepath filename]);
    handles.output=output;
    clear output;
    handles.Loaded_text.String=['File loaded: '...
        handles.output.filename];
    %Update the current folder to locate the appropriate directory (as long
    %as the analysis file and the analysis folder are in the same
    %directory, the program will work)
    handles.output.filepath=filepath;
    handles.output.filesfolder= [filepath filename(1:end-4) ...
        ' analysis files/'];
    handles.output.temp_mask_path=[handles.output.filesfolder ...
        handles.output.filename(1:end-4) ' tempMask.tif'];
    %Enable save button and detect wells push button
    handles.Save_push_button.Enable='on';
    handles.Detect_wells_push.Enable='on';
    if isequal(handles.output.detect_wells_push_count,1)
        handles.Detect_wells_push.String=...
            'Re-do Well Detection';
        handles.Edit_wells_push.Enable='on';
        handles.Prepare_CP_push.Enable='on';
        handles.images_menu.Enable='on';
        handles.relocate_menu.Enable='on';
    end
    if isequal(handles.output.prepare_CP_push_count,1)
        handles.Prepare_CP_push.String='Re-do CellProfiler Preparation';
        handles.Import_CP_push.Enable='on';
    end
    if isequal(handles.output.import_CP_push_count,1)
        handles.Import_CP_push.String='Re-Import CellProfiler Data';
        handles.Edit_cells_push.Enable='on';
    end
    if isequal(handles.output.align_signal,1)
        handles.extract_export_push.Enable='on';
    end
    %Compatibility - add numWells if it isn't already there
    if ~isfield(handles.output,'numWells')
        handles.output.numWells=220;
    end
    % Update handles structure
    guidata(handles.Load_fig, handles);
    delete(h);
end
end


% --- Executes on button press in Import_CP_push.
function Import_CP_push_Callback(hObject, eventdata, handles)
% hObject    handle to Import_CP_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if handles.output.import_CP_push_count==0
    cell_locations(handles);
    
elseif handles.output.import_CP_push_count==1;
    quest_ans=questdlg(...
        'Are you sure you want to re-do the CellProfiler import?',...
        'Warning!','Yes','No','No');
    if strcmp(quest_ans,'Yes')
        cell_locations(handles);
    end
end

end



% --- Executes on button press in Prepare_CP_push.
function Prepare_CP_push_Callback(hObject, eventdata, handles)
% hObject    handle to Prepare_CP_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% For cutting images and using cellprofiler...

if handles.output.prepare_CP_push_count==0;
    CPprep(handles);
    
elseif handles.output.prepare_CP_push_count==1;
    quest_ans=questdlg(...
        'Are you sure you want to re-do the CellProfiler preparation?',...
        'Warning!','Yes','No','No');
    if strcmp(quest_ans,'Yes')
        CPprep(handles);
    end
end
end

%--------------------------------
%% For making large mask and matlab detection...

% if handles.output.prepare_CP_push_count==0;
%     %Make new mask
%     %Find visible wells and use only those
%     h=waitbar(0.1,'Making well mask...');
%     vis_ind=cellfun(@find,handles.output.visibility,'UniformOutput',0);
%     for i=1:14
%         vis_wells{i}=handles.output.well_borders{i}(vis_ind{i});
%         %Index to large image (instead of cut images)
%         vis_wells_large{i}=cellfun(@(X) [X(:,1) X(:,2)+...
%             handles.output.tab_min(i)-1], vis_wells{i},'UniformOutput',0);
%     end
%     %Linearize the well locations into a single vector
%     well_ind=vertcat(vis_wells_large{:});
%     well_ind=vertcat(well_ind{:});
%     %Get image info to make a mask
%     img_info=imfinfo([handles.output.darkfield_imgpath...
%         handles.output.darkfield_imgname]);
%     %Make logical mask of all zeros of appropriate size
%     BW1=logical(zeros(img_info.Height,img_info.Width));
%     %Use indexes of well borders to outline wells using linear indexing
%     well_ind_linear=sub2ind([img_info.Height img_info.Width],well_ind(:,1),well_ind(:,2));
%     BW1(well_ind_linear)=1;
%     %Fill in the holes to generate mask
%     waitbar(0.4,h,'Filling in holes...')
%     BW2=imfill(BW1,'holes');
%     clear BW1
%     %Save Mask
%     waitbar(0.8,h,'Saving mask image...')
%     handles.output.real_mask_path=[handles.output.filesfolder ...
%         handles.output.filename(1:end-4) ' realMask.tif'];
%     imwrite(BW2,handles.output.real_mask_path,'tiff');
%     guidata(hObject,handles);
%     delete(h)
%     cell_locs=detect_cells(handles.Load_fig,BW2);
%     clear BW2;
%     %     save([handles.output.filepath ...
%     %         handles.output.filename],'-struct','handles','output')
%
% elseif handles.output.prepare_CP_push_count==1;
%     quest_ans=questdlg(...
%         'Are you sure you want to re-do the cell detection?',...
%         'Warning!','Yes','No','No');
%     if strcmp(quest_ans,'Yes')
%
%
%     end
% end



%% --------------------------------------------------------------------
function Save_push_button_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Save_push_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h=waitbar(0.5,sprintf('Saving file: %s ...\n',handles.output.filename),...
    'WindowStyle','modal');
save([handles.output.filepath handles.output.filename],...
    '-struct','handles','output')
delete(h);
end



% --- Executes on button press in Detect_wells_push.
function Detect_wells_push_Callback(hObject, eventdata, handles)
% hObject    handle to Detect_wells_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(handles.output.detect_wells_push_count,0)
    detect_wells_fitc(handles);
    
else
    buttonName=questdlg('Do you want to re-do the well detection?', ...
        'Well Detection');
    if strcmpi(buttonName,'yes')
        detect_wells_fitc(handles);
        
    end
end
end


% --- Executes on button press in Edit_wells_push.
function Edit_wells_push_Callback(hObject, eventdata, handles)
% hObject    handle to Edit_wells_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles.output,'fitc_imgpath')
    
    hmsg1=msgbox('Load FITC Image','help','modal');
    uiwait(hmsg1)
    [imgname, imgpath]= uigetfile('.tif','Choose FITC Image',...
        handles.output.phase_imgpath);
    if isequal(imgname,0) || isequal(imgpath,0)
        disp('User pressed cancel')
        return;
    else
        handles.output.fitc_imgpath=imgpath;
        handles.output.fitc_imgname=imgname;
        %Save guidata
        guidata(handles.Load_fig, handles);
        %Save to disk
        save([handles.output.filepath handles.output.filename],...
            '-struct','handles','output')
    end
end
Master_analysis_GUI(handles.Load_fig,'wells');
handles.Prepare_CP_push.Enable='on';
end


% --- Executes on button press in Edit_cells_push.
function Edit_cells_push_Callback(hObject, eventdata, handles)
% hObject    handle to Edit_cells_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Pass all information stored in handles to GUI to count cells
if ~isfield(handles.output,'phase_imgpath')
    
    hmsg1=msgbox('Load Phase Image','help','modal');
    uiwait(hmsg1)
    [imgname, imgpath]= uigetfile('.tif','Choose Oblique Image',...
        handles.output.fitc_imgpath);
    if isequal(imgname,0) || isequal(imgpath,0)
        disp('User pressed cancel')
        return;
    else
        handles.output.phase_imgpath=imgpath;
        handles.output.phase_imgname=imgname;
        %Save guidata
        guidata(handles.Load_fig, handles);
        %Save to disk
        save([handles.output.filepath handles.output.filename],...
            '-struct','handles','output')
    end
end
Master_analysis_GUI(handles.Load_fig,'cellsandsignal');
% Update handles structure from output of GUIforcells
% handles=guidata(handles.Load_fig);
% guidata(hObject, handles);
end


% --- Executes on button press in extract_export_push.
function extract_export_push_Callback(hObject, eventdata, handles)
% hObject    handle to extract_export_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
extract_signal(handles.Load_fig);
end


% --------------------------------------------------------------------
function images_menu_Callback(hObject, eventdata, handles)
% hObject    handle to images_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function relocate_menu_Callback(hObject, eventdata, handles)
% hObject    handle to relocate_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(handles.output.detect_wells_push_count,1)
    
    hmsg1=msgbox('Load FITC Image','help','modal');
    uiwait(hmsg1)
    [imgname, imgpath]= uigetfile('.tif','Choose FITC Image',...
        handles.output.filepath);
    if isequal(imgname,0) || isequal(imgpath,0)
        disp('User pressed cancel')
        return
    else
        handles.output.fitc_imgname=imgname;
        handles.output.fitc_imgpath=imgpath;
    end
    
end

if isequal(handles.output.prepare_CP_push_count,1)
    
    hmsg1=msgbox('Load Phase Image','help','modal');
    uiwait(hmsg1)
    [imgname, imgpath]= uigetfile('.tif','Choose Oblique Image',...
        handles.output.fitc_imgpath);
    if isequal(imgname,0) || isequal(imgpath,0)
        disp('User pressed cancel')
        return
    else
        handles.output.phase_imgname=imgname;
        handles.output.phase_imgpath=imgpath;
    end
    
end

if isequal(handles.output.align_signal,1)
    
    hmsg1=msgbox('Choose TRITC microscope Image','help','modal');
    uiwait(hmsg1)
    [tritcname, tritcpath]= uigetfile('.tif','Choose FITC microscope Image',...
        handles.output.fitc_imgpath);
    if isequal(tritcname,0) || isequal(tritcpath,0)
        disp('User pressed cancel')
        return;
    else
        %Get the Genepix FITC image
        hmsg1=msgbox('Choose GenePix 555nm Image','help','modal');
        uiwait(hmsg1)
        [g555name, g555path]= uigetfile('.tif','Choose GenePix 488nm Image',...
            tritcpath);
        if isequal(g555name,0) || isequal(g555path,0)
            disp('User pressed cancel')
            return;
        else
            %Get the Genepix signal data (635)
            hmsg1=msgbox('Choose GenePix 635nm Image','help','modal');
            uiwait(hmsg1)
            [g635name, g635path]= uigetfile('.tif','Choose GenePix 635nm Image',...
                g555path);
            if isequal(g635name,0) || isequal(g635path,0)
                disp('User pressed cancel')
                return;
            else
                handles.output.fitc_imgpath=tritcpath;
                handles.output.fitc_imgname=tritcname;
                handles.output.g555_imgpath=g555path;
                handles.output.g555_imgname=g555name;
                handles.output.g635_imgpath=g635path;
                handles.output.g635_imgname=g635name;
            end
        end
    end

end
% Update handles structure
guidata(handles.Load_fig, handles);
end
