function [] = GetConcentrationMaps(workingDir,T1map_precontrastFile,T1map_postcontrast1File,T1map_postcontrast2File,brainmaskFile,relaxivityconstant)


% input:
% - workingDir, directory in which we are currently working
% - T1map_precontrastFile
% - T1map_postcontrast1File, first postcontrast scan
% - T1map_postcontrast2File, second postcontrast scan
% - relaxivityContrast, relaxivity value obtained from phantom scans


cd(workingDir)

%% Load T1maps
display('Loading input data...')

structT10map = MYnii(T1map_precontrastFile); 
T10map = structT10map.data;

structT1_1map = MYnii(T1map_postcontrast1File); 
T1_1map = structT1_1map.data;

structT1_2map = MYnii(T1map_postcontrast2File); 
T1_2map = structT1_2map.data;

brainmask = MYnii(brainmaskFile);
brainmask = logical(brainmask.data);

display(' Done!')

%% Correct T1map precontrast
% T1 values of the 0.7mm resolution scans are biased in comparison to 1.2mm
% scans --> To use the T1 values of the 0.7mm resolution scans, we should
% do a correction, otherwise they cannot be compared to the T1 values found
% in the 1.2mm resolution scan. T1new=0.85*T1_old+115 %ms
display('Perform T1,0 correction...')

T10map_corr= T10map;%0.85.*T10map+115.0.*ones(size(T10map)); %ms
%T10map_corr=T10map_corr.*brainmask;
MYsavenii(T10map_corr, workingDir, 'T1map_precontrast_corr.nii', T1map_precontrastFile);

display(' Done!')
%% Calculate contrast agent concentration
display('Calculating concentration maps...')
%[Gd] = (R1-R1,0)/r1;

diffR1_1=(ones(size(T1_1map))./T1_1map)-(ones(size(T10map_corr))./T10map_corr);
concentration_1=diffR1_1./relaxivityconstant;
concentration_1(~isfinite(concentration_1))=0;
concentration_1_microM=concentration_1.*1e6; %from M to uM
MYsavenii(concentration_1_microM, workingDir, 'concentration_uM_1.nii', T1map_postcontrast1File);

diffR1_2=(ones(size(T1_2map))./T1_2map)-(ones(size(T10map_corr))./T10map_corr);
concentration_2=diffR1_2./relaxivityconstant;
concentration_2(~isfinite(concentration_2))=0;
concentration_2_microM=concentration_2.*1e6; %from M to uM
MYsavenii(concentration_2_microM, workingDir, 'concentration_uM_2.nii', T1map_postcontrast1File);

display(' Done!')


end
