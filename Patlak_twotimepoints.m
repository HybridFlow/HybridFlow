function [ ] = Patlak_twotimepoints(workingDir,concentrationmap1File,concentrationmap2File,maskFile)
% Patlak - Calculates the ki and vp maps, i.e. Ki and Vp per voxel. 
% Based on script "kimap_20141111.m" of Joost de Jong and "Patlak.m" of
% Lisanne Canjels
% Adapted for 2 MP2RAGE timepoints after contrast injection by Paulien Voorter

cd(workingDir)

display(['workingDir = ''', workingDir,'''']);
display(['concentrationMap1 = ''', concentrationmap1File,'''']);
display(['concentrationMap2 = ''', concentrationmap2File,'''']);
display(['maskFile = ''', maskFile,'''']);

%% mask
% load the brainmask if you want a Kimap of the whole brain
mask = MYnii(maskFile);
% mask of whole image instead of brain: 
%mask = logical(mask.data);
mask = ones(size(mask.data));

inds = find(mask);

%% concentration in blood plasma (Cp)
load(fullfile(workingDir,'Cp_inputPatlak.mat')); %contains all the information of 
% concentration in the blood plasma

% load data for the horizontal axis of the Patlak plot
xdata=Cp_inputPatlak(1,:);
Cp=Cp_inputPatlak(2,:);

%% concentration in tissue (Ct)
% load the concentration maps at the two timepoints of the MP2RAGEs
Ct_1 = MYnii(concentrationmap1File);
Ct_1 = Ct_1.data./1000; %uM naar mM

Ct_2 = MYnii(concentrationmap2File);
Ct_2 = Ct_2.data./1000; %uM naar mM


%% loop
display(['Calculating ki of ' num2str(numel(inds)) ' voxels...'])

display('Starting loop to calculate Ki and Vp...')

tic
ki = cell(numel(inds),1);
vp = cell(numel(inds),1);


for I = 1:numel(inds)
    Ct_pixel=[Ct_1(inds(I)) Ct_2(inds(I))];


    ydata = Ct_pixel./Cp;
    ydata(~isfinite(ydata)) = 0;

    if ydata(1)==0 || ydata(1)==0 %if too many zeros, probably something went wrong
        ki{I} = -1;
        vp{I} = -1;

    else

        % draw straight line through 2 data points 
        % slope --> Ki
        ki_pixel = (ydata(2)-ydata(1))/(xdata(2)-xdata(1)); %[min^-1]
        % y intercept --> vp
        vp_pixel = ydata(1)-xdata(1)*ki_pixel;
        ki{I}=ki_pixel; %[min^-1]
        vp{I}=vp_pixel;

%             patlak = figure;
%             set(patlak, 'Name', 'test');
% %             if rem(I,1000)==0
%                 figure(patlak);
% %                 plot(xdata, ydata, 'k.', xdata, vp{I} + ki_sec*tmpxdata, 'k');
%                 plot(xdata, ydata, 'k.');
%                 xlabel('_{0}\int^{t}C_{p}(\tau)d\tau / C_{p}(t)');
%                 ylabel('C_{t}(t) / C_{p}(t)');
% %                 axis([0 1800 0 1]);
% %                 text(tmpxdata(2),0.9,['v_p = ' num2str(brob(1))], 'HorizontalAlignment','left','FontSize', 12, 'Color', 'black')
% %                 text(tmpxdata(2),0.8,['k_i = ' num2str(brob(2)*60)], 'HorizontalAlignment','left','FontSize', 12, 'Color', 'black')
% %                 drawnow;
%                 hold on;
%            end          
    end     
end   
   
toc
display('Finished loop')

%% save Ki and Vp maps
ki = cell2mat(ki);
vp = cell2mat(vp);

size_concentration=size(Ct_1);

kimap = zeros([size_concentration(1) size_concentration(2) size_concentration(3)]);
kimap(inds) = ki;
% kimap(kimap < 0) = 0;
kimap(~mask) = 0;

vpmap = zeros([size_concentration(1) size_concentration(2) size_concentration(3)]);
vpmap(inds) = vp;
% vpmap(vpmap == -1) = 0;

refFile=concentrationmap1File;
MYsavenii(kimap, workingDir, 'kimap.nii', refFile);
MYsavenii(vpmap, workingDir, 'vpmap.nii', refFile);



end

