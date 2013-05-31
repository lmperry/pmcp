baseDir = ('/Users/lmperry/pitt/data/DTI_3');
subs = textread(fullfile(baseDir,'.subs_a.txt'),'%s')

return
%% INPUTS

fprintf('\n [%s] \n', mfilename);

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select base directory');
end


%% Get subjects to process and advise the user RE time

warn = sprintf('This process will run FREESURFER recon-all on %d subjects.\n    This will take ~%d hours!\n    Do you want to continue?',numel(subs),numel(subs)*10);
resp = questdlg(warn,'pitt_segmentAnatomy','YES','NO','YES');
if strcmp(resp,'NO')
    disp('User cancelled.')
    return
end

%% Set subjects_dir env variable

sd = fullfile(baseDir,'freesurfer');
if ~exist(sd,'dir'), mkdir(sd); end

setenv('SUBJECTS_DIR',sd);


%% Initialize and format the log file

if ~isempty(subs)
    logDir = fullfile(baseDir,'logs');
    if ~exist(logDir,'dir'), mkdir(logDir); end
    
    logFileName = fullfile(logDir,'segmentAnatomy.txt');
    log         = fopen(logFileName,'a');
    
    fprintf(log,'\n\n\n\n\n\n-----%s------\n\n',getDateAndTime);
    fprintf(log,'Running freesurfer for: %d subjects \n---\n',numel(subs));
    fprintf('Running freesurfer for %d subjects...\n---\n',numel(subs));
else
    fprintf('  No subjects found that can be segmented at this time.\n');
    return
end

sp       = 0;
subsProc = {};
err      = 0; 
errFlag  = false;


%% Loop over subs and segment anatomicals using freesurfer

for ii=1:numel(subs)
    
    % Set up the path to files needed to run the recon 
    mrdDir = fullfile(subs{ii},'mrDiffusion');
    t1     = fullfile(mrdDir,'t1','t1acpc.nii.gz'); 
    [~, subID ~] = fileparts(subs{ii}); 
    
    % Path to the segfile
    segFile = fullfile(sd,subID,'mri','aparc+aseg.mgz'); 
    
    % In case this subject has been started previously, remove the
    % directory and start anew. 
    if exist(fullfile(sd,subID),'dir') && ~exist(segFile,'file')
        rmdir(fullfile(sd,subID),'s');
    end
    
    fprintf(log,'\nRunning subject %s...',subID); fprintf('\nRunning subject %s...\n',subID); 
    tic;
    
    % RUN THE RECON-ALL: Build the recon command and run it 
    % ** This is what takes all the time **
    cmd    = sprintf('recon-all -i %s -subjid ''%s'' -all', t1, subID);
    [status, ~] = system(cmd,'-echo');
    endtime = num2str(toc/60);
 
    
    % Check to see if it ran correctly and if it did write the hidden file
    % that will signal that subject has been processed
    if status == 0 && exist(segFile,'file')
        fprintf(log,'success!\n');
        fprintf('\n %s processed successfully.\n',mrvDirup(mrdDir));
        sp = sp+1;
        subsProc{sp} = mrvDirup(mrdDir);  
        tmgCmd = sprintf('echo %s > %s',getDateAndTime,(fullfile(mrdDir,'.freeseg')));
        system(tmgCmd);
        
        % CREATE ROIS: Here we will create the ROIs for each subject.
        fprintf(' Creating freesurfer ROIs from the segmentation file: %s\n', segFile); 
        fprintf(log,'  Creating freesurfer ROIs from the segmentation file: %s\n', segFile);
        
        % First line will create the rois in .mat format for tracking with
        % conTrack- the next line will then create the ROIs in nifti format
        % for visualization in other viewers 
        fs_roisFromAllLabels(segFile,fullfile(mrdDir,'ROIs','freesurfer'),'mat',fullfile(mrdDir,'t1','t1acpc.nii.gz'));
        fs_roisFromAllLabels([segFile(1:end-4) '.nii.gz'],fullfile(mrdDir,'ROIs','freesurfer'),'nifti',fullfile(mrdDir,'t1','t1acpc.nii.gz'));
        
        fprintf('  fs_roisFromAllLabels: Success. \n  Time elapsed:  %s minutes.\n', endtime); 
        fprintf(log,'  fs_roisFromAllLabels: Success. \n  Time elapsed:  %s minutes.\n', endtime);
    else
        fprintf(log,'failed.\n');
        errFlag = true;
        err     = err+1;
        subsErr{err} = subs{ii};  
    end
end


%% Show some outputs in the command window that will show which subjects 
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


fprintf(log,'\n---END---\n');

return
















