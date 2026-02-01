function ageInMonths = getSubjectAgeAtExperimentDate(this)
%getSubjectAgeAtExperimentDate  Computes subject age at experiment time
%
%   ageInMonths = getSubjectAgeAtExperimentDate(this) calculates the
%   subject's age in months at the time of the experiment from either
%   stored age or date of birth
%
%   Inputs:
%       this - experimentData object
%
%   Outputs:
%       ageInMonths - subject age in months at experiment date
%
%   Note: Warns if DOB is present as this may be a privacy issue
%
%   See also: subjectData, experimentMetaData

if ~isempty(this.subData.age)
    ageInMonths = this.subData.age * 12; % In months
elseif ~isempty(this.subData.dateOfBirth)
    warning('expData:subjectDOB', ...
        'subject metadata contains DOB, this may be a privacy issue.');
    dob = this.subData.dateOfBirth;
    testData = this.metaData.date;
    ageInMonths = testData.timeSince(dob);
else
    error('expData:subjectDOB', ...
        'Could not establish subject age at experiment time.');
end
end

