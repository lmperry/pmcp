function anatProc = pitt_processAnatomy(baseDir,processDiffusion,force)

%  anatProc = pitt_processAnatomy(baseDir,processDiffusion,force)
% 
% Process subjects' raw anatomical t1-weighted data through the mrVista
% pipeline. The user can provide a list of subjects as a cell array, or, by
% default this function will recursively search through any directory in
% baseDir and look for the existence of a hidden file (.anatproc) that will
% have be created by this function when it is run successfully. An optinal
% input argument will foce the processing of a subject regardless of the
% existence of the anatproc hidden file. This is useful for those cases
% where a subject's alignment needs to be fixed. 
% 
% This funciton will: 
%     (1) Convert the hdr/img pair to nifti file format
%     (2) Set anatomical landmarks (ac-pc) using mrAnatAverageAcpcNifti
%     (3) Save the resulting image in the 't1' directory as 't1acpc.nii.gz'
% 
% 
% DIRECTORY ORGANIZATION:
%       As of right now the directory structure is: 
%           DTI -> A229 -> mrDiffusion -> dti60trilin -> dt6.mat [...]
%                                      -> raw -> dti68_1024x1024
%                                      -> t1  -> t1acpc.nii.gz
% INPUT:
%       baseDir  -  The directory which contains the subjects' data
%                   directories. 
% 
%       force    -  Boolean flag - setting this flag to true will cause the
%                   reprocessing of any antomical data that had been
%                   previously processed regardless of the existence of a
%                   sorted hidden file.
% 
% OUTPUTS:
%       anatproc   - a cell array containing a list of all the directories
%                    that were processed by this funciton, successfully. 
% 
% EXAMPLE USAGE:
%       baseDir = '/Users/lmperry/pitt/data/DTI';
%       force   = false; 
%       anatProc = pitt_processAnatomy(baseDir,force); 

% Supression
%#ok<*AGROW>
%#ok<*WNTAG>
%#ok<*REMFF1> 

% NOTES: 
% 
% **** Think about how to go about checking to make sure that we have
% diffusion data and a valid anatomical image. The anatomical image has to
% be sa*.hdr or ms*.hdr (i'm not exactly sure what the differecnes are but
% it seems like msa is bias-corrected). The cs*.hdr files don't work at all
% -they seem to be image masks or something else strange.
% DONE:
%     Might want to do error logging here too. *DONE*
% 
%     It might be worthwhile seperating these two funcitons (sort and anat) so
%     that we don't have to do it all at the same time. I could imagine that we
%     might want to be able to search for cases where no anatomy exists and
%     allow the user to try to find a valid option... That's something to think
%     about. 
% TO DO:
%       Add a force option to this function and the procDiffusion function.
%       * DONE *
% 
%       Might want to add the ability to reprocess only certain subjects ->
%       like processDiffusion
% 
%       Update the screen outputs so they're more informative. * DONE *
% 
%       How about a next subject dialog - or quit for now. * DONE **


%% Check Inputs

if notDefined('baseDir');
    baseDir = uigetdir(pwd,'Select Base Directory');
    if baseDir == 0; error('User cancelled.'), end
end

if notDefined('force')
    force = false;
end

if notDefined('processDiffusion')
    getFlag = true;
    processDiffusion = false;
else
    getFlag = false;
end

anatDirs = getAnatDirs(baseDir,force);


%% Initialize error log files

% We want to keep track of those subjects that do not have DTI data or
% ANATOMY data
if ~isempty(anatDirs)
logDir = fullfile(mrvDirup(anatDirs{1},3),'logs');
if ~exist(logDir,'dir'), mkdir(logDir); end
else
    logDir = fullfile(baseDir,'logs');
end

log  = fopen(fullfile(logDir,'processAnatomy.txt'),'a');
fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);


%% Initialize counters

anatProc = {};
ap = 0;

err      = 0; 
errFlag  = false;


%%  ANATOMICAL PROCESSING


% IF all subjects are already processed display that to the output window
fprintf('\n[pitt_processAnatomy] ... \n\n%s subjects will be processed...\n',num2str(numel(anatDirs)));
fprintf(log,'\n[pitt_processAnatomy] ... \n%s subjects will be processed...\n',num2str(numel(anatDirs)));

if isempty(anatDirs), 
    fprintf('All subjects already processed.');
    fprintf(log,'\nAll subjects already processed.\n'); 
end

for ii = 1:numel(anatDirs)
    
    % Here we should define the mrdDir
    mrdDir = mrvDirup(anatDirs{ii});
    
    % HERE we should check for and write the "working" file
    % HERE: CHECK FOR AND WRITE THE "WORKING" FILE, which will allow us to
    % keep track of which subjects are currently being worked on by another
    % process.
    % Path to the work file
    workFile = fullfile(mrdDir,'.workinganatproc');
    
    if ~exist(workFile,'file')
        
        fprintf('\nProcessing %s\n', fileparts(fileparts(anatDirs{ii})));

        % Write the working file
        workCmd = sprintf('echo %s > %s',getDateAndTime,workFile);
        system(workCmd);
        
        anatFile = dir([anatDirs{ii} '/*.hdr']);
        anatFile = fullfile(anatDirs{ii},anatFile.name);
        
        if exist(anatFile,'file') && ~isdir(anatFile) % Hack because of the empty cell above!
            
            [~, f ~]    = fileparts(anatFile);
            anatOutFile = fullfile(anatDirs{ii},[f '.nii.gz']);
            t1AcpcFile  = fullfile(anatDirs{ii},'t1acpc.nii.gz');
            
            % Convert structural image to NIFTI
            if ~exist(t1AcpcFile,'file')
                cmd = ['fslchfiletype NIFTI_GZ ' anatFile ' ' anatOutFile];
                [status result] = system(cmd);
                if status == 0
                    % Do the acpc alignment - prompt the user to make sure it's good.
                    an = 0;
                    while an ~= 1 || isempty(an)
                        mrAnatAverageAcpcNifti(anatOutFile,t1AcpcFile);
                        an = questdlg('Does the alignment look good?','ACPC ALIGNMENT','YES','NO','YES');
                        if strcmp('YES',an), an = 1;
                            try
                                close 1 2 3;
                            catch cmsg %#ok<NASGU>
                                warning('WINDOWS CANNOT BE CLOSED... PLEASE CLOSE ALL WINDOWS MANUALLY')
                            end
                        else an = 0;
                        end
                    end
                else
                    fprintf(log,'%s \n\t %s\n',anatDirs{ii},result);
                end
            end
             
            % HERE: REMOVE THE "WORKING FILE"
            delete(workFile);
            
            % AFTER IT'S ALL SAID AND DONE
            % Check that the anat file has been written to disk.
            if exist(t1AcpcFile,'file')
                anatCmd = sprintf('echo %s > %s',getDateAndTime,fullfile(mrdDir,'.anatproc'));
                system(anatCmd);
               
                
                % Track the processed directories for return
                ap = ap+1;
                anatProc{ap} = anatDirs{ii};
                
                % Prompt the user to continue
                if ii<numel(anatDirs) && ii~=1
                    prompt = sprintf('Subject %d of %d: \n Would you like to continue with the next subject?',ii+1,numel(anatDirs));
                    answ = questdlg(prompt,'ACPC ALIGNMENT','YES','NO','YES');
                    if strcmp('YES',answ), answ = 1; else answ = 0; end
                    if answ ~=1
                        warning('User Cancelled: pitt_processAnatomy');
                        return
                    end
                end
            else
                
                fprintf('Error: %s was not created.\n',t1AcpcFile);
                errFlag = true;
                fprintf(log,'Error in: %s\n %s was not found.',anatDirs{ii},t1AcpcFile);
                err = err + 1;
                subsErr{err} = anatDirs{ii};
            end
        else
            fprintf('Error in: %s\n',anatFile);
            errFlag = true;
            fprintf(log,'Error in: %s\n',anatFile);
        end
        
        % HERE: END THE CHECK FOR THE "WORKING FILE"
    else
        fprintf('\nSkipping %s - "working" file found.\n',anatDirs{ii});
    end
end



%% Show some outputs to the command window that will show which subjects
%  have been processed correctly and which had errors.
%  If the anat files are missing, or if there was a problem with the
%  nifti conversion then throw the error flag.

