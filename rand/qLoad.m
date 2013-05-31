%

files = textread('/biac2b/data1/finra/DTI/scripts/files.txt', '%s');

for ii=1:numel(files)
    pdb = files{ii};
    t1Dir = fullfile(mrvDirup(files{ii},3),'t1acpc.nii.gz');
    qmd{ii} = ['!Quench -d ' t1Dir ' -p ' pdb];    
end


% 
% % Convert files to pdb
% files = textread('/home/lmperry/Desktop/mtFiberFiles.txt', '%s');
% 
% for ii=1:numel(files)
%     fg = dtiReadFibers(files{ii});
%     [pth name] = fileparts(files{ii});
%     outName = [pth filesep name '.pdb'];
%     mtrExportFibers(fg, outName);
% end
% 

