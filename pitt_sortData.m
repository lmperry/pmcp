function [sortedDirs anatDirs] = pitt_sortData(baseDir,anatFlag) 
%  
%    [sortedDirs anatDirs] = pitt_sortData([baseDir=uigetdir],[anatFlag=prompt])
% 
% This function will take a directory (baseDir) and sort all subject
% directories for use with the pitt_* Preprocess pipeline. It will return a
% list of directories that are ready to be fed into the next step in the
% pipeline -> pitt_processAnatomy.m -> pitt_preprocessDiffusion
% 
% The next step in the pipeline can be called straight from here by setting
% anatFlag = true, or by selecting "process now" when the dialog appears.
% This allows the user to either sort the directories only or actually run
% the anatomical processing directly from this script. 
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
%       anatFlag -  Setting this flag to true will send the resulting
%                   sorted direcories into the next function to be
%                   processed. False will simply sort the directories and
%                   the user will have to run the next script seperately. 
% 
% OUTPUTS:
%       sortedDirs - a cell array containing a list of all the directories
%                    that were sorted by this funciton, successfully. This
%                    is the subject's top level directory
% 
%       anatDirs   - a cell array containing all the directories that were
%                    are ready for anatomical processing.
% 
% EXAMPLE USAGE:
%       baseDir = '/Users/lmperry/pitt/data/DTI';
%     

% Supression:
%#ok<*REMFF1>
%#ok<*INUSD>

% NOTES:
% 
% **** Think about how to go about checking to make sure that we have
% diffusion data and a valid anatomical image. The anatomical image has to
% be sa*.hdr or ms*.hdr (i'm not exactly sure what the differecnes are but
% it seems like msa is bias-corrected). The cs*.hdr files don't work at all
% -they seem to be image masks or something else strange.

% * DONE * It might be worthwhile seperating these two funcitons (sort and
% anat) so that we don't have to do it all at the same time. I could
% imagine that we might want to be able to search for cases where no
% anatomy exists and allow the user to try to find a valid option... That's
% something to think about.

% * DONE * May want to allow for the option of choosing if the user wishes
% to choose the acpc landmarks now or later. This could be useful if I
% write another function that will take as an input those subjects who have
% not yet had their anatomical images acpc aligned.

% * DONE * Anat flag will allow the user to select if they want the anatomy
% files to be kept track of and sent to the anatomy function for anatomical
% processing.

% * DONE * The more I think about it the more I realize that the funcitons
% have to be seperated. The user may not want to run the processing of
% anatomical images at the same time, or they may be interrupted. They just
% need to be kept track of. It could be as simple as checking for the
% existence of the t1acpc.nii.gz file in the ant dir. That would allow for
% skipping the crazy checks for hidden files. But need to think on that
% more...

% Might want to consolidate the error logs. 


%% Check INPUTS and get a directory listing for the baseDir

if notDefined('baseDir');
    baseDir = uigetdir(pwd,'Select Base Directory');
    if baseDir == 0; error('User cancelled.'), end
end


% Get a listing of the fullpaths to each directory contained in baseDir.
subDirs = getDirs(baseDir);


%% Initialize error log files

logDir = fullfile(baseDir,'logs'); 
if ~exist(logDir,'dir'), mkdir(logDir); end

% We want to keep track of those subjects who do not have DTI data or
% ANATOMY data
logName  = fullfile(logDir,'sortData.txt');
log      = fopen(logName,'a');
fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);



%% Initialize counters

% Initialize a counter to keep track of the sortedDirs
sortedDirs = {};
sd = 0;

% Initialize counter for the anatomical files that need to be processed.
anatDirs = {};
ad = 0;

errFlag = false;


%% Do the actual sorting 
%#ok<*AGROW>

    fprintf('\n[pitt_sortData] ... \n\nFound %s possible directories.\nSorting directories ...\n\n',num2str(numel(subDirs)));

for ii=1:numel(subDirs)
        
    sortDir = subDirs{ii};
    
    % This will check to see if this directory has been sorted.- If it has
    % it will have the '.sorted' hidden-file in the directory and we'll
    % skip this subject. 
    if ~exist(fullfile(sortDir,'mrDiffusion','.sorted'),'file')
        
        cd(sortDir);
        
        % RAW DTI DATA CHECK AND SORT: Create the raw directory and move
        % the appropriate files in there. first Check to make sure raw dti
        % data exists. If not then write that directory to the error log.
        existRaw = checkForRawData(sortDir);
        
        if existRaw
            fprintf('Sorting %s ...',sortDir);
            fprintf(log,'Sorting %s ...\n',sortDir);
            mrdRawDir = fullfile(sortDir,'mrDiffusion','raw');
            if ~exist(mrdRawDir,'dir'), mkdir(mrdRawDir); end
            
            try
                copyfile(fullfile(sortDir,'dti_68_1024x1024*'), mrdRawDir);
            catch %#ok<CTCH>
                warning('Could not copy contentf from %s to %s',fullfile(sortDir,'dti_68_1024x1024*'),mrdRawDir); %#ok<WNTAG>
            end
            
        else
            fprintf('  - Skipping %s: No DTI data found.\n',sortDir);
            fprintf(log,'  -- Skipping %s: No DTI data found.\n',sortDir);
            errFlag = true;
        end
        
        % ANATOMICAL DATA CHECK AND SORT: Check to make sure that the
        % anatomy data exists. If it does then make the t1 folder from the
        % structural folder with the appropriate files in t1 that will be
        % used for creating the anatomical image. If not write that
        % directory to the error log.
        [existAnat name] = checkForAnat(sortDir);
       
        if existAnat
            mrdAnatDir = fullfile(sortDir,'mrDiffusion','t1');
            if ~exist(mrdAnatDir,'dir'), mkdir(mrdAnatDir); end
            
            copyfile(['Structural/' name '*.hdr'], mrdAnatDir);
            copyfile(['Structural/' name '*.img'], mrdAnatDir);
            
            % Add this directory to anatDirs for anatomical processing
            ad = ad + 1;
            anatDirs{ad} = mrdAnatDir; 
        else
            fprintf('  - Skipping %s: No Anatomy found.\n',sortDir);
            fprintf(log,'  -- Skipping %s: No Anatomy found.\n',sortDir);
            errFlag = true;
        end
        
        % AFTER IT'S ALL SAID AND DONE: If there is raw data, and
        % anatomical data we write a file in a directory that we have
        % already sorted. This file will be hidden and contain the date and
        % time of sort
        if existRaw && existAnat
            sortCmd = sprintf('echo %s > %s',getDateAndTime,fullfile(sortDir,'mrDiffusion','.sorted'));
            system(sortCmd);
            
            % Track the sorted Directories for return
            sd = sd+1;
            sortedDirs{sd} = sortDir;
            fprintf(' done.\n');
        end
    elseif exist(fullfile(sortDir,'mrDiffusion','.sorted'),'file')
        fprintf('  * Skipping %s: Already sorted.\n',sortDir);
        fprintf(log,'  * Skipping %s: Already sorted.\n',sortDir);
    end
end

if errFlag
    fprintf('\nOne or more subjects were skipped. Please check the log: \n\t%s',logName); 
end

fprintf('\nDone\n');


% ANATOMICAL PROCESSING: Send out those subs and subDirs for anatomical
% processing. Just need a list of anatDirs for each subject in a cell array
if notDefined('anatFlag') && ~isempty(sortedDirs)
    anatFlag = getAnatFlag;
else 
    anatFlag = false;
end

if anatFlag 
    fprintf('\nSending sortedDirs to pitt_processAnatomy...\n')
    pitt_processAnatomy(anatDirs); 
end



return



%% FUNCTIONS     

% ::: getDirs :::: Return a cell array with the full paths to all subject
% directories in baseDir.
function dirs = getDirs(baseDir) 
    dirsTextFile = fullfile(baseDir,'.dirs.txt');
    cmd = sprintf('ls -1 %s > %s', baseDir, dirsTextFile); 
    system(cmd);
    dirs = textread(dirsTextFile,'%s'); 
    cmd = sprintf('rm %s', dirsTextFile); 
    system(cmd); 

for i = sort(1:numel(dirs),'descend'); 
    if isdir(fullfile(baseDir,dirs{i})) && ~strcmp(dirs{i},'logs') && ~strcmp(dirs{i},'freesurfer')
        dirs{i} = fullfile(baseDir,dirs{i});
    else
        dirs(i) = [];
    end
end
return


% :::: checkForRawData :::: Check to see if the raw data directory actually
% exists within the sortDir
function existRaw = checkForRawData(sortDir)
    content = dir([sortDir,'/dti_68_1024x1024*']);
    if ~isempty(content)
        existRaw = true;
    else
        existRaw = false;
    end
return
    

% :::: checkForAnat :::: Check to see if there is anatomical data. If it
% does exist then send back the first characters, with preference given to
% the msa data - which is bias corrected. If it does not exist we're going
% to write to the error log that is's not there. 
function [existAnat name] = checkForAnat(sortDir)
name = '';
if exist(fullfile(sortDir,'Structural'),'dir')
    
    content = dir([sortDir,'/Structural/ms*.hdr']);
    
    if ~isempty(content) % NEED TO CHECK THAT THE FILES ARE NOT .MAT FILES - dealt with by adding the .hdr above.
        existAnat = true;
        name = 'ms';
    else
        content = dir([sortDir,'/Structural/s*.hdr']); % Had to change this because of the 'A' case.
        if ~isempty(content)
            existAnat = true;
            name = 's';
        else
            existAnat = false;
        end
    end
else
    existAnat = false;
end

return


% :::: getAnatFlag :::: Prompt user to process anatomical images now or
% later - which will send the anat dirs to pitt_processAnatomy.m
function anatFlag = getAnatFlag
    response = questdlg('Would you like to process (ACPC-landmark) anatomical images NOW? If you select "NO" you can run pitt_processAnatomy at a later time to process anatomy.','pitt_sortData');
    switch lower(response)
        case {'yes'}
            anatFlag = true;
        case {'no'}
            anatFlag = false;
        case {'cancel'}
            error('User cancelled');
    end
return










