function [  ] = MYsavenii( data, outputdir, name, varargin )
%   Usage: MYsavenii( data, outputdir, name, [refnii] (full path, optional) )
%   Saves your matrix in the outputdir with the specified name. Use a nifti
%   in the same space to get correct rotations and spatial parameters. The
%   varargin can also be a voxel size in the form [2 2 2].

deleterefnii = 0;
if ~strcmp('.', name(end-3))
    name = [name '.nii'];
end


if isempty(varargin)
    refnii = fullfile(outputdir, 'testnii.nii');
    voxelsize = [1 1 1];
    MYunix(['fslcreatehd ' num2str([size(data,1) size(data,2) size(data,3)]) ' 1 ' num2str(voxelsize) ' 1 0 0 0 32 ' refnii]);
    deleterefnii = 1;
elseif iscell(varargin)
    if isfloat(varargin{1}) && numel(varargin{1})==3
        voxelsize = varargin{1};
        refnii = fullfile(outputdir, 'testnii.nii');
        MYunix(['fslcreatehd ' num2str([size(data,1) size(data,2) size(data,3)]) ' 1 ' num2str(voxelsize) ' 1 0 0 0 32 ' refnii]);
        deleterefnii = 1;
    elseif ~exist(cell2mat(varargin), 'file')
        error('Reference nifti does not exist')
    else
        refnii = cell2mat(varargin);
    end
else
    error('Please provide a full path name to the reference nifti')
end

dims = size(data);
if length(dims) == 3
    V = spm_vol(refnii);
    V = V(1); %Why? no idea
    
    V.dt = [spm_type('float32'); 0];
    
    V.fname = fullfile(outputdir, name);
    
    V.dim = size(data);
    spm_write_vol(V, data);

elseif length(dims) == 4
    V = spm_vol(refnii);
    V = V(1); %Why? no idea
    if max(data(:)) > 2^15 || min(data(:)) < -2^15
        V.dt = [spm_type('float32'); 0];
    else
        V.dt = [spm_type('float32'); 0]; %int16
    end
    V.dim = dims(1:3);
    
    
    %create random workdir for temporary saving of nifti's
    workdir = fullfile(outputdir, [num2str(round(rand(1)*1000000)) 'MYsaveniitmp']);
    while exist(workdir, 'dir')>0
        workdir = fullfile(outputdir, [num2str(round(rand(1)*1000000)) 'MYsaveniitmp']);
    end
    
        
    MYmkdir(workdir);
    
    
    for I = 1:dims(4)
        
        V.fname = fullfile(workdir, [num2str(I, '%03d') '_' name]);
        
        spm_write_vol(V, data(:,:,:,I));
    end
    
    
    MYunix(['fslmerge -t ' fullfile(outputdir,name) ' ' workdir '/*.nii']);
    rmdir(workdir, 's');
elseif length(dims) == 2
    V = spm_vol(refnii);
    V = V(1); %Why? no idea
    
    V.dt = [spm_type('float32'); 0];
    
    V.fname = fullfile(outputdir, name);
    
    V.dim = [size(data,1) size(data,2) 1];
    spm_write_vol(V, data);
end

% if exist(fullfile(outputdir, [name '.gz']), 'file')
%     delete(fullfile(outputdir, [name '.gz']));
% end
% MYunix(['gzip ' fullfile(outputdir, name)]);



if deleterefnii
    delete(refnii);
end


end


