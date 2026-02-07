function newThis = addNewParameter(this, newParamLabel, funHandle, ...
    inputParameterLabels, newParamDescription)
%addNewParameter  Computes and adds new parameter from existing parameters
%
%   newThis = addNewParameter(this, newParamLabel, funHandle,
%   inputParameterLabels, newParamDescription) computes new parameter
%   from existing parameters and adds it
%
%   Inputs:
%       this - parameterSeries object
%       newParamLabel - string name for new parameter
%       funHandle - function handle with N input variables
%       inputParameterLabels - cell array of N parameter labels to use
%                              as inputs
%       newParamDescription - description string for new parameter
%
%   Outputs:
%       newThis - parameterSeries with new parameter added
%
%   Example:
%       Define normalized velocity contribution that divides by avg.
%       step time and avg. step velocity, so that velocity contribution is
%       now measure of belt-speed ratio:
%       newThis = this.addNewParameter('newVelocityContribution',
%           @(x,y,z) x ./ (2*y./z), {'velocityContributionAlt',
%           'stepTimeContribution', 'stepTimeDiff'},
%           'velocityContribution normalized to strideTime times
%           average velocity');
%
%   See also: computeNewParameter, appendData

newData = this.computeNewParameter( ...
    newParamLabel, funHandle, inputParameterLabels);
newThis = appendData( ...
    this, newData, {newParamLabel}, {newParamDescription});
end

