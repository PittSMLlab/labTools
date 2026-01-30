function [momentData, COP, COM] = computeTorques(this, ...
    subjectWeight)
%computeTorques  Computes joint torques from kinematics and
%kinetics
%
%   [momentData, COP, COM] = computeTorques(this) computes
%   joint torques using estimated subject weight from GRF data
%
%   [momentData, COP, COM] = computeTorques(this,
%   subjectWeight) computes joint torques using specified
%   subject weight
%
%   Inputs:
%       this - labData object
%       subjectWeight - subject body weight in kg (optional,
%                       estimated from GRF if not provided)
%
%   Outputs:
%       momentData - labTimeSeries containing joint moment data
%       COP - center of pressure data
%       COM - center of mass data
%
%   See also: TorqueCalculator, estimateSubjectBodyWeight

if nargin < 2 || isempty(subjectWeight)
    warning(['Subject weight not given, estimating from ' ...
        'GRFs. This will fail miserably if z-axis force is ' ...
        'not representative of weight.'])
    subjectWeight = estimateSubjectBodyWeight(this);
end
[momentData, COP, COM] = TorqueCalculator(this, subjectWeight);
end

