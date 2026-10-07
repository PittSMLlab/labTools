function bodyWeight = estimateSubjectBodyWeight(this)
%ESTIMATESUBJECTBODYWEIGHT Estimates subject weight from GRF data.
%
%   bodyWeight = estimateSubjectBodyWeight(this) estimates subject body
% weight by averaging vertical ground reaction forces
%
% Inputs:
%   this - labData object
%
% Outputs:
%   bodyWeight - estimated body weight in kg
%
% NOTE: Assumes z-axis forces are representative of body weight
%
% Toolbox Dependencies: None
%
% See also COMPUTETORQUES.

% Taking forces in z-axis and averaging to estimate subject weight
gravityAcc = 9.8; % m/s^2
bodyWeight = ...
    -mean(sum(this.GRFData.getDataAsVector({'LFz', 'RFz'}), 2), ...
    'omitnan') / gravityAcc;
end

