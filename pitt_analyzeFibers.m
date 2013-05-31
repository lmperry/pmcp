function fgvals = pitt_analyzeFibers(baseDir)
% 
%  subsProc = pitt_analyzeFibers(baseDir)
% 
% 
% Perform fiber analyzis of any fibers that exist in the fibers directory. 
% 
% INPUTS:
%       baseDir   - directory containing the subjects' directories
% 
% OUTPUTS:
%       fgvals    - a cell array containing the values for each fiber group
%                 - or an exported file that has the data. Need to decide
%                  this.
% 
% EXAMPLE USAGE:
%       baseDir   = '/path/to/subject/directories'
%       fgvals  = pitt_analyzeFibers(baseDir);
% 
% 

% *** Going to have to analyze the morigroups seperately. 

%  Author: LMP [2013]
%#ok<*AGROW>


%% CHECK INPUT

fprintf('\n[%s] \n', mfilename);

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select your base directory');
end


%% Get subjects

subs = pitt_getSubs(baseDir,'fibertrack');
fgvals = {};


%% Initialize and format the log file

if ~isempty(subs)
    logDir = fullfile(baseDir,'logs');
    
    if ~exist(logDir,'dir'), mkdir(logDir); end
    
    logFileName = fullfile(logDir,'analyzeBrainFibers.txt');
    log         = fopen(logFileName,'a');
    
    fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);
    fprintf(log,'Analyzing Fibers for: %d subjects \n---\n',numel(subs));
    fprintf('Analyzing Fibers for %d subjects...\n---\n',numel(subs));
else
    fprintf('  No subjects found that can be Analyzed at this time.\n');
    return
end

% Initialize counters
sp       = 0;
subsProc = {};
err      = 0; 
errFlag  = false;


%% Loop over the subjects and process the fibers

for ii = 1:numel(subs)
    
    fprintf(log,'Processing %s...',subs{ii});
    sprintf('Processing %s...',subs{ii});
    
    mrdDir   = fullfile(subs{ii},'mrDiffusion');
    dt6Dir   = fullfile(mrdDir,'dti60trilin');
    dt6File  = fullfile(dt6Dir,'dt6.mat');
    fiberDir = fullfile(dt6Dir,'fibers');
    
    % PROBABLY DON'T NEED A WORKING FILE: CHECK FOR AND WRITE THE "WORKING"
    % FILE, which will allow us to keep track of which subjects are
    % currently being worked on by another process. Path to the work file
    workFile = fullfile(mrdDir,'.workinganalyzefibers');
    
    if ~exist(workFile,'file')
        
        % Write the working file
        workCmd = sprintf('echo %s > %s',getDateAndTime,workFile);
        system(workCmd);
        
        % Load the dt6 file
        dt = dtiLoadDt6(dt6File);
        
        % Loop over the directory and find each fiber group 
        
        % Load the fibergroup
        
        % Get the fiber properties - using dtiGetValFromTensor(or something
        % like this) ---- see the span file for consistency. 
        
        % Add the values to the text file
        
        
        % DONT THINK WE NEED THIS: Write a file in the raw directory that
        % will keep track of the subject's raw data being processed.
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