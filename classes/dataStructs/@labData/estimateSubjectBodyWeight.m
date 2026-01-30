function bodyWeight = estimateSubjectBodyWeight(this)
%estimateSubjectBodyWeight  Estimates subject weight from GRF
%data
%
%   bodyWeight = estimateSubjectBodyWeight(this) estimates
%   subject body weight by averaging vertical ground reaction
%   forces
%
%   Inputs:
%       this - labData object
%
%   Outputs:
%       bodyWeight - estimated body weight in kg
%
%   Note: Assumes z-axis forces are representative of body
%         weight
%
%   See also: computeTorques

% Taking forces in z-axis and averaging to estimate subject weight
bodyWeight = ...
    -nanmean(sum(this.GRFData.getDataAsVector({'LFz', 'RFz'}), 2)) / 9.8;
end

