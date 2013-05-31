% dti_FINRA_createMoriFiberGroups.m

% This script will loop through a group of subjects and track fibers using the tools in 
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


logDir      = '/biac2b/data1/finra/DTI/';
baseDir     = '/biac2b/data1/finra/';
subs        = {'ap','as','ba','bh','bp','cc','ch','cl','cn','ko','lb','lg','ls','lu','me','mw','nh','nm','rc','sc','sw','sy','te','th','ww'};
dirs        = 'dti40';    

session2    = 1;

if session2 == 1
    baseDir     = '/biac2b/data1/finra/session2';
    subs 	= {'bg','jo','kc','mc','md','na'};
end


%% Run the functions

for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir   = fullfile(baseDir,sub.name);
        dt6Dir   = fullfile(subDir,'DTI',dirs);
        fiberDir = fullfile(dt6Dir,'fibers');
 
        fprintf('\nProcessing %s\n', subDir);
	
        % Find mori groups
        dt6File = fullfile(dt6Dir,'dt6.mat');
        outFile=fullfile(fileparts(dt6File), 'fibers', 'MoriGroups.mat');
        fg = dtiFindMoriTracts(dt6File,outFile);
       
         
        
    else 
        fprintf('% Does not exist, skipping...',subs{ii});
    end
end
