function [syns,coefs,res,fullSyns] = ...
    getSynergies(data,dim,replicates,usePar)
%GETSYNERGIES Non-negative matrix factorization with normalized synergies.
%
%   Factorizes the data with myNNMF into synergies and activation
% coefficients. The data are transposed (with a warning) if the second
% dimension is not the shorter one.
%
% Side effects: displays a warning in the command window when the data
%   have to be transposed.
%
% Inputs:
%   data       - samples x channels matrix
%   dim        - number of synergies
%   replicates - (optional) number of NNMF replicates (default: 5)
%   usePar     - (optional) parallel option passed to myNNMF (default:
%                'never')
%
% Outputs:
%   syns     - normalized synergies
%   coefs    - activation coefficients
%   res      - residual
%   fullSyns - declared output, never assigned
%
% Toolbox Dependencies: None (myNNMF may use the Statistics and Machine
%   Learning Toolbox)
%
% See also MYNNMF, COEFEXTRFROMSYN.

%% Check if replicates is given, if not, default
if nargin < 4
    usePar = 'never';
end
if nargin < 3
    replicates = 5; %default value
end

%% Check if data is given so that the short dimension is the second one
if size(data,2) >= size(data,1)
    data = data';
    disp('Warning: data was given in the transposed form')
end

%% Get synergies
%Auto-replicating:
[coefs,syns,res] = myNNMF(data,dim,replicates,usePar); %Normalized coefs
coefs = coefs';
syns  = syns';
res   = (res*numel(data))^2;
end

