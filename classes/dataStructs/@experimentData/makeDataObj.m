function adaptData = makeDataObj(this, filename, experimentalFlag, ...
    contraLateralFlag)
%MAKEDATAOBJ Creates an adaptationData object
%
%   adaptData = makeDataObj(this, filename) creates an adaptationData object
% and saves it to file
%
%   adaptData = makeDataObj(this, filename, experimentalFlag,
% contraLateralFlag) controls inclusion of experimental parameters and
% contralateral computation
%
% Inputs:
%   this              - experimentData object
%   filename          - string for saving (typically subject identifier,
%                       optional)
%   experimentalFlag  - false (or 0) prevents experimental parameter
%                       calculation (optional)
%   contraLateralFlag - if true, computes parameters using non-reference leg
%                       (optional)
%
% Outputs:
%   adaptData - adaptationData object; when filename is specified it is
%               saved as <filename>params.mat (-v7.3), silently
%               overwriting an existing file. A bare filename resolves
%               against the current folder (see DATA_OUTPUTS.md).
%
% Toolbox Dependencies: None
%
% Example:
%   adaptData = expData.makeDataObj('Sub01'); saves
%   adaptationData object to Sub01params.mat
%
%   adaptData = expData.makeDataObj('', false); does not include
%   experimentalParams and does not save to file
%
% See also ADAPTATIONDATA, MAKEDATAOBJNEW.

if ~(this.isProcessed)
    ME = MException('experimentData:makeDataObj', ...
        ['Cannot create an adaptationData object from ' ...
        'unprocessed data!']);
    throw(ME);
end

if nargin < 3
    experimentalFlag = [];
end
if nargin < 2
    filename = [];
end
if nargin < 4
    contraLateralFlag = [];
end
adaptData = makeDataObjNew(this, filename, experimentalFlag, ...
    contraLateralFlag);
end

