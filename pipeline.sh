#!bin/bash

SCRIPTDIR=~/HybridFlow/scripts
dicomDir=~/HybridFlow/dicomData
hematocrit=0.45
relaxivityconstant=4.2

workingDir=~/HybridFlow/processedData 

fastdceProtocolName=fl3d_vibe_fast_DT1.7s_16slices_2mmiso
T1map_precontrastFile=MP2RAGE_T1_precontrast_ref.nii
T1map_postcontrast1File=MP2RAGE_T1_postcontrast1.nii
T1map_postcontrast2File=MP2RAGE_T1_postcontrast2_ref.nii
brainmaskFile=brain_binmask_ref.nii

cd "$workingDir"


#########################################################################################################
# Convert MP2RAGE data into GBCA concentration  maps
#########################################################################################################
echo "Calculating GBCA concentration maps..."
matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('"$SCRIPTDIR"')); try GetConcentrationMaps('"$workingDir"','"$T1map_precontrastFile"','"$T1map_postcontrast1File"','"$T1map_postcontrast2File"','"$brainmaskFile"',"$relaxivityconstant"); catch ME; display(ME.message); exit; end; close all; clear all; exit" 
echo " Done!"

#########################################################################################################
# Create VIF mask and calculate Cp
#########################################################################################################

# Show instructions 
echo "Drawing of the VIF mask is desired:
 1) Start Edit mode: Settings -> Ortho View 1 -> Edit mode (or Alt+E)
 2) Create empty mask: Edit (Ortho View 1) -> Create mask (or Ctrl+N)
 3) Select the original image and use the select tool in combination with seed, 3D and adjacent voxels. Then,
    select a voxel in the middle of the SSS and shift the intensity threshold to select the voxels for the VIF (first mask)   
 4) Copy and paste this selection of voxels in the newly created mask, and save the mask as vif_mask.nii
 6) Close FSLeyes by clicking the X in the upper-right corner"
fsleyes MP2RAGE_UNI_postcontrast1_brain.nii
read -p " 7) Press Enter to continue"

# Get vascular input function (output is vif.mat and checkfit_vif.jpg and Cp_inputPatlak.mat)
echo "Calculating vascular input function (VIF)..."
matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('"$SCRIPTDIR"')); try getVIF('"$dicomDir"','"$workingDir"','concentration_uM_1.nii','concentration_uM_2.nii','fast_dce_mc_ref.nii','"$fastdceProtocolName"','MP2RAGE_T1_postcontrast1.nii','MP2RAGE_T1_postcontrast2.nii',"$hematocrit",'"$SCRIPTDIR"/VIF_LUT_fast_7T'); catch ME; display(ME.message); exit; end; close all; clear all; exit"
echo " Done!"

#########################################################################################################
# Patlak analysis
#########################################################################################################
# Calculate Ki- and Vp-maps
echo "Calculate Ki- and Vp-maps..."
matlab -nodesktop -nodisplay -nosplash -r "addpath(genpath('"$SCRIPTDIR"')); try Patlak_twotimepoints('"$workingDir"','concentration_uM_1.nii','concentration_uM_2.nii','"$brainmaskFile"'); catch ME; display(ME.message); exit; end; close all; clear all; exit"
echo " Done!"

#########################################################################################################
# Get leakage results
#########################################################################################################
echo -e '"Name"\t"RegionOfInterest"\t"RegionSize [voxels]"\t"NumberOfNaNs [voxels]"\t"Ki_Mean [min^-1]"\t"Ki_StDev [min^-1]"\t"Ki_Median [min^-1]"\t"Ki_IQR25 [min^-1]"\t"Ki_IQR75 [min^-1]"\t"Vp_Mean [-]"\t"Vp_StDev [-]"\t"Vp_Median [-]"\t"Vp_IQR25 [-]"\t"Vp_IQR75 [-]"' >> "$workingDir"/results.txt
echo "Saving unfiltered results (no histogram method applied) for region:"

for region in {frontal,temporal,parietal,occipital} # ADD ROI names here. Corresponding masks need to be named mask_${ROIname}.nii and co-registered to reference space.
do
  echo "- $region"

  # Region size (with NaNs)
  regionSize=$(fslstats "$workingDir"/mask_"$region".nii -V | cut -d" " -f1)
  
  # Count NaNs and remove these voxels from the region mask to exclude them from analysis
  fslmaths "$workingDir"/kimap.nii -uthr -1 -abs -bin "$workingDir"/nans.nii
  fslmaths "$workingDir"/nans.nii -add "$workingDir"/mask_"$region".nii -thr 2 -bin "$workingDir"/nans_"$region".nii
  NumberOfNaNs=$(fslstats "$workingDir"/nans_"$region".nii -V | cut -d" " -f1)
  fslmaths "$workingDir"/mask_"$region".nii -sub "$workingDir"/nans_"$region".nii "$workingDir"/mask_"$region".nii
  
  # Get Ki results
  kiData=( $(fslstats "$workingDir"/kimap.nii -k "$workingDir"/mask_"$region".nii -M -S -P 50 -P 25 -P 75) )
  
  # Get Vp results
  vpData=( $(fslstats "$workingDir"/vpmap.nii -k "$workingDir"/mask_"$region".nii -M -S -P 50 -P 25 -P 75) )
  
  # Save results into text file
  echo "$subject" "$region" "$regionSize" "$NumberOfNaNs" ${kiData[@]}  ${vpData[@]} >> "$workingDir"/results.txt
done

echo " --> '$workingDir'/results.txt"



exit
