function varargout = pittdti(varargin)
% PITTDTI MATLAB code for pittdti.fig
%      PITTDTI, by itself, creates a new PITTDTI or raises the existing
%      singleton*.
%
%      H = PITTDTI returns the handle to a new PITTDTI or the handle to
%      the existing singleton*.
%
%      PITTDTI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PITTDTI.M with the given input arguments.
%
%      PITTDTI('Property','Value',...) creates a new PITTDTI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pittdti_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pittdti_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pittdti

% Last Modified by GUIDE v2.5 05-Apr-2012 20:56:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pittdti_OpeningFcn, ...
                   'gui_OutputFcn',  @pittdti_OutputFcn, ...
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


% --- Executes just before pittdti is made visible.
function pittdti_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pittdti (see VARARGIN)
fprintf('\n** PITT DTI PROCESSING TOOLBOX **\n');
fprintf('Base directory for this session: ');
handles.baseDir = uigetdir(pwd,'Select the base directory for this session');
fprintf('%s\n', handles.baseDir);
% Choose default command line output for pittdti
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes pittdti wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pittdti_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in showSubjectStatusButton.
function showSubjectStatusButton_Callback(hObject, eventdata, handles)
% hObject    handle to showSubjectStatusButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if notDefined('handles.baseDir')
%     handles.baseDir = uigetdir(pwd,'select base directory');
% end

fprintf('\n Gathering stats. Please be patient ...\n');

[subs n] = pitt_getSubs(handles.baseDir);

fprintf('\nSUBJECT STATUS: %d subjects in %s\n',n, handles.baseDir) 
fprintf('...\nTO DO:\n');
fprintf(' %d/%d subject(s) ready for Sorting\n',numel(subs.sort),n);
fprintf(' %d/%d subject(s) ready for Anatomical processing\n',numel(subs.anatproc),n);
fprintf(' %d/%d subject(s) ready for Diffusion preprocessing\n',numel(subs.dti),n);
fprintf(' %d/%d subject(s) ready for Freesurfer segmentation\n',numel(subs.freeseg),n);
fprintf(' %d/%d subject(s) ready for Whole-brain fiber tractography\n',numel(subs.wbfibertrack),n);
fprintf(' %d/%d subject(s) ready for Mori fiber tractography\n',numel(subs.morifibertrack),n);

disp('...');

[subs_c] = pitt_getStatus(handles.baseDir);

disp('DONE:'); 
fprintf(' %d/%d subject(s) done with Sorting\n',numel(subs_c.sort),n);
fprintf(' %d/%d subject(s) done with Anatomical processing\n',numel(subs_c.anatproc),n);
fprintf(' %d/%d subject(s) done with Diffusion preprocessing\n',numel(subs_c.dti),n);
fprintf(' %d/%d subject(s) done with Freesurfer segmentation\n',numel(subs_c.freeseg),n);
fprintf(' %d/%d subject(s) done with Whole-brain fiber tractography\n',numel(subs_c.wbfibertrack),n);
fprintf(' %d/%d subject(s) done with Mori fiber tractography\n\n',numel(subs_c.morifibertrack),n);


return


% --- Executes on button press in sortDataButton.
function sortDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to sortDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_sortData(handles.baseDir);
return

% --- Executes on button press in processAnatomyButton.
function processAnatomyButton_Callback(hObject, eventdata, handles)
% hObject    handle to processAnatomyButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_processAnatomy(handles.baseDir);
return


% --- Executes on button press in processDtiButton.
function processDtiButton_Callback(hObject, eventdata, handles)
% hObject    handle to processDtiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_preprocessDiffusion(handles.baseDir);
return

% --- Executes on button press in trackWholeBrainFibersButton.
function trackWholeBrainFibersButton_Callback(hObject, eventdata, handles)
% hObject    handle to trackWholeBrainFibersButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_trackWholeBrainFibers(handles.baseDir);
return


% --- Executes on button press in trackMoriFiberGroupsButton.
function trackMoriFiberGroupsButton_Callback(hObject, eventdata, handles)
% hObject    handle to trackMoriFiberGroupsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_trackMoriFibers(handles.baseDir);
return

% --- Executes on button press in pittFiberTrackerButton.
function pittFiberTrackerButton_Callback(hObject, eventdata, handles)
% hObject    handle to pittFiberTrackerButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ftgui;
%warndlg('This function is not yet implemented...','pitt_fiberTracker');
return


% --- Executes on button press in segmentAnatomicalsPushbutton.
function segmentAnatomicalsPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to segmentAnatomicalsPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_segmentAnatomy(handles.baseDir);
return


% --- Executes on button press in runAllButton.
function runAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to runAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pitt_processAll(handles.baseDir);
return
