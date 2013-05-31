function subsProc = pitt_trackWholeBrainFibers(baseDir)
% 
% fg = pitt_trackWholeBrainFibers(baseDir)
% 
% Perform fiber tracking of the entire brain for each subject in baseDir
% that is in the proper place in the pipeline. 
% 
% INPUTS:
%       baseDir     - directory containing the subjects' directories
% 
% OUTPUTS:
%       subsProc    - a cell array containing the path to each subject
%                     processed.
% 
% EXAMPLE USAGE:
%       baseDir   = '/path/to/subject/directories'
%       subsProc  = pitt_trackWholeBrainFibers(baseDir);
% 
% 

%  Author: LMP [2012]
%#ok<*AGROW>


%% CHECK INPUT

fprintf('\n[%s] \n', mfilename);

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select your base directory');
end


%% Get subjects

subs = pitt_getSubs(baseDir,'wbfibertrack');
subsProc = {};

% Commenting out this code so it won't be slowing things down. 
% warn = sprintf('This process will track whole-brain fibers for %d subjects.\n    This process will take ~%d hours!\n    Do you want to continue?',numel(subs),round(numel(subs)*.5));
% resp = questdlg(warn,'pitt_trackWholeBrainFibers','YES','NO','YES');
% if strcmp(resp,'NO')
%     disp('User cancelled.')
%     return
% end


%% Initialize and format the log file

if ~isempty(subs)
    logDir = fullfile(baseDir,'logs');
    
    if ~exist(logDir,'dir'), mkdir(logDir); end
    
    logFileName = fullfile(logDir,'trackWholeBrainFibers.txt');
    log         = fopen(logFileName,'a');
    
    fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);
    fprintf(log,'Tracking Whole-Brain Fibers for: %d subjects \n---\n',numel(subs));
    fprintf('Tracking Whole-Brain Fibers for %d subjects...\n---\n',numel(subs));
else
    fprintf('  No subjects found that can be tracked at this time.\n');
    return
end

% Initialize counters
sp       = 0;
subsProc = {};
err      = 0; 
errFlag  = false;


%% Loop over the subjects and track the fibers

for ii = 1:numel(subs)
    
    fprintf(log,'Processing %s...',subs{ii});
    sprintf('Processing %s...',subs{ii});
    
    mrdDir   = fullfile(subs{ii},'mrDiffusion');
    dt6Dir   = fullfile(mrdDir,'dti60trilin');
    dt6File  = fullfile(dt6Dir,'dt6.mat');
    fiberDir = fullfile(dt6Dir,'fibers');
    
    % HERE: CHECK FOR AND WRITE THE "WORKING" FILE, which will allow us to
    % keep track of which subjects are currently being worked on by another
    % process.
    % Path to the work file
    workFile = fullfile(mrdDir,'.workingwbfibertrack');
    
    if ~exist(workFile,'file')
        
        % Write the working file
        workCmd = sprintf('echo %s > %s',getDateAndTime,workFile);
        system(workCmd);
        
        % Load the dt6 file
        dt = dtiLoadDt6(dt6File);
        
        % Set fiber tracking parameters Track all white matter fibers in the
        % native subject space. We do this by seeding all voxels with high FA
        % (>0.3).
        faThresh              = 0.30;
        opts.stepSizeMm       = 1;
        opts.faThresh         = .2; %0.15
        opts.lengthThreshMm   = [20 250];
        opts.angleThresh      = 50;
        opts.wPuncture        = 0.2;
        opts.whichAlgorithm   = 1;
        opts.whichInterp      = 1;
        opts.seedVoxelOffsets = [-0.25 0.25];
        opts.offsetJitter     = 0.1;
        
        % Get the FA and create the mask ROI
        fa = dtiComputeFA(dt.dt6);
        fa(fa>1) = 1; fa(fa<0) = 0;
        
        roiAll  = dtiNewRoi('all');
        mask    = dtiCleanImageMask(fa>=faThresh);
        [x,y,z] = ind2sub(size(mask), find(mask));
        clear mask fa;
        
        roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
        clear x y z;
        
        % Perform the fiber tracing
        fg = dtiFiberTrack(dt.dt6, roiAll.coords, dt.mmPerVoxel, dt.xformToAcpc, 'WholeBrainFG', opts);
        clear roiAll
        
        % Write out the fiber group
        dtiWriteFiberGroup(fg,fullfile(fiberDir,'WholeBrainFG'));
        fgWrite(fg,fullfile(fiberDir,'WholeBrainFG'),'pdb');
        clear fg
        
        
        % Write a file in the raw directory that will keep track of the
        % subject's raw data being processed.
        if exist(fullfile(fiberDir,'WholeBrainFG.mat'),'file')
            fprintf(log,'success.\n');
            fprintf('\n %s processed successfully.\n',mrvDirup(mrdDir));
            sp = sp+1;
            subsProc{sp} = mrvDirup(mrdDir);
            tmgCmd = sprintf('echo %s > %s',getDateAndTime,(fullfile(mrdDir,'.wholebrainfiberproc')));
            system(tmgCmd);
        else
            errFlag = true;
            err     = err+1;
            subsErr{err} = subs{ii};
        end
        
        % HERE: REMOVE THE "WORKING FILE"
        delete(workFile);
    else
        % HERE: END THE CHECK FOR THE "WORKING FILE"
        fprintf('\nSkipping %s - "working" file found.\n',subs{ii});
    end
    
end


%% Show some outputs to the command window that will show which subjects 
%  have been processed correctly and which had errors.

if errFlag
    fprintf('\nError(s) occurred. Please check the logFile: \n \t %s\n',logFileName);
    fprintf('\nThe following subjects returned errors:\n');    
    fprintf(log,'\nThe following subjects returned errors:\n');

    for e = 1:numel(subsErr)
        fprintf('%s\n',subsErr{e});
        fprintf(log,'%s\n',subsErr{e});
    end
else
    fprintf('\nNo errors occurred during execution.\n');
    
end

fprintf('\nThe following subjects were processed successfully:\n');
fprintf(log,'\nThe following subjects were processed successfully:\n');
for s = 1:numel(subsProc)
    fprintf('%s\n',subsProc{s});
    fprintf(log,'%s\n',subsProc{s});
end


return