function [this, iC, iI] = flipLR(this)
%flipLR  Flips left/right alignment
%
%   [this, iC, iI] = flipLR(this) flips the non-aligned side to match
%   aligned side timing
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       this - flipped alignedTimeSeries
%       iC - indices of contralateral (flipped) labels
%       iI - indices of ipsilateral (aligned) labels
%
%   Note: Finds side with starting event and flips the other side
%
%   See also: getSym, getaSym, fftshift

% Find the side that has the starting event:
alignedSide = this.alignmentLabels{1}(1);
nonAlignedSide = getOtherLeg(alignedSide);
% Flip non-aligned side:
lC = this.getLabelsThatMatch(['^' nonAlignedSide]); % Get non-aligned
if ~isempty(lC)
    [~, iC] = this.isaLabel(lC); % Index for non-aligned
    % Getting aligned side labels
    aux = regexprep(lC, ['^' nonAlignedSide], alignedSide);
    [bI, iI] = this.isaLabel(aux); % Index for aligned
    if ~all(bI) % Labels are not symm, aborting
        warning(['Asked to flipLR but labels are not ' ...
            'symmetrically present.']);
    else
        % This just flips first and second halves of aligned data, no
        % checks performed
        this.Data(:, iC) = fftshift(this.Data(:, iC), 1);
        this.alignmentLabels = regexprep(this.alignmentLabels, ...
            ['^' alignedSide], 'i');
        this.alignmentLabels = regexprep(this.alignmentLabels, ...
            ['^' nonAlignedSide], 'c');
    end
else
    warning('Asked to flipLR but couldn''t find aligned side.');
    iC = [];
end
end

