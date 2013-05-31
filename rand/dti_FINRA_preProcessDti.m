% dti_FINRA_PreProcessDti.m

% This script will loop through a group of subjects and process their diffusion data using the tools in 
% mrVista.

% HISTORY: LMP Wrote it.

% Notes:
% 

% startupFile = '/home/span/matlabfiles/startup.m';
% run(startupFile);
% cd('/biac2b/data1/finra');

%% I. Directory and Subject Informatmation

startupFile = '/home/span/matlabfiles/startup.m';
run(startupFile);
cd('/biac2b/data1/finra');

baseDir = '/biac2b/data1/finra/';
subs = {'as042308','ba081408','bp071608','cl121207','ch081108','me061008','mw060408'...
        'ap051708','bh070808','cc062608','cn082308','jj072108','ko081808',...
        'lb052808','lg061908','ls041808','lu051808','nh081508','nm060208',...
        'pn080608','rc082208','sc071008','sw080108','sy061108','te060308',...
        'th080808','ww062408','rm080908'};



logFile  = fullfile(baseDir,'DTI',['PreprocessingLog_' date '.txt']);


%% II. Loop through subs and Preprocess
fid = fopen(logFile,'w');
fprintf(fid,'Processing DTI data for: %d subjects. \n-----------------\n',numel(subs));
startTime = clock;
c = 0;

for ii=1:numel(subs)
    
    subDir = fullfile(baseDir,subs{ii});
    dtDir  = dir(fullfile(baseDir,subs{ii},'18*'));
    dtDir  = dtDir.name;
    dtDir  = fullfile(subDir,dtDir);
    rawDir = fullfile(dtDir,'raw');
    raw6   = fullfile(rawDir,'006');
    raw7   = fullfile(rawDir,'007');
    
    fprintf('Processing %s...\n',subs{ii}); fprintf(fid,'Processing %s...\n',subs{ii});
    fprintf('Data Directory = %s\n',dtDir); fprintf(fid,'Data Directory = %s\n',dtDir);
     
    if ~exist(rawDir,'file'), mkdir(rawDir), fprintf('Created \t%s \n', rawDir); end
    if ~exist(fullfile(rawDir,'007'),'file'), cd(dtDir), system('mv 00* raw'); end
      
    ni006 = fullfile(rawDir,'dti_g87_b900_006.nii.gz');
    ni007 = fullfile(rawDir,'dti_g87_b900_007.nii.gz');
    ni013 = fullfile(rawDir,'dti_g87_b900.nii.gz');
    try
        % If the raw dti nifti files don't exist we create them using dinifti
        r6=0; r7=0;
        if ~exist(ni013,'file')
            cd(rawDir);
            disp('Creating raw nifti files. Be patient...');
            
            if exist(raw6,'file')
                [status,result] = unix('dinifti -g -s 60 006 dti_g87_b900_006','-echo');
                if status ~= 0, disp(result); end
                r6=1;
                fprintf(fid,'Successfully created %s\n', ni006);
            end
            if exist(raw7,'file')
                [status,result] = unix('dinifti -g -s 60 007 dti_g87_b900_007','-echo');
                if status ~= 0, disp(result); end
                r7=1;
                fprintf(fid,'Successfully created %s\n', ni007);
            end
            
        else
            disp('Nifti files already created with dinifti.');
        end
        
        if ~exist(ni013,'file') && exist(ni007,'file') && exist(ni006,'file')
            disp('Combining raw nifti files...'); fprintf(fid,'Combining Raw NiftiFiles\n');
            cd(rawDir);
            ni1 = readFileNifti('dti_g87_b900_006.nii.gz');
            ni2 = readFileNifti('dti_g87_b900_007.nii.gz');
            ni1.data = cat(4, ni1.data, ni2.data);
            ni1.fname = 'dti_g87_b900.nii.gz';
            writeFileNifti(ni1);
            
            if exist(ni013,'file'), fprintf('Successfully created %s', ni1.fname); fprintf(fid,'Successfully created %s', ni1.fname); end
            
            clear ni1 ni2
        end
        
        if r7==1 && r6==0, cd(rawDir); system('mv dti_g87_b900_007.nii.gz dti_g87_b900.nii.gz'); end
        if r7==0 && r6==1, cd(rawDir); system('mv dti_g87_b900_006.nii.gz dti_g87_b900.nii.gz'); end
        
        % Run the preprocessing
        if exist(fullfile(dtDir,'t1acpc.nii.gz'),'file') && ~exist(fullfile(dtDir,'dti40'),'file') && exist(ni013,'file')
            cd(dtDir);
            disp('Running dtiRawPreprocess. This will take some time ...');
            dtiRawPreprocess('raw/dti_g87_b900.nii.gz','t1acpc.nii.gz',.9,87,'false',[],[],[],[],[],true);
            fprintf('% processed successfully.\n\n',subs{ii});
            fprintf(fid,'DtiRawPreprocess ran successfully for %s.\n\n',subs{ii});
        else
            if ~exist(fullfile(dtDir,'t1acpc.nii.gz'),'file'),
                fprintf('Required files not found for subject %s in %s\n\n',subs{ii},dtDir);
                fprintf(fid,'Required files not found for subject %s in %s\n\n',subs{ii},dtDir);
            end
            if exist(fullfile(dtDir,'dti40','dt6.mat'),'file'),
                fprintf('Processing is already complete for %s\n\n',subs{ii});
                fprintf(fid,'Processing is already complete for %s\n\n',subs{ii});
            end
        end
        
    catch ME 
        c = c+1;
        elog{c} = subDir;
        fprintf(fid,'\nSomething went wrong with %s. \n Returned the following error: \n %s\n\n', subs{ii}, ME.message);
        fprintf('\n!!! Something went wrong with %s.\nCheck the log file for more information.\n Moving on...\n\n', subs{ii});
    end
end

%% III. Close things out
totalTime = etime(clock,startTime);
fprintf('*************\n  DONE!\n');
fprintf('\n Script Completed in a total time of %f minutes.\n\n',totalTime/60);

if ~notDefined('elog')
    fprintf('**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n')
    fprintf(fid,'**********************\nTHE FOLLOWING SUBJECTS RETURNED ERRORS:\n**********************\n')
    for ee = 1:numel(elog)
        fprintf('%s\n',elog{ee});
        fprintf(fid,'%s\n',elog{ee});
    end
end
    
fclose(fid);












%% Notes:


% Output text file with info regarding processing.

% ni = readFileNifti('raw_dinifti/dti_g87_b900.nii.gz')
% ni = niftiSetQto(ni,ni.sto_xyz);
% writeFileNifti(ni);
% # Now run dtiRawPreprocess...

% Subject BP has one large folder with both scans in the same directory.
% Run dinifti to assure that one nifti will be created from both scans.
% Also check to see which if any directories don't exist - ie only one
% scan. 
% 
%  % Process Raw T1
%     if ~exist(fullfile(dtDir,'t1.nii.gz'),'file') && ~exist(fullfile(dtDir,'t1acpc.nii.gz'),'file') && ~exist(fullfile(rawDir,'t1'),'file')
%         cd(dtDir)
%         disp('Creating the t1 nifti file');
%         niftiFromDicom('raw/005','raw/t1');
%     end
%     
%     % Output instruction for running mrAnatAverageAcpcNifti - it might be
%     % best at this point to prompt the user to create the acpc aligned t1 file, or choose it if it exists somewhere else..