if errFlag
    fprintf('\nError(s) occurred. Please check the logFile: \n');
    fprintf('\nThe following subjects returned errors:\n');    
    fprintf(log,'\nThe following subjects returned errors:\n');

    for e = 1:numel(subsErr)
        fprintf('%s\n',subsErr{e});
        fprintf(log,'%s\n',subsErr{e});
    end
else
    fprintf('\nNo errors occurred during execution.\n');
    fprintf(log,'\nNo errors occurred during execution.\n');
end

if~isempty(anatDirs)
    fprintf('\nThe following subjects were processed successfully:\n');
    fprintf(log,'\nThe following subjects were processed successfully:\n');
    for s = 1:numel(anatDirs)
        fprintf('%s\n',anatDirs{s});
        fprintf(log,'%s\n',anatDirs{s});
    end
end



%% Send the anatDirs out to pitt_preprocessDiffusion

% Determine if we should pass the output to the diffusion function
if getFlag == 1 && ~isempty(anatDirs)
    processDiffusion = getDiffusionFlag;
end

%  Initialize diffusion processing.
if processDiffusion == 1 && ~isempty(anatDirs)
    % ??? Will this work with dti proc? It may have to be numbers - not full paths.
    % Get to the raw level of the subject's directory
    for dd = 1:numel(anatProc)
        anatProc{dd} = fullfile(mrvDirup(anatProc{dd}),'raw');  
    end
    fprintf('\nSending subjects to pitt_preprocessDiffusion to process diffusion data...\n');
    pitt_preprocessDiffusion(anatProc);
end


return









%% :::: FUNCTIONS ::::


% ::: getAnatDirs ::: Return a cell array with the full paths to all
% subject's anatomy directories.
function anatDirs = getAnatDirs(baseDir,force)   

if ~iscell(baseDir)
    dirsTextFile = fullfile(baseDir,'.anatDirs.txt');
    cmd = sprintf('ls -1 %s > %s', baseDir, dirsTextFile); system(cmd);
    dirs = textread(dirsTextFile,'%s');   
    cmd = sprintf('rm %s', dirsTextFile); system(cmd);
    
    for i = sort(1:numel(dirs),'descend');
        if ~force && isdir(fullfile(baseDir,dirs{i},'mrDiffusion','t1')) ...
                  && ~exist(fullfile(baseDir,dirs{i},'mrDiffusion','.anatproc'),'file') ...
                  &&  exist(fullfile(baseDir,dirs{i},'mrDiffusion','.sorted'),'file')

            dirs{i} = fullfile(baseDir,dirs{i},'mrDiffusion','t1');
            
        elseif force && isdir(fullfile(baseDir,dirs{i},'mrDiffusion','t1'))
            dirs{i} = fullfile(baseDir,dirs{i},'mrDiffusion','t1');
            
        else
            dirs(i) = [];
        end
    end
    anatDirs = dirs;
else
    % What was passed in must be a cell array of anatomy directories.
    % but we should check for the existence of anatproc!!! && sorted!!!
    dirs = baseDir;
    for i = sort(1:numel(dirs),'descend');
        if ~force && isdir(fullfile(dirs{i})) ...
                && ~exist(fullfile(mrvDirup(dirs{i}),'.anatproc'),'file') ...
                &&  exist(fullfile(mrvDirup(dirs{i}),'.sorted'),'file')
            dirs{i} = fullfile(dirs{i});
        elseif force && isdir(dirs{i})
            dirs{i} = fullfile(dirs{i});
        else
            dirs(i) = [];
        end
    end
    anatDirs = dirs;
end

return


% :::: getAnatFlag :::: Prompt user to process anatomical images now or
% later - which will send the anat dirs to pitt_processAnatomy.m
function processDiffusion = getDiffusionFlag
    response = questdlg('Would you like to process diffusion data NOW? If you select "NO" you can run pitt_preprocessDiffusion at a later time.','pitt_processAnatomy');
    switch lower(response)
        case {'yes'}
            processDiffusion = true;
        case {'no'}
            processDiffusion = false;
        case {'cancel'}
            error('User cancelled');
    end
return