function pitt_freesurfer(baseDir)
% 
% Run freesurfer automatic segmentation on all subjects in 'baseDir'
% 
% 
% INPUTS:
%       baseDir - directory contatining all subjects that have data to be
%                 processed. 
% 
% OUTPUTS:
%       While this function does not return anything it does save out the
%       results of the segmentations to the baseDir withing a directory
%       called 'freesurfer'. Within that directory can be found all the
%       output files form the initial freesurfer run. 

% NOTES:
%   Things this funciton should do:
%       1. Get a list of all the subjects that should be / are ready to be
%          segmented. 
%       2. Set the export directory to be within the 'baseDir' in a
%          'freesurfer' directory. 
%       3. Add this function to the GUI
%       4. Create the ROIs from the segmentation mask individually
%       5. Save the ROIs to a directory within freesurfer and link here
%          from the dti directory - it might be worthwhile to have these
%          ROIs placed in the dti directory, since it's from there we would
%          want to use them. 
%       6. see dtiRoiFromNifti for the method to save those niftis as mat
%          files for use with contrack.