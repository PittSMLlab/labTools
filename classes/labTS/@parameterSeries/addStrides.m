function newThis = addStrides(this, other)
%addStrides  Adds strides from another parameterSeries
%
%   newThis = addStrides(this, other) concatenates strides from two
%   parameterSeries, handling mismatched parameter lists
%
%   Inputs:
%       this - parameterSeries object
%       other - parameterSeries object to add
%
%   Outputs:
%       newThis - combined parameterSeries
%
%   Note: If parameter lists don't match, merges lists and fills NaN
%         for missing parameters. You should fix this issue.
%
%   See also: cat, appendData

% TODO: Check that the labels are actually the same
if ~isempty(other.Data)
    aux = other.getDataAsVector(this.labels);
    if size(this.Data, 2) == size(other.Data, 2)
        newThis = parameterSeries([this.Data; aux], this.labels(:), ...
            [this.hiddenTime; other.hiddenTime], this.description(:));
    else
        warning('parameterSeries:addStrides', ...
            ['Concatenating parameterSeries with different number ' ...
            'of parameters. Merging parameter lists & filling NaNs ' ...
            'for missing parameters. You (yes, YOU, the current ' ...
            'user) SHOULD FIX THIS. Ask Pablo for guidance.']);
        % Labels present in other but NOT in this
        bool2 = compareLists(this.labels, other.labels);
        % Labels present in this but NOT in other
        bool1 = compareLists(other.labels, this.labels);
        if any(~bool2)
            % Expanding this
            newThis = this.appendData(...
                nan(size(this.Data, 1), sum(~bool2)), ...
                other.labels(~bool2), other.description(~bool2));
        else
            newThis = this; % digna added this, review
        end
        if any(~bool1)
            % Expanding other
            newOther = other.appendData(...
                nan(size(other.Data, 1), sum(~bool1)), ...
                this.labels(~bool1), this.description(~bool1));
        else
            newOther = other; % Digna added this, review
        end
        newThis = addStrides(newThis, newOther);
    end
else
    newThis = this; % Empty second arg., adding nothing.
end
end

