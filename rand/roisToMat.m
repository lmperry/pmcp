% roisToMat.m

% This script will loop through a group of subjects and convert their nifti rois to mat

% HISTORY: LMP Wrote it.

% Notes:
% 

% startupFile = '/home/span/matlabfiles/startup.m';
% run(startupFile);
% cd('/biac2b/data1/finra');

%% I. Directory and Subject Informatmation



baseDir = '/biac2b/data1/finra/session2';
%% session2
% subs = {'lg061908','rc082208'};
subs  = {'bg031710','jo042210','kc031610','kk030910','mc032510','md032310','na032310'};


rois = {'lmpfc','lnacc','lthal','rmpfc','rnacc','rthal','vta'};


for ii=1:numel(subs)

    subDir = fullfile(baseDir,subs{ii});
    dtDir  = fullfile(baseDir,subs{ii},'DTI');
    roiDir  = fullfile(dtDir,'dti_rois');
    if exist(roiDir,'file')
        for rr = 1:numel(rois)
            niftiRoi = fullfile(roiDir,[rois{rr} '.nii.gz']);
            newRoi = dtiCreateRoisFromNifti(niftiRoi);
            newRoi.name = [rois{rr} '.mat'];
            dtiWriteRoi(newRoi, fullfile(roiDir,newRoi.name));
            fprintf('Saving %s in %s \n', newRoi.name, roiDir);
        end
    else fprintf('%s does not exist ... \n skipping %s\n',roiDir,subs{ii});
    end
end
