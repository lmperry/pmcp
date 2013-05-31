function pitt_clearWorkingFiles(baseDir,procStage)
% 
% function subs = pitt_getSubs(baseDir)
% 
% This funtion will return clear all the working files in each of the
% subjects directories so that processing can continue. A given stage can
% be specified so that other ongoing processes are not affected. 
% 

% Author: LMP 2012
% 
%#ok<*REMFF1>


%% Check INPUT

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select a Base Directory');
end

if ~exist('procStage','var') || ~isstr(procStage)
    procStage = false;
end


%% Return a cell array with the full paths to all subject directories 
 
dirsTextFile = fullfile(baseDir,'.dirs.txt');

cmd  = sprintf('ls -1 %s > %s', baseDir, dirsTextFile); system(cmd);
dirs = textread(dirsTextFile,'%s'); 
cmd  = sprintf('rm %s', dirsTextFile); system(cmd);

% Loop over the array and return only those that are directories
for i = sort(1:numel(dirs),'descend'); 
    if isdir(fullfile(baseDir,dirs{i})) && ~strcmp(dirs{i},'logs') && ~strcmp(dirs{i},'freesurfer')
        dirs{i} = fullfile(baseDir,dirs{i});
    else
        dirs(i) = [];
    end
end

% Return the total number of directories
n = numel(dirs);

for ii = 1:numel(dirs)
    mrddir = fullfile(dirs{ii},'mrDiffusion');
    
    if exist(mrddir,'dir')
        % Remove the working files
        if ~procStage
            delete(fullfile(mrddir,'.working*'));
        else
            switch lower(procStage)
                case 'anatproc'
                    if exist(fullfile(mrddir,'.workinganatproc'),'file');
                        delete(fullfile(mrddir,'.workinganatproc'));
                    end
                    
                case 'dtiproc'
                    if exist(fullfile(mrddir,'.workingdtiproc'),'file')
                        delete(fullfile(mrddir,'.workingdtiproc'));
                    end
                    
                case 'freeseg'
                    if exist(fullfile(mrddir,'.workingfreeseg'),'file')
                        delete(fullfile(mrddir,'.workingfreeseg'));
                    end
                    
                case {'wbfibertrack', 'wholebrainfibertrack'}
                    if exist(fullfile(mrddir,'.workingwbfibertrack'),'file')
                        delete(fullfile(mrddir,'.workingwbfibertrack'));
                    end
                    
                case {'morifibertrack', 'mori'}
                    if exist(fullfile(mrddir,'.workingmorifibertrack'),'file')
                        delete(fullfile(mrddir,'.workingmorifibertrack'));
                    end
            end
        end
        
    end
end
      disp(' Working files cleared.');

return

        

        
        
        
        
        
        
        
        