pittdti
=======
(C) Michael Perry, Stanford University [2012-2014]

####pitt_initData<br>
>This will organize all the data into the format we prefer

####pitt_initAnatomicals
>This will convert the anatomical images to nifti format and run mrAnatAverageAcpcNifti
Could also run freesurfer segmentation at this point. Those ROIS will need to be converted to nifti or mat for use with various tools. The ROI toolbox will be important for this. 

####pitt_segmentAnatomicals
>This will segment the anatomical files using freesurfer and convert the ROIs to individual nifti files (this is what dtiRoiFromNifti was written for)

####pitt_preprocessDiffusion
>This will convert the raw scanner data to nifti and process the data using MRD. 

####pitt_fiberTracker
>This will allow any two rois to be used to track fibers.   either using contrack or stt 
ADD this as an option on the pittdti gui - 
the idea being that the user could choose do do this kind of fiber tracking from the gui and close the gui (or leave it open)

####pitt_fiberTrackMoriGroups 	
>This will track the mori groups for each subject 

####pitt_getStats
>Get and display stats for a given fiber group(s). 
