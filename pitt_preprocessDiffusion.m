function [subsProc] = pitt_preprocessDiffusion(baseDir,subs,clobber,~)
% 
% [subsProc] = pitt_preprocessDiffusion([baseDir=uigetdir],[subs=[]], ... 
%               [clobber=false], [emailTo = 'lmperry@pitt.edu'])
% 
% This script/function will loop through a group of subjects and process
% their diffusion data using the tools in mrVista.
% 
% By default, with no arguments provided, this funciton will recursively
% search through all the directories within 'baseDir' looking for evidence
% that (1) the required files exist for preprocessing and (2) that a given
% subject has not been processed previously. 
% 
% In the case that a subject has been processed previously you can opt to
% re-run the processing by setting the 'clobber' flag to 'true'. If no
% 'subs' are specified in a cell array and passed in via the 'subs'
% variable all subjects will be processed and if 'clobber' = 'true' all
% their data will be clobbered and they will be reprocessed (careful). 
% 
% 
% INPUTS:
%       baseDir     - The top level directory which contains the subjects'
%                     directories
%       subs        - a cell array of subject directory names. By default
%                     this will be empy and recursively search the
%                     directories for evidence that each subject was
%                     processed.
%       clobber     - Force a reprocessing of the dti data from the ground
%                     up. If the subjects have already been processed their
%                     data will be overwritten and they will be processed
%                     again.
%       emailTo     - email address for the person who should receive the
%                     email and log file when the script is complete. 
% 
% 
% OUTPUTS:
%       subsProc    - A cell array containing the paths to those subjects
%                     that were processed during the running of this
%                     function.
% 
% EXAMPLE USAGE:
%       baseDir = '/data/DTI';
%       subs    = {'A229','A285'};
%       clobber = false;
% 
%       [subsProc] = pitt_preprocessDiffusion(baseDir,subs,clobber);
% 

% HISTORY:
%       2012 - LMP wrote it.

%% Supression
%#ok<*AGROW>
%#ok<*WNTAG>
%#ok<*REMFF1>


%% Check INPUTS

fprintf('\n[pitt_processDiffusion] ... \n\nStarting diffusion preprocessing ...\n');

if notDefined('baseDir');
    baseDir = uigetdir(pwd,'Select Base Directory');
    if baseDir == 0; error('User cancelled.'), end
end

if notDefined('subs')
    subs = [];
end

if notDefined('clobber')
    clobber = false;
end


%% Get back a cell array containing all the subjects' raw directories. 
%  Check for the existence of the raw directory and make sure that the 
%  subject has not been processed previously.

rawDirs = getRawDirs(baseDir,subs,clobber);


%% Initialize and format the log file

if ~isempty(rawDirs)
    logDir      = fullfile(mrvDirup(rawDirs{1},3),'logs');
else
    logDir = fullfile(baseDir,'logs');
end

if ~exist(logDir,'dir'), mkdir(logDir); end

logFileName = fullfile(logDir,'preprocessDTI.txt');
log         = fopen(logFileName,'a');

fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);
fprintf(log,'Processing DTI data for: %d subjects \n---\n',numel(rawDirs));
fprintf('Processing DTI data for %d subjects...\n---\n',numel(rawDirs));


%% Prompt user to continue
% if ~isempty(rawDirs)
%     prompt = sprintf('Running dtiInit on %d subjects... \n Would you like to continue?',numel(rawDirs));
%     answ = questdlg(prompt,'DTI_INITIALIZATION','YES','NO','YES');
%     if strcmp('YES',answ), answ = 1; else answ = 0; end
%     if answ ~=1
%         warning('User Cancelled: pitt_preprocessDiffusion');
%         return
%     end
% end


%% Initialize structures that will keep track of those subjects that were
%  processed correctly and those that had errors.

sp       = 0;
subsProc = {};

err      = 0; 
errFlag  = false;


%% Loop over each subject's raw directory and process their data

