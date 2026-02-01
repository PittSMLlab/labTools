function adaptData = makeDataObj(this, filename, experimentalFlag, ...
    contraLateralFlag)
%makeDataObj  Creates an adaptationData object
%
%   adaptData = makeDataObj(this, filename) creates an adaptationData
%   object and saves it to file
%
%   adaptData = makeDataObj(this, filename, experimentalFlag,
%   contraLateralFlag) controls inclusion of experimental parameters
%   and contralateral computation
%
%   Inputs:
%       this - experimentData object
%       filename - string for saving (typically subject identifier,
%                  optional)
%       experimentalFlag - false (or 0) prevents experimental
%                          parameter calculation (optional)
%       contraLateralFlag - if true, computes parameters using
%                           non-reference leg (optional)
%
%   Outputs:
%       adaptData - adaptationData object, saved to present working
%                   directory if filename specified
%
%   Examples:
%       adaptData = expData.makeDataObj('Sub01') saves
%       adaptationData object to Sub01params.mat
%
%       adaptData = expData.makeDataObj('', false) does not include
%       experimentalParams and does not save to file
%
%   See also: adaptationData, makeDataObjNew

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

