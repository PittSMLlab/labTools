function xticklabel_rotate90(XTick,xTickLabels,varargin)
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

%Make sure XTick is a column vector
XTick = XTick(:);

%Set the Xtick locations and set XTicklabel to an empty string
set(gca,'XTick',XTick,'XTickLabel','')

% Define the xtickLabels
%xTickLabels = num2str(XTick);

% Determine the location of the labels based on the position
% of the xlabel
hxLabel = get(gca,'XLabel');  % Handle to xlabel
xLabelString = get(hxLabel,'String');

if ~isempty(xLabelString)
   warning('You may need to manually reset the XLABEL vertical position')
end

set(hxLabel,'Units','data');
xLabelPosition = get(hxLabel,'Position');
y = xLabelPosition(2);
y=1.1;

%CODE below was modified following suggestions from Urs Schwarz
%y=repmat(y,size(XTick,1),1);
% retrieve current axis' fontsize
fs = get(gca,'fontsize');

for i=1:length(XTick)
% Place the new xTickLabels by creating TEXT objects
hText = text(XTick(i), y, xTickLabels{i},'fontsize',fs);

% Rotate the text objects by 90 degrees
set(hText,'Rotation',90,'HorizontalAlignment','right',varargin{:})
end

%------------- END OF CODE --------------