% Keep track of how much time it takes
tstart = tic;
for ii = 1:numel(rawDirs)
    
    % Set path to raw DTI data
    dtiNifti   = fullfile(rawDirs{ii},'dti.nii.gz');
    bvals      = fullfile(rawDirs{ii},'dti.bval');
    bvecs      = fullfile(rawDirs{ii},'dti.bvec');
    
    % Set path to mrdDir
    mrdDir = mrvDirup(rawDirs{ii});
    
    
    % HERE: CHECK FOR AND WRITE THE "WORKING" FILE, which will allow us to
    % keep track of which subjects are currently being worked on by another
    % process. 
    % Path to the work file
    workFile = fullfile(mrdDir,'.workingdtiproc');
    
    if ~exist(workFile,'file')
        
        % Write the working file
        workCmd = sprintf('echo %s > %s',getDateAndTime,workFile);
        system(workCmd);
        
        % I. Check for the existence of the raw DTI data and create them  from
        %    the dicoms if they don't exist
        if ~exist(dtiNifti,'file') || ~exist(bvals,'file') || ~exist(bvecs,'file')
            
            % Get the path to the raw dicom directory
            dcmDir = dir([rawDirs{ii} '/dti_*']);
            
            % This directory could be zipped to save space.
            if strfind(dcmDir(1).name(end-3:end),'.zip')
                unzipCmd = sprintf('unzip %s',dcmDir(1).name);
                [status result] = system(unzipCmd);
                if status ~= 0
                    warning('Problem unzipping raw data %s',rawDirs{ii});
                    fprintf(log,'Problem unzipping raw data: %s\n',result);
                else
                    disp('Raw data unzipped.');
                    % Remove the '.zip'
                    dcmDir(1).name = dcmDir(1).name(1:end-4);
                    dicomDir = fullfile(rawDirs{ii},dcmDir(1).name);
                end
            else
                dicomDir = fullfile(rawDirs{ii},dcmDir(1).name);
            end
            
            
            cd(dicomDir);
            fprintf('\nProcessing raw data in: %s\n',dicomDir);
            fprintf(log,'\nProcessing raw data in: %s\n',dicomDir);
            
            
            % Ia.Convert Raw dtiData to nifti format
            %    Execute the call to dcm2nii - which actually converts the dicoms
            %    to nifti
            disp('Converting dicoms to nifti format...');
            dcmcmd = 'dcm2nii *';
            [status result] = system(dcmcmd);
            if status ~= 0
                warning('Problem with creating raw nifti file %s',rawDirs{ii});
                fprintf(log,'Problem creating raw nifti: %s\n',result);
            else
                disp('Nifti created.');
            end
            
            
            % Ib. Rename the nifti files, bvals and bvecs and move them one dir up.
            mvcmd  = 'mv *bvec dti.bvec; mv *bval dti.bval; mv *.nii.gz dti.nii.gz; mv dti* ../';
            [status result] = system(mvcmd);
            if status ~= 0
                warning('Problem moving raw data %s',rawDirs{ii});
                fprintf(log,'Problem moving raw data: %s \n%s\n',result);
            else
                % Zip the dicom directory to save space
                cd(rawDirs{ii});
                zipCmd = sprintf('zip -rm %s %s',[dcmDir(1).name '.zip'],dcmDir(1).name);
                [status result] = system(zipCmd);
                if status ~= 0
                    warning('Problem zipping raw data %s',rawDirs{ii});
                    fprintf(log,'Problem creating zip file: %s\n',result);
                else
                    disp('Raw data zipped.');
                end
                
            end
        else
            fprintf('Raw diffusion files already created.\n');
        end
        
        
        % II. Get the path to the anatomical image
        t1AcpcFile = fullfile(mrvDirup(rawDirs{ii}),'t1','t1acpc.nii.gz');
        
        
        % III. Set the parameters specific to this protocol
        dwParams                = dtiInitParams;
        dwParams.phaseEncodeDir = 2;
        dwParams.dt6BaseName    = 'dti60trilin';
        dwParams.fitMethod      = 'lsrt';
        dwParams.bvecsFile      = bvecs;
        dwParams.bvalsFile      = bvals;
        dwParams.rotateBvecsWithCanXform = 1;
        % If clobber is 1, then we overwrite any existing data.
        if clobber, dwParams.clobber = 1; else dwParams.clobber = -1; end
        
        
        % IV. Make the call to dtiInit and process the data: Use a try/catch
        %     just in case something goes wrong - we can process the rest of the
        %     subjects.
        fprintf('Starting DTI preprocessing [dtiInit] for %s\n ...',mrvDirup(mrdDir));
        fprintf(log,'Starting DTI preprocessing [dtiInit] for %s ...',mrvDirup(mrdDir));
        tic;
        try
            dtiInit(dtiNifti,t1AcpcFile,dwParams);
            fprintf('Elapsed time: %s minutes.\n',(num2str(round(toc)/60)));
        catch initMsg
            fprintf(log,'\nERROR: %s \n %s\n',rawDirs{ii},initMsg.message);
            fprintf('\nERROR: %s \n %s\n',rawDirs{ii},initMsg.message);
        end
        
        
        % V. Write a file in the raw directory that will keep track of the
        %    subject's raw data being processed.
        if exist(fullfile(mrdDir,dwParams.dt6BaseName,'dt6.mat'),'file')
            fprintf(log,'success.\n');
            fprintf('\n %s processed successfully.\n',mrvDirup(mrdDir));
            sp = sp+1;
            subsProc{sp} = mrvDirup(mrdDir);
            dtiCmd = sprintf('echo %s > %s',getDateAndTime,(fullfile(mrdDir,'.dtiproc')));
            system(dtiCmd);
        else
            errFlag = true;
            err     = err+1;
            subsErr{err} = rawDirs{ii};
        end
        
        % HERE: REMOVE THE "WORKING FILE"
        delete(workFile);
        % HERE: END THE CHECK FOR THE "WORKING FILE"
    else
        fprintf('\nSkipping %s for now - "working" file found.\n',mrdDir);
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


%% Send email with the logfile

tend = toc(tstart); 
fprintf('\nElapsed time: %s minutes.\n',(num2str(round(tend)/60)));
fprintf(log, '\nElapsed time: %s minutes.\n',(num2str(round(tend)/60)));
% if notDefined('emailTo')
%     emailTo = 'lmperry@pitt.edu';
% end
% 
% totalTime = sprintf('Elapsed time: %s minutes.\n',(num2str(round(tend)/60)));
% etext = sprintf('DTI Processing completed: %s \nPlease see the attached logfile for more information.',totalTime);
% pitt_sendMail('pitt_processDiffusion has finished.',emailTo,[],etext,logFileName);


return




%% :::: FUNCTIONS ::::
% ::: getRawDirs ::: Return a cell array with the full paths to all
%                    subject's raw DTI directories.

function rawDirs = getRawDirs(baseDir,subs,clobber)

fprintf('Analyzing raw data directories...\n');

% CASE 1: What was passed is a cell array of raw directories.
%         If this is so then 'subs' will be empty
if iscell(baseDir) && isempty(subs)
    rawDirs = baseDir;
end


% CASE 2: Subs is passed in as a cell array of subject names and base dir
%         is not a cell array of raw directories
if ~isempty(subs) && iscell(subs) && ~iscell(baseDir)
        dirs = subs;
    
 
% CASE 3: Typical case - baseDir is not a cell array of raw directoires and
%         specific subject names are not passed in - we go and look for all
%         possible directories in baseDir, 
elseif ~iscell(baseDir) && isempty(subs)
    dirsTextFile = fullfile(baseDir,'.rawDirs.txt');
    cmd  = sprintf('ls -1 %s > %s', baseDir, dirsTextFile); system(cmd);
    dirs = textread(dirsTextFile,'%s'); 
    cmd  = sprintf('rm %s', dirsTextFile); system(cmd);
end

% FINISH: For cases 2 and 3: dirs will exist as a variable and we will
%         loop over all the directories and check to see if they meet the 
%         conditions for processing (1) no .dtiproc file, (2) have the
%         raw directory in mrDiffusion. * Note that some of the requirments
%         had to be met in pitt_processAnatomy
if exist('dirs','var')
    for i = sort(1:numel(dirs),'descend');
        if ~clobber
            if isdir(fullfile(baseDir,dirs{i},'mrDiffusion','raw')) ...
                    && ~exist(fullfile(baseDir,dirs{i},'mrDiffusion','.dtiproc'),'file') ...
                    && exist(fullfile(baseDir,dirs{i},'mrDiffusion','.anatproc'),'file') 
                dirs{i} = fullfile(baseDir,dirs{i},'mrDiffusion','raw');
            else
                fprintf('  - Skipping: %s\n',dirs{i});
                dirs(i) = [];
            end
        else
            if isdir(fullfile(baseDir,dirs{i},'mrDiffusion','raw'))
                dirs{i} = fullfile(baseDir,dirs{i},'mrDiffusion','raw');
            else
                fprintf('  - Skipping: %s\n',dirs{i});
                dirs(i) = [];
            end
        end
    end
    rawDirs = dirs;
end


return


%% %% $ todo 

%%% * DONE *MUST CHECK FOR THE EXISTENCE OF THE T1ACPC FILE - THIS IS GETTING BY
%%% THE OTHER FUNCITONS SOMEHOW. THAT'S WHY IT WOULD BE A GOOD IDEA TO MAKE
%%% ONE FILE THAT KEEPS TRACK OF WHERE THE SUBJECTS ARE IN THE PIPELINE SO
%%% WE KNOW WHERE TO GO NEXT AND WHATNOT.  -- See line 293, it may or may
%%% not be good enough. EITHER CHECK FOR ANAT PROC, OR CHECK FOR THE
%%% EXISTENCE OF THE T1ACPC FILE. 

%%% * DONE * write to the text file as the processing is ongoing. also keep track of
%%% the errors in the logfile - there are errors printed to the screen that
%%% are  not part of the error log file. HOW? That was fixed -- I think. 


%% NOTES:
%   COMMENT AND DEBUG - WORK ON BETTER SCREEN OUTPUTS FOR ALL THE SCRIPTS.
% 
%   Also need to think about data checks - how do we know that the data were
%   processed correctly. Fiber tractography?
% 
% 
%  CHECK FOR ANATPROC - WE NEED TO KNOW THAT IT'S BEEN PROCESSED! or that
%  it exists? where?
%   Think about ways to spawn the processes out to different matlab threads.
% 

