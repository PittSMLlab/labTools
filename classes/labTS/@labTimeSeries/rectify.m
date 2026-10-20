function this = rectify(this)
%RECTIFY Takes absolute value of data.
%
%   this = rectify(this) computes absolute value of all data
%
% Inputs:
%   this - labTimeSeries object
%
% Outputs:
%   this - labTimeSeries with rectified data
%
% Toolbox Dependencies: None
%
% See also TIMES.

this.Data = abs(this.Data);
this.labels = strcat(strcat(this.labels), 'abs');
end

