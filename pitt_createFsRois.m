function [subs n] = pitt_createFsRois(baseDir,procStage)
% 
% function subs = pitt_getSubs(baseDir)
% 
% This funtion will return a cell array of subjects' directories that contains
% which subjects need to be processed at a given stage of the pipeline.
% 

% Author: LMP 2012
% 
%#ok<*REMFF1>


%% Check INPUT

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select a Base Directory');
end

if ~exist('procStage','var') || ~isstr(procStage)
    procStage = 'freeseg';
end

%% Initialize the structure and the counters

subs.sort       = {};
subs.anatproc   = {};
subs.dti        = {};
subs.freeseg    = {};
subs.wbfibertrack = {};
subs.morifibertrack = {};

sns  = 0;
sna  = 0;
snd  = 0;
snfs = 0;
snwbf  = 0;
snmf  = 0;

%% Return a cell array with the full paths to all subject directories 
 
dirsTextFile = fullfile(baseDir,'.dirs.txt');

cmd  = sprintf('ls -1 %s > %s', baseDir, dirsTextFile); system(cmd);
dirs = textread(dirsTextFile,'%s'); 
cmd  = sprintf('rm %s', dirsTextFile); system(cmd);

% Loop over the array and return only those that are directories
for i = sort(1:numel(dirs),'descend'); 
    if isdir(fullfile(baseDir,dirs{i})) && ~strcmp(dirs{i},'logs') && ~strcmp(dirs{i},'freesurfer')
        dirs{i} = fullfile(baseDir,dirs{i});
    else
        dirs(i) = [];
    end
end

% Return the total number of directories
n = numel(dirs);


%% Loop over the dirs and find which subjects need to be processed at each
%  stage of the pipeline. 

% Do it all here
% This is going to be a bunch of if statements to check if a given
% subject has the hidden files left behind after a given stage in the
% pipeline has been run.
for ii=1:numel(dirs)
    
    mrdir         = fullfile(dirs{ii},'mrDiffusion');
    sorted        = fullfile(mrdir,'.sorted');
    anatproc      = fullfile(mrdir,'.anatproc');
    dtiproc       = fullfile(mrdir,'.dtiproc');
    fseg          = fullfile(mrdir,'.freeseg');
    wbfiberproc   = fullfile(mrdir,'.wholebrainfiberproc');
    morifiberproc = fullfile(mrdir,'.morifiberproc');
   
    
    % Check for subjects that need to be sorted. 
    if ~exist(sorted,'file') 
       sns = sns+1;
       subs.sort{sns} = dirs{ii};
    end
    
    % Check for subjects that need anatomy file processed
    if ~exist(anatproc,'file') && exist(sorted,'file')
       sna = sna+1;
       subs.anatproc{sna} = dirs{ii};
    end
    
    % Check for subjects that need diffusion data processed
    if ~exist(dtiproc,'file') && exist(anatproc,'file')
       snd = snd+1;
       subs.dti{snd} = dirs{ii};
    end
    
    % Check for subjects that need freesurfer segmentation done
    if exist(fseg,'file') && exist(anatproc,'file')
       snfs = snfs+1;
       subs.freeseg{snfs} = dirs{ii};
    end
    
    % Check for subjects that need whole-brain fibers created
    if ~exist(wbfiberproc,'file') && exist(dtiproc,'file')
       snwbf = snwbf+1;
       subs.wbfibertrack{snwbf} = dirs{ii};
    end
    
    % Check for subjects that need mori-fibers created
    if ~exist(morifiberproc,'file') && exist(wbfiberproc,'file') && exist(dtiproc,'file')
       snmf = snmf+1;
       subs.morifibertrack{snmf} = dirs{ii};
    end
    
end


%% Return subs cell array to the user switching on procStage input

switch lower(procStage)
    case 'sort'
        subs = subs.sort;
    case 'anatproc'
        subs = subs.anatproc;
    case 'dtiproc'
        subs = subs.dti;
    case 'freeseg'
        subs = subs.freeseg;
    case {'wbfibertrack', 'wholebrainfibertrack'}
        subs = subs.wbfibertrack;
    case {'morifibertrack', 'mori'}
        subs = subs.morifibertrack;
end

for ii=1:numel(subs)
    sd = fullfile(baseDir,'freesurfer');
    % Set up the path to files needed to run the recon
    mrdDir = fullfile(subs{ii},'mrDiffusion');
    [~, subID ~] = fileparts(subs{ii});
    
    % Path to the segfile
    segFile = fullfile(sd,subID,'mri','aparc+aseg.mgz');
    
    fprintf('\nRunning subject %s...\n',subID);
    
    
    
    % CREATE ROIS: Here we will create the ROIs for each subject.
    fprintf(' Creating freesurfer ROIs from the segmentation file: %s\n', segFile);
    
    fs_roisFromAllLabels([segFile(1:end-4) '.nii.gz'],fullfile(mrdDir,'ROIs','freesurfer'),'nifti',fullfile(mrdDir,'t1','t1acpc.nii.gz'));
    
    
    
end

return


