function fh = plot3(this, fh)
%plot3  Plots 3D trajectories
%
%   fh = plot3(this) plots 3D trajectories for all markers
%
%   fh = plot3(this, fh) plots in existing figure
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       fh - figure handle (optional)
%
%   Outputs:
%       fh - figure handle
%
%   Note: Plots all 3 components of all variables in OTS instance, with
%         outliers marked in red if Quality field exists
%
%   See also: animate, animate2

% -------------------
% plots all 3 components of all variables in OTS instance
%
% INPUTS:
% fh, figure handle. If none passed in, a new one is created
% OUTPUTS:
% fh, figure handle to figure that shows 3D plot of each data variable
% (e.g. marker data or GRFdata)

if nargin < 2 || isempty(fh)
    fh = figure; % return handle to a figure
else
    figure(fh);
end
[data, labelPref] = getOrientedData(this);
hold on;

for i = 1:length(labelPref)
    plot3(data(:, i, 1), data(:, i, 2), data(:, i, 3), '.');
    if ~isempty(this.Quality)
        aux = this.Quality(:, i) == 1;
        plot3(data(aux, i, 1), data(aux, i, 2), data(aux, i, 3), ...
            'rx');
    end
end
hold off;
axis equal;
legend(labelPref);
end

