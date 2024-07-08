function [ mynii ] = MYnii( vol, varargin )
%MYNII Usage: MYnii(inputvolume). Replaces nifti function, output .mat .dir .dims .voxelsize .data
%   MYnii opens .gz files if needed. Accepted input is .nii, .hdr, .dcm (no
%   mat available) and .PAR or .REC (no mat available). If anything is
%   given after the vol, a par file is read without applying scaling
%   factors. 

if exist(vol, 'file') == 0
    error(['File ' vol ' does not exist!'])
end


[~, ~, ext] = fileparts(vol);
if strcmp(ext, '.gz')
    tmpname = num2str(rand(1), '%bx');
    newvol = fullfile('/tmp', [tmpname '.nii']);
    MYunix(['gunzip -c ' vol ' > ' newvol]);
    [~, ~, ext] = fileparts(newvol);
    vol = newvol;
end
    
if strcmp(ext, '.nii')
    N = nifti(vol);
    
    if length(size(N.dat)) == 2
        mynii.data = N.dat(:,:);
    elseif length(size(N.dat)) == 3
        mynii.data = N.dat(:,:,:);
    elseif length(size(N.dat)) == 4
        mynii.data = N.dat(:,:,:,:);
    end
    mynii.mat = N.mat;
    mynii.dir = vol;
    mynii.dims = N.dat.dim;
    mynii.voxelsize = [abs(mynii.mat(1,1)) abs(mynii.mat(2,2)) abs(mynii.mat(3,3))];
elseif strcmp(ext, '.hdr')
    mynii.data = spm_read_vols(spm_vol(vol));
    info = spm_vol(vol);   
    mynii.mat = info.mat;
    mynii.dir = vol;
    mynii.dims = size(mynii.data);
    mynii.voxelsize = [abs(info.mat(1,1)) abs(info.mat(2,2)) abs(info.mat(3,3))];
elseif strcmp(ext, '.dcm')
    mynii.data = double(dicomread(vol));
    info = dicominfo(vol);
    mynii.mat = zeros(4);
    mynii.dir = vol;
    mynii.dims = size(mynii.data);
    if sum(strcmp('PixelSpacing', fieldnames(info))) > 0
    mynii.voxelsize = [abs(info.PixelSpacing(1)) abs(info.PixelSpacing(2)) abs(info.SliceThickness)];
    else
        mynii.voxelsize = [0 0 0];
        display('Warning: dicom voxelsize not found.')
    end
elseif strcmp(ext, '.PAR') || strcmp(ext, '.REC')
    parfilename = [vol(1:end-3) 'PAR'];
    recfilename = [vol(1:end-3) 'REC'];
    parrec = loadPARREC(parfilename, recfilename);
    mynii.dims = size(cell2mat(parrec.scans(1,1,1)));
    concsize = size(cell2mat(parrec.scans(:,1,1)));
    mynii.dims(4) = concsize(1)/mynii.dims(1);
    for I = 1:mynii.dims(4)
        mynii.data(:,:,:,I) = double(cell2mat(parrec.scans(I,1,1)));
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PAR lr seems to be flipped... Always check if used with nii!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mynii.data = flipdim(mynii.data,2);
    mynii.mat = zeros(4);
    mynii.dir = vol;
    if mynii.dims(4) == 1
        mynii.dims = mynii.dims(1:3);
    end
    
    %import and use pixelvals > floating point vals
    
    mynii.parinfo = MYreadpar(parfilename);
    
    if ~isempty(varargin)
        mynii.data = (mynii.data * mynii.parinfo.SliceInformation(1).RescaleSlope + mynii.parinfo.SliceInformation(1).RescaleIntercept) / (mynii.parinfo.SliceInformation(1).RescaleSlope * mynii.parinfo.SliceInformation(1).ScaleSlope);
    end
        
    
    
else
    error([ext ' format not supported'])
end


if exist('newvol', 'var')
    delete(newvol)
end




end
