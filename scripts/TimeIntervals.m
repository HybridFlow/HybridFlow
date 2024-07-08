function [intervalFast,kcenter_timepoint1,kcenter_timepoint2] = TimeIntervals(dicomfolder,sequencenameFast,workingDir,MP2RAGE_postcontrast1File,MP2RAGE_postcontrast2File)
%Calculate the interval between the dynamics in the fast DCE scan
cd(dicomfolder)
s = dir([dicomfolder,'/*.IMA']);
nDicoms = size(s,1);
iFast = 1;
display('TimeIntervals.m is running to get the timepoints of the scans...');
for i = 1:nDicoms
    info = dicominfo([dicomfolder,'/',s(i).name]);
    tffast = strcmp(info.SeriesDescription,sequencenameFast);
    if tffast == 1
        FastAcq = info.AcquisitionTime;
        hours = str2double(FastAcq(1,1:2))*60*60;
        mins = str2double(FastAcq(1,3:4))*60;
        secs = str2double(FastAcq(1,5:end));
        intervalFast(iFast,1) = hours+mins+secs;
        iFast = iFast + 1;
    end

end

format long
intervalFast2 = unique(intervalFast);
intervalFast3 = intervalFast2 - intervalFast2(1,1);
intervalFast = intervalFast3;
cd(workingDir)
save('intervalFast.mat','intervalFast','-v7.3')


%get begin timepoints of MP2RAGES after contrast
image1_struct=load_untouch_nii(MP2RAGE_postcontrast1File);
Acq1 = image1_struct.hdr.hist.descrip;
hours1 = str2double(Acq1(1,13:14))*60*60; %the hours are at the 13th and 14th position in the char
mins1 = str2double(Acq1(1,15:16))*60;
secs1 = str2double(Acq1(1,17:20));
startpoint1=(hours1+mins1+secs1)-intervalFast2(1,1);
kcenter_timepoint1=startpoint1+85;%the center of k space is acquired at 1/3 of the total scan time; so here 85sec after the beginning timepoint

image2_struct=load_untouch_nii(MP2RAGE_postcontrast2File);
Acq2 = image2_struct.hdr.hist.descrip;
hours2 = str2double(Acq2(1,13:14))*60*60;
mins2 = str2double(Acq2(1,15:16))*60;
secs2 = str2double(Acq2(1,17:20));
startpoint2=(hours2+mins2+secs2)-intervalFast2(1,1);
kcenter_timepoint2=startpoint2+85;

intervalTotal=[intervalFast;kcenter_timepoint1;kcenter_timepoint2];
save('intervalTotal.mat','intervalTotal','-v7.3')

display('Done!');

end

