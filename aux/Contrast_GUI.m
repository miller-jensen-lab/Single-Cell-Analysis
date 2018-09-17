function varargout = Contrast_GUI(varargin)
% CONTRAST_GUI MATLAB code for Contrast_GUI.fig
%      CONTRAST_GUI, by itself, creates a new CONTRAST_GUI or raises the existing
%      singleton*.
%
%      H = CONTRAST_GUI returns the handle to a new CONTRAST_GUI or the handle to
%      the existing singleton*.
%
%      CONTRAST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTRAST_GUI.M with the given input arguments.
%
%      CONTRAST_GUI('Property','Value',...) creates a new CONTRAST_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Contrast_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Contrast_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Contrast_GUI

% Last Modified by GUIDE v2.5 12-May-2015 13:19:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Contrast_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Contrast_GUI_OutputFcn, ...
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


% --- Executes just before Contrast_GUI is made visible.
function Contrast_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Contrast_GUI (see VARARGIN)
genepix488=varargin{1};
genepix635=varargin{2};
microscope=varargin{3};
handles.RGB_gene=cat(3,genepix635,genepix488,zeros(size(genepix635),'uint8'));
handles.RGB_mic=cat(3,zeros(size(microscope),'uint8'),microscope,zeros(size(microscope),'uint8'));
handles.genepix_axes=axes('Parent',handles.uipanel_genepix);
handles.genepix_image=imshow(handles.RGB_gene,[],'Parent',handles.genepix_axes);
handles.mic_axes=axes('Parent',handles.uipanel_microscope);
handles.mic_image=imshow(handles.RGB_mic,[],'Parent',handles.mic_axes);

%Make scroll panels
handles.scroll_genepix=imscrollpanel(handles.uipanel_genepix,...
    handles.genepix_image);
handles.api_scroll_genepix=iptgetapi(handles.scroll_genepix);
handles.api_scroll_genepix.setVisibleLocation(1,1);
handles.api_scroll_genepix.setMagnification(0.5);

handles.scroll_mic=imscrollpanel(handles.uipanel_microscope,...
    handles.mic_image);
handles.api_scroll_mic=iptgetapi(handles.scroll_mic);
handles.api_scroll_mic.setVisibleLocation(1,1);
handles.api_scroll_mic.setMagnification(0.5);


% Choose default command line output for Contrast_GUI
% handles.output = 1;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Contrast_GUI wait for user response (see UIRESUME)
hmsg=msgbox('Adjust contrast of images until you can see the wells and 488 signal clearly',...
    'help','modal');
uiwait(hmsg);
uiwait(handles.Contrast_GUI);


% --- Outputs from this function are returned to the command line.
function varargout = Contrast_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1}=[];
    delete(hObject);
else
    varargout{1} = handles.output;
    delete(hObject);
end







% --- Executes on button press in done_push.
function done_push_Callback(hObject, eventdata, handles)
% hObject    handle to done_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.moving=handles.genepix_image.CData;
handles.output.fixed=handles.mic_image.CData;
handles.output.contrast_value_mic=handles.contrast_slider_mic.Value*0.01;
handles.output.contrast_value_gene=handles.contrast_slider_gene.Value*0.01;
guidata(handles.Contrast_GUI,handles);
uiresume(handles.Contrast_GUI);


% --- Executes on scroll wheel click while the figure is in focus.
function Contrast_GUI_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to Contrast_GUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function contrast_slider_mic_Callback(hObject, eventdata, handles)
% hObject    handle to contrast_slider_mic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
contrast_value=get(hObject,'Value')*0.01;
limits=stretchlim(handles.RGB_mic,contrast_value);
handles.mic_image.CData=imadjust(handles.RGB_mic,limits);



% --- Executes during object creation, after setting all properties.
function contrast_slider_mic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contrast_slider_mic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',0);
set(hObject,'SliderStep',[.1 .2]);
set(hObject,'Max',10);



% --- Executes on slider movement.
function contrast_slider_gene_Callback(hObject, eventdata, handles)
% hObject    handle to contrast_slider_gene (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
contrast_value=get(hObject,'Value')*0.01;
limits=stretchlim(handles.RGB_gene,contrast_value);
set(handles.genepix_image,'CData',imadjust(handles.RGB_gene,limits));
drawnow;



% --- Executes during object creation, after setting all properties.
function contrast_slider_gene_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contrast_slider_gene (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',0);
set(hObject,'SliderStep',[.1 .2]);
set(hObject,'Max',10);


% --- Executes on button press in zoom_out_mic_push.
function zoom_out_mic_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_out_mic_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currmag=handles.api_scroll_mic.getMagnification();
handles.api_scroll_mic.setMagnification(currmag-0.1);

% --- Executes on button press in zoom_in_mic_push.
function zoom_in_mic_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_in_mic_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currmag=handles.api_scroll_mic.getMagnification();
handles.api_scroll_mic.setMagnification(currmag+0.1);


% --- Executes on button press in zoom_in_gene_push.
function zoom_in_gene_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_in_gene_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currmag=handles.api_scroll_genepix.getMagnification();
handles.api_scroll_genepix.setMagnification(currmag+0.1);

% --- Executes on button press in zoom_out_gene_push.
function zoom_out_gene_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_out_gene_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currmag=handles.api_scroll_genepix.getMagnification();
handles.api_scroll_genepix.setMagnification(currmag-0.1);
