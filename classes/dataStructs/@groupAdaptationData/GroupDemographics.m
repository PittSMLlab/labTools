function Demographics = GroupDemographics(SMatrix)
%GROUPDEMOGRAPHICS Compute group and study demographics.
%
%   Demographics = GroupDemographics(SMatrix) calls the
% GroupDemographics method of every group in SMatrix and adds study-wide
% totals (number of subjects, mean and std of age, number of males).
% SMatrix is the output of MAKESMATRIXV2 or UICREATESTUDY.
%
% Inputs:
%   SMatrix - struct with one groupAdaptationData object per field
%             (one field per group)
%
% Outputs:
%   Demographics - struct with one field per group (the output of that
%                  group's GroupDemographics method) and a field
%                  StudyDemographics with N, MeanAge, StdAge, and NMale
%                  over all groups
%
% NOTE: shadowed. groupAdaptationData.m defines the method
%       GroupDemographics(this) inline, and that definition takes
%       precedence over this file. The call below passes an argument
%       (SMatrix.(group).GroupDemographics(group)) that the inline method
%       does not accept; the working study-level function is
%       fun/misc/hmhFun/GroupDemographics.m.
%
% Toolbox Dependencies: None
%
% See also MAKESMATRIXV2, UICREATESTUDY.

grps      = fieldnames(SMatrix);
StudyAge  = [];
StudyMale = [];
for g = 1:length(grps)
    Demographics.(grps{g}) = SMatrix.(grps{g}).GroupDemographics(grps{g});
    StudyAge  = [StudyAge Demographics.(grps{g}).AllAge];
    StudyMale = [StudyMale Demographics.(grps{g}).NMale];
end

Demographics.StudyDemographics.N = length(StudyAge);
Demographics.StudyDemographics.MeanAge = mean(StudyAge);
Demographics.StudyDemographics.StdAge = std(StudyAge);
Demographics.StudyDemographics.NMale = sum(StudyMale);
end

