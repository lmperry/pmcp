function subsProc = pitt_trackMoriFibers(baseDir)
% 
% Perform fiber tractography on a group of subjects who have the required
% data processing complete in the baseDir. This will perform tractography
% based on the Mori atlas. 
% 
% This function will recursively search the base directory and find those
% subjects that need fibers processed. This function can then either feed
% into the next step in the pipeline, or it can do the analysis here. 
% 
% The analysis should be saved in either the base directory or it should be
% saved in each subjects directory. It could be concatenated each time a
% seperate analysis script is run ... NEED to think about that. Look into
% using dtiFiberProperties
% 
% *** THERE SHOULD be a whole brain fiber group tracked before this step!!
% 
% INPUTS:
%       baseDir - The directory containing the subjects' data folders
% 
% OUTPUTS:
%       fgs     - a cell array containing the paths to each subject's
%                 resulting fiber groups
% 

% AUTHOR: LMP [2012]
%#ok<*AGROW>


%% INPUTS

fprintf('\n [%s] \n', mfilename);

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select your base directory');
end


%% Get subjects that are ready for fiber tractography

subs = pitt_getSubs(baseDir,'mori');
subsProc = {};

%% Initialize and format the log file

if ~isempty(subs)
    logDir = fullfile(baseDir,'logs');
    
    if ~exist(logDir,'dir'), mkdir(logDir); end
    
    logFileName = fullfile(logDir,'trackMoriFibers.txt');
    log         = fopen(logFileName,'a');
    
    fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);
    fprintf(log,'Tracking Mori Fibers for: %d subjects \n---\n',numel(subs));
    fprintf('Tracking Mori Fibers for %d subjects...\n---\n',numel(subs));
else
    fprintf('  No subjects found that can be tracked at this time.\n');
    return
end
sp       = 0;
subsProc = {};
err      = 0; 
errFlag  = false;


%% Loop over the subjects and track the fibers

% There should be a whole brain fiber group that exists before this step.
for ii = 1:numel(subs)
    
    fprintf(log,'Processing %s...',subs{ii});
    fprintf('Processing %s...\n',subs{ii});
    
    mrdDir   = fullfile(subs{ii},'mrDiffusion');
    dt6Dir   = fullfile(mrdDir,'dti60trilin');
    dt6File  = fullfile(dt6Dir,'dt6.mat');
    fiberDir = fullfile(dt6Dir,'fibers');
    wbFibers = fullfile(fiberDir,'WholeBrainFG.mat');
    
    % HERE: CHECK FOR AND WRITE THE "WORKING" FILE, which will allow us to
    % keep track of which subjects are currently being worked on by another
    % process.
    % Path to the work file
    workFile = fullfile(mrdDir,'.workingmorifibertrack');
    
    if ~exist(workFile,'file')
        
        % Write the working file
        workCmd = sprintf('echo %s > %s',getDateAndTime,workFile);
        system(workCmd);
        
        % Do the MORI classification
        dtiFindMoriTracts(dt6File,[],wbFibers,[],[],true,true);
        
        % Write out the fiber groups : We don't need to do this here as the
        % function above will save the fibers for us.
        % fgWrite(fg,fullfile(fiberDir,'MoriGroups_fgW.mat'));
        %clear fg
        % fgWrite(fg_uclass, fullfile(fiberDir,'MoriGroups_unClass_fgW.mat'));
        % clear fg_uclass
        
        % Write a file in the raw directory that will keep track of the
        % subject's raw data being processed.
        if exist(fullfile(fiberDir,'MoriGroups.mat'),'file')
            fprintf(log,'success.\n');
            fprintf('%s processed successfully.\n',mrvDirup(mrdDir));
            sp = sp+1;
            subsProc{sp} = mrvDirup(mrdDir);
            tmgCmd = sprintf('echo %s > %s',getDateAndTime,(fullfile(mrdDir,'.morifiberproc')));
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