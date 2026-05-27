function xticklabel_rotate90(XTick, xTickLabels, varargin)
%XTICKLABEL_ROTATE90 Rotate x-tick labels by 90 degrees.
%
%   Replaces numeric XTick labels with rotated text objects, allowing
%   the caller to supply arbitrary cell-array labels via xTickLabels.
%   Additional property-value pairs are forwarded to the text() call.
%
%   NOTE: This function name does not match the file name
%   (xticklabel_rotate90_cell.m). Do not rename the file; call this
%   function as xticklabel_rotate90().
%
% Inputs:
%   XTick       - numeric vector of x-tick positions
%   xTickLabels - cell array of label strings, one per element of XTick
%   varargin    - additional property-value pairs forwarded to text()
%
% Outputs:
%   None
%
% Toolbox Dependencies: None
%
% See also TEXT, SET.
%
% Author: Denis Gilbert, Ph.D., physical oceanography
% Maurice Lamontagne Institute, Dept. of Fisheries and Oceans Canada
% email: gilbertd@dfo-mpo.gc.ca  Web: http://www.qc.dfo-mpo.gc.ca/iml/
% February 1998; Last revision: 24-Mar-2003

if ~isnumeric(XTick)
    error('XTICKLABEL_ROTATE90 requires a numeric input argument');
end

% Make sure XTick is a column vector.
XTick = XTick(:);

% Clear the built-in tick labels at the desired positions.
set(gca, 'XTick', XTick, 'XTickLabel', '')

% Determine the vertical position for the rotated labels.
hxLabel      = get(gca, 'XLabel');
xLabelString = get(hxLabel, 'String');

if ~isempty(xLabelString)
    warning('You may need to manually reset the XLABEL vertical position')
end

set(hxLabel, 'Units', 'Data');
xLabelPosition = get(hxLabel, 'Position');
y = xLabelPosition(2);
Y_LABEL_OFFSET = 1.1;  % empirical offset below axis (per Urs Schwarz)
y = Y_LABEL_OFFSET;
%y = repmat(y, size(XTick, 1), 1);

fs = get(gca, 'FontSize');

for ii = 1:length(XTick)
    % Place rotated text objects in lieu of built-in tick labels.
    hText = text(XTick(ii), y, xTickLabels{ii}, 'FontSize', fs);
    set(hText, 'Rotation', 90, 'HorizontalAlignment', 'Right', varargin{:})
end

end
