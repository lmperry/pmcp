
%% INPUTS

fprintf('\n [%s] \n', mfilename);

if notDefined('baseDir')
    baseDir = uigetdir(pwd,'Select base directory');
end


%% Get subjects to process and advise the user RE time

subs = pitt_getSubs(baseDir,'freeseg');


nsubs = numel(subs);
half = floor(nsubs/2);

subs_a = subs(1:half);
subs_b = subs(half+1:end);

file_a = fopen(fullfile(baseDir,'.subs_a.txt'),'w');
file_b = fopen(fullfile(baseDir,'.subs_b.txt'),'w');

%% write the subjects to the subs files

for i = 1:numel(subs_a)
    fprintf(file_a,'%s\n',subs_a{i});
end

for i = 1:numel(subs_b)
    fprintf(file_b,'%s\n',subs_b{i});
end

% how can I get these to run at the same time? 
str = ['xterm -e' ' /Applications/MATLAB_R2010bSP1.app/bin/matlab -r pitt_segmentAnatomy_a.m']; 
system(str)

run('pitt_segmentAnatomy_b'); 


% add a working hidden file that will keep track of those subjects whose
% data is currently being analyzed - check for this file before each
% iteration in the loop and delete it once it's done - or after the catch
% if it fails! 