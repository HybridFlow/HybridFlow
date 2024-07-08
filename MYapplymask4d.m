function [outputdata] = MYapplymask4d(inputdata, maskdata)
%  Apply a 3d mask to 4d data. Usage output = MYapplymask4d(data,
%  mask). Input can be either a 4 dimension and 3 dimension matrix, paths 
%  to the nifti files, a MYnii struct or any combination thereof. Second 
%  dimension is time so mean(output, 2) gives mean per timepoint. 

if ischar(inputdata)
    data = MYnii(inputdata);
    data = data.data;
elseif isstruct(inputdata) && isfield(inputdata, 'data')
    data = inputdata.data;    
elseif isfloat(inputdata) && numel(size(inputdata)) == 4
    data = inputdata;
else
    error('Data input not recognized. Please provide either a path, 4D matrix or a MYnii struct.')
end

if ischar(maskdata)
    mask = MYnii(maskdata);
    mask = mask.data;
elseif isstruct(maskdata) && isfield(maskdata, 'data')
    mask = maskdata.data;
elseif isfloat(maskdata) && numel(size(maskdata)) == 3
    mask = maskdata;
else
    error('Mask input not recognized. Please provide either a path, 3D matrix or MYnii struct.')
end



if sum(size(mask)) ~= sum([size(data,1) size(data,2) size(data,3)])
    error('Size of the mask is different from the size of the data!')
end

if sum(mask~=0 & mask~=1)>0 %if mask is not binary
    mask = mask(mask>0.9);
end



inds = find(mask);
outputdata = zeros([numel(inds), size(data, 4)]);
for I = 1:size(data, 4)
    outputdata(:,I) = data(inds);
    inds = inds + (size(mask,1) * size(mask,2) * size(mask,3));
end





%andere oplossing, duurt veel langer
% data = squeeze(mat2cell(data, size(data, 1), size(data, 2), size(data, 3), ones(1,size(data, 4))));
% bla = cellfun(@(x) x(inds), data, 'UniformOutput', false);
% outputdata = cell2mat(bla);








