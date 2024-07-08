function [ ] = getVIF(dicomdir,workingDir,concentrationmap1File,concentrationmap2File,fastdceFile,sequencenameFast,MP2RAGE_postcontrast1File,MP2RAGE_postcontrast2File,hematocrit,fastLookUpTableFile)

cd(workingDir)

% retrieve the exact timepoints of the mri scans using the dicominformation
[intervalFast,kcenter_timepoint1,kcenter_timepoint2] = TimeIntervals(dicomdir,sequencenameFast,workingDir,MP2RAGE_postcontrast1File,MP2RAGE_postcontrast2File);

vifmaskFile='vif_mask.nii';
display(['workingDir = ''', workingDir,'''']);
display(['vifmaskFile = ''', vifmaskFile,'''']);
display(['fastdceFile = ''', fastdceFile,'''']);
display(['MP2RAGE_postcontrast1File = ''', MP2RAGE_postcontrast1File,'''']);
display(['MP2RAGE_postcontrast2File = ''', MP2RAGE_postcontrast2File,'''']);
display(['concentrationmap1File = ''', concentrationmap1File,'''']);
display(['concentrationmap2File = ', concentrationmap2File,'''']);
display(['intervalFast = ', mat2str(intervalFast)]);
display(['kcenter_timepoint1 = ', mat2str(kcenter_timepoint1./60),' min']);
display(['kcenter_timepoint2 = ', mat2str(kcenter_timepoint2./60),' min']);

if exist(vifmaskFile, 'file') == 0
    display('Create mask for vascular input function!');
    exit
end

intervalFast = intervalFast./60; %seconds to minutes
kcenter_timepoint1 = kcenter_timepoint1/60; %seconds to minutes
kcenter_timepoint2 = kcenter_timepoint2/60; %seconds to minutes

%% concentration from SSS in MP2RAGEs
vifmask=load_untouch_nii(vifmaskFile);
vifmask=vifmask.img;

conc1image=load_untouch_nii(concentrationmap1File);
conc1image=double(conc1image.img)./1e3; %uM to mM
indsvif=find(vifmask);
conc1=mean(conc1image(indsvif));

display(['number of SSS pixels included in vif mask:', mat2str(length(indsvif))]);

conc2image=load_untouch_nii(concentrationmap2File);
conc2image=double(conc2image.img)./1e3;%uM to mM
conc2=mean(conc2image(indsvif));

if conc2>conc1
    display(['WARNING: Concentration at t=', mat2str(kcenter_timepoint2/60),' min is higher than concentration at t=', mat2str(kcenter_timepoint1/60)],' min');
    exit
end

% fit monoexponential curve through these two time points
x0=0.75*conc2;
f = @(x,xdata) x0 + x(1) .* exp(-x(2).*xdata);

xdata = [kcenter_timepoint1,kcenter_timepoint2];
ydata = [conc1,conc2];


startvals = [0.3 0.05];
options = optimset('Display', 'off');
[fitout,~,~,~] = lsqcurvefit(f, startvals ,xdata,ydata, [0 0], [1 .1], options);
times = linspace(xdata(1),xdata(end));
figure;plot(xdata,ydata,'ko',times,f(fitout,times),'b-')

interval_extra=times(end):0.01:50;
vif_extra=f(fitout,[times(end):0.01:50]);




%% fast dce concentration
datafast = mean(MYapplymask4d(fastdceFile, vifmaskFile),1);
%datafastREF = mean(MYapplymask4d(fastdceFile, refmaskFile),1);

%get first contrast fast
differences = diff(datafast);
meandifferencebeginning = mean(differences(1:5)) + 3*std(differences(1:5));
list = differences(differences>meandifferencebeginning);
firstcontrast_fast = find(differences == list(1));
clear list differences meandifferencebeginning

%calculate relative signal fast dce (S-S0)/S0
S0=mean(datafast(4:firstcontrast_fast-5));
datafast=(datafast-S0.*ones(size(datafast)))./S0;
save(fullfile(workingDir,'datafast.mat'), 'datafast');

%contains the parameters for the biexponential fit through the concentration vs signal enhancement curve, essentially the data obtained
%from the phantom data
LUT = load(fastLookUpTableFile);

% apply lookup table using an ugly loop...
concFast = zeros(length(datafast), 1);
% concFast = datafast;%zeros(length(datafast), 1);
% syms x
% x = 10;
warning('off','all')

try
	for I = firstcontrast_fast-1:length(datafast)
%         concFast(I) = fsolve(@(x) myFunConcentrationVIF(x,LUT,datafast(I)),x);
% 	    concFast(I) = solve(datafast(I) == ((LUT.fitout3(1)-1) - LUT.fitout3(2)*exp(-LUT.fitout3(3)*x))*exp(-LUT.fitout3(4)*x), x);
	    fun = @(x)(( (LUT.fitout3(1)-1) - LUT.fitout3(2)*exp(-LUT.fitout3(3)*x))*exp(-LUT.fitout3(4)*x)-datafast(I));
        concFast(I) = fsolve(fun,1);
    end
catch
end
warning('on','all')

concFast(1:firstcontrast_fast-1) = 0;
concFast(concFast<0) = 0;
concFast(~isfinite(concFast)) = 0;


timepoint = intervalFast(end);
newfastendConc = f(fitout, timepoint); %expected concentration of last timepoint in fast dce, based on MP2RAGEs
concFast = concFast./concFast(end).*newfastendConc; %multiply fast with this number to correct


%% check fit --> implementeer nog dat meerdere punten van fast meegenomen worden om te schalen
VIF=[concFast',f(fitout,times)];

checkfit=1;
if checkfit
    checkfitFigure=figure('units','normalized','position',[0 0 1 1]);
    plot([intervalFast',times], VIF, '-r',intervalFast', concFast, 'b.',[kcenter_timepoint1 kcenter_timepoint2],[conc1 conc2], 'gx',[kcenter_timepoint1-85/60 kcenter_timepoint1+171/60],[conc1 conc1],'g-',[kcenter_timepoint2-85/60 kcenter_timepoint2+171/60],[conc2 conc2],'g-');
    legend('VIF','fast DCE','k-space center filled MP2RAGE','duration MP2RAGE')
    xlabel('Time (min)')
    ylabel('Concentration (mM)')
    MYsetfontsize(16,2,8)    
    hgexport(checkfitFigure, fullfile(workingDir,'checkfit_vif.jpg'), ...     
            hgexport('factorystyle'), 'Format', 'jpeg');
   
end

% Save VIF
save(fullfile(workingDir,'vif.mat'), 'VIF');


%%HEMATOCRITVALUE REQUIRED!
%% Cp input for Patlak model
save(fullfile(workingDir,'hematocrit.mat'), 'hematocrit');
concentration_sagsinus = bsxfun(@rdivide,VIF,(1-hematocrit)); %apply hematocrit value for plasma concentration
rsumCp = cumtrapz([intervalFast',times], concentration_sagsinus);

integralCp_1=interp1([intervalFast',times],rsumCp,kcenter_timepoint1);
integralCp_2=interp1([intervalFast',times],rsumCp,kcenter_timepoint2);

Cp1=conc1/(1-hematocrit);
Cp2=conc2/(1-hematocrit);
Cp=[Cp1 Cp2];

xdata = [integralCp_1/Cp1 integralCp_2/Cp2];
xdata(~isfinite(xdata)) = 0;

timepoints=[kcenter_timepoint1 kcenter_timepoint2];

Cp_inputPatlak=[xdata;Cp;timepoints];
save(fullfile(workingDir,'Cp_inputPatlak.mat'), 'Cp_inputPatlak');


%% for in-vivo based simulations input VIF:
save(fullfile(workingDir,'interval_extra.mat'), 'interval_extra');
save(fullfile(workingDir,'vif_extra.mat'), 'vif_extra');

end
