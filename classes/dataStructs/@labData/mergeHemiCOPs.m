function [COP] = mergeHemiCOPs(COPL, COPR, FL, FR, noFilterFlag)
%mergeHemiCOPs  Merges left and right center of pressure data
%
%   COP = mergeHemiCOPs(COPL, COPR, FL, FR, noFilterFlag)
%   combines left and right COP data weighted by vertical
%   forces
%
%   Inputs:
%       COPL - left leg center of pressure (orientedLabTS)
%       COPR - right leg center of pressure (orientedLabTS)
%       FL - left leg force data
%       FR - right leg force data
%       noFilterFlag - flag indicating if filtering should be
%                      applied (1 = apply filtering)
%
%   Outputs:
%       COP - merged center of pressure data containing both
%             individual and combined COP
%
%   See also: computeCOPAlt, computeHemiCOP

if noFilterFlag == 1
    COPL = COPL.medianFilter(5).substituteNaNs.lowPassFilter(30);
    COPR = COPR.medianFilter(5).substituteNaNs.lowPassFilter(30);
end
newData = bsxfun(@rdivide, (bsxfun(@times, COPL.Data, ...
    FL(:, 3)) + bsxfun(@times, COPR.Data, FR(:, 3))), ...
    FL(:, 3) + FR(:, 3));
COP = orientedLabTimeSeries(newData, COPL.Time(1), ...
    COPL.sampPeriod, ...
    orientedLabTimeSeries.addLabelSuffix(['COP']), ...
    COPL.orientation);
COP = COP.cat(COPL).cat(COPR);
end

