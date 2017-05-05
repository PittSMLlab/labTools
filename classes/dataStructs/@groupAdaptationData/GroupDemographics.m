function [ Demographics ] = GroupDemographics(SMatrix)
%GroupDemographics Computes group demographics -- A CJS origonal, 5/5/17
%   Calculates number subjects, mean and std of age and number of males
%   The input is either the output of "makeSMatrixV2" or "uiCreateStudy".
%   Lets say the output of these funciton you called "DumbTester7", you
%   would then call this funciton like this:
%   Demographics=GroupDemographics(DumbTester7)
%   Now Demographics has all the things you might want to know about your
%   study for inclusion in paper and posters and the like

grps=fieldnames(SMatrix);
StudyAge=[];
StudyMale=[];
for g=1:length(grps)  
    [Demographics.(grps{g})]=SMatrix.(grps{g}).GroupDemographics(grps{g});
    StudyAge=[StudyAge Demographics.(grps{g}).AllAge];
    StudyMale=[StudyMale Demographics.(grps{g}).NMale];
end

Demographics.StudyDemographics.N=length(StudyAge);
Demographics.StudyDemographics.MeanAge=mean(StudyAge);
Demographics.StudyDemographics.StdAge=std(StudyAge);
Demographics.StudyDemographics.NMale=sum(StudyMale);
end

