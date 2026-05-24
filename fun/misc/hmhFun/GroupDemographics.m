function Demographics = GroupDemographics(SMatrix)
%GROUPDEMOGRAPHICS Compute group and study-level demographics.
%
%   Calculates the number of subjects, mean and SD of age, and number of
% males for each group in SMatrix, then aggregates across all groups for
% study-level summaries.
%
% Inputs:
%   SMatrix - Struct whose fields are group names; each field must have
%             a GroupDemographics sub-struct with AllAge and NMale fields
%             (as returned by makeSMatrixV2 or uiCreateStudy)
%
% Outputs:
%   Demographics - Struct with one field per group from SMatrix plus a
%                  StudyDemographics field containing N, MeanAge, StdAge,
%                  and NMale aggregated across all groups
%
% Toolbox Dependencies: None
%
% See also MAKESMATRIXV2, UICREATESTUDY.

grps      = fieldnames(SMatrix);
studyAge  = [];
studyMale = [];

for gg = 1:length(grps)
    Demographics.(grps{gg}) = SMatrix.(grps{gg}).GroupDemographics;
    studyAge  = [studyAge  Demographics.(grps{gg}).AllAge];  %#ok<AGROW>
    studyMale = [studyMale Demographics.(grps{gg}).NMale];   %#ok<AGROW>
end

Demographics.StudyDemographics.N       = length(studyAge);
Demographics.StudyDemographics.MeanAge = mean(studyAge);
Demographics.StudyDemographics.StdAge  = std(studyAge);
Demographics.StudyDemographics.NMale   = sum(studyMale);

end
