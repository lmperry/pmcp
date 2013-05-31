function subsProc = pitt_processAll(baseDir,forceFlag)
% 
% Run the pitt dwi pipeline. If forceFlag = true all data will
% be clobbered and run again. 
% 
% INPUTS:
%       baseDir     - the directory containing the subject folders.
%       forceFlag   - clobber data and run again.
% 

% Segmentations are not being called through here. 


%% Check INPUTS and get a directory listing for the baseDir

if notDefined('baseDir');
    baseDir = uigetdir(pwd,'Select Base Directory');
    if baseDir == 0; error('User cancelled.'), end
end

if notDefined('forceFlag')
    forceFlag = false;
end


%% Run the processing functions

pitt_sortData(baseDir,false);

pitt_processAnatomy(baseDir,false,forceFlag);

pitt_preprocessDiffusion(baseDir,[],forceFlag,[]);

pitt_trackWholeBrainFibers(baseDir);

subsProc = pitt_trackMoriFibers(baseDir);

return