function [this, iC, iI] = getaSym(this)
%getaSym  Computes asymmetric components
%
%   [this, iC, iI] = getaSym(this) computes asymmetric (difference)
%   components of bilateral data
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       this - alignedTimeSeries with asymmetric components
%       iC - indices of contralateral labels
%       iI - indices of ipsilateral labels
%
%   Note: Computes slow - fast
%
%   See also: getSym, flipLR

[this, iC, iI] = this.flipLR; % First, flip the non-aligned side.
% Then: compute asym data and replace it.
this.Data = [this.Data(:, iI) - this.Data(:, iC)]; % we do slow - fast
% Update labels:
this.labels = [regexprep(this.labels(iI), ...
    ['^' this.labels{iI(1)}(1)], 'a')];
end

