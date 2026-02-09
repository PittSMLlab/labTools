function [this, iC, iI] = getSym(this)
%getSym  Computes symmetric components
%
%   [this, iC, iI] = getSym(this) computes symmetric (sum) and
%   asymmetric (difference) components of bilateral data
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       this - alignedTimeSeries with symmetric/asymmetric components
%       iC - indices of contralateral labels
%       iI - indices of ipsilateral labels
%
%   See also: getaSym, flipLR

[this, iC, iI] = this.flipLR; % First, flip the non-aligned side.
% Then: compute sym/asym data and replace it.
this.Data = [this.Data(:, iI) - this.Data(:, iC) ...
    this.Data(:, iI) + this.Data(:, iC)];
% Update labels:
this.labels = [regexprep(this.labels(iI), ...
    ['^' this.labels{iI(1)}(1)], 'a') ...
    regexprep(this.labels(iI), ['^' this.labels{iI(1)}(1)], 'b')];
end

