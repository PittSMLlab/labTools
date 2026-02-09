function newThis = cat(this, other, dim, forceFlag)
%cat  Concatenates alignedTimeSeries
%
%   newThis = cat(this, other) concatenates strides (dim = 3)
%
%   newThis = cat(this, other, dim, forceFlag) concatenates along
%   specified dimension with optional force flag
%
%   Inputs:
%       this - alignedTimeSeries object
%       other - alignedTimeSeries to concatenate
%       dim - dimension: 2 (labels) or 3 (strides) (optional, default:
%             3)
%       forceFlag - if true, ignores label/alignment mismatches
%                   (optional, default: false)
%
%   Outputs:
%       newThis - concatenated alignedTimeSeries
%
%   Note: Cat-ting strides loses consecutive event timing
%
%   See also: getPartialStridesAsATS, getPartialDataAsATS

if nargin < 4
    forceFlag = false;
end
if nargin < 3 || isempty(dim)
    dim = 3; % Cat-ting strides
end

% Check alignment vectors coincide & alignment labels coincide
if any(this.alignmentVector ~= other.alignmentVector)
    ME = MException('ATS:cat', 'Alignment vector mismatch');
    throw(ME);
end
if ~forceFlag && ~all(strcmp(this.alignmentLabels, ...
        other.alignmentLabels))
    ME = MException('ATS:cat', ['Alignment labels mismatch, this check '...
        'can be ignored by setting forceFlag = true']);
    throw(ME);
end

if dim == 3
    % Check dimensions coincide
    s1 = size(this.Data);
    s2 = size(other.Data);
    if any(s1(1:2) ~= s2(1:2))
        ME = MException('ATS:cat', 'Data dimension mismatch.');
        throw(ME);
    end

    % Check labels coincide (unless forced)
    if ~forceFlag && ~all(strcmp(this.labels, other.labels))
        ME = MException('ATS:cat', ['Label mismatch, this check can be '...
            'ignored by setting forceFlag = true']);
        throw(ME);
    end

    % Do the cat:
    newThis = alignedTimeSeries(this.Time(1), diff(this.Time(1:2)), ...
        cat(3, this.Data, other.Data), this.labels, ...
        this.alignmentVector, this.alignmentLabels, ...
        cat(2, this.eventTimes(:, 1:end - 1), other.eventTimes));
    warning('ATS:catStridesLostEvents', ['Cat-ting strides of ' ...
        'alignedTimeSeries, events are no longer consecutive.']);
elseif dim == 2 % Cat-ting labels
    % Check dimensions coincide
    s1 = size(this.Data);
    s2 = size(other.Data);
    if any(s1([1, 3]) ~= s2([1, 3]))
        ME = MException('ATS:cat', 'Data dimension mismatch.');
        throw(ME);
    end
    % Check no repeated labels

    % Check alignmentVector & Labels

    % Check that all eventTimes match
    if any(size(this.eventTimes) ~= size(other.eventTimes)) || ...
            any(abs(this.eventTimes(:) - other.eventTimes(:)) > 1e-9)
        ME = MException('ATS:cat', ['Trying to cat labels, but event ' ...
            'times are different']);
        throw(ME);
    end

    % Do the cat
    newThis = alignedTimeSeries(this.Time(1), diff(this.Time(1:2)), ...
        cat(2, this.Data, other.Data), [this.labels, other.labels], ...
        this.alignmentVector, this.alignmentLabels, this.eventTimes);
else
    ME = MException('ATS:cat', 'Invalid dimension for concatenation');
    throw(ME);
end
end

