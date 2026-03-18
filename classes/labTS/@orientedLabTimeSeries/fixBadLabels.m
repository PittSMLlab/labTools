function [this, m, permuteList, modelScore, badFlag, modelScore2] = ...
    fixBadLabels(this, permuteList)
%fixBadLabels  Detects and fixes label swaps
%
%   [this, m, permuteList, modelScore, badFlag, modelScore2] =
%   fixBadLabels(this) attempts to detect and fix swapped marker labels
%
%   [this, m, permuteList, modelScore, badFlag, modelScore2] =
%   fixBadLabels(this, permuteList) applies known permutations first
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       permuteList - known label permutations to try (optional)
%
%   Outputs:
%       this - orientedLabTimeSeries with fixed labels
%       m - validated marker model
%       permuteList - permutations applied
%       modelScore - model quality score (max robust std)
%       badFlag - true if model validation failed
%       modelScore2 - alternate model score (mean robust std)
%
%   See also: buildNaiveDistancesModel, validateMarkerModel

% error('Unimplemented');
if nargin < 2
    permuteList = [];
end
aux = this;
duration = aux.timeRange;
% At least 10 secs of data with true movement for training
if duration > 10
    m = buildNaiveDistancesModel(aux);
    [badFlag, MO, OBO] = validateMarkerModel(m, false);
    bF = badFlag;
    nB = sum(MO | OBO);
    % If bad flag, will try to fix by permuting labels
    if bF
        % Trying the same fix as the last model
        if ~isempty(permuteList) && max(permuteList) <= length(MO)
            m2 = m.applyPermutation(permuteList);
            [bF, MO, OBO] = m2.validateMarkerModel(false);
        end
        if bF % Still not fully fixed
            if sum(MO | OBO) < nB % some improvement so far
                m = m2;
            else
                permuteList = nan(0, 2); % Resetting
            end
            % Searching over permutation space
            [permuteList2, m2] = m.permuteModelLabels;
            if size(permuteList2, 1) > 0
                [bF, MO, OBO] = m2.validateMarkerModel(false);
                permuteList = [permuteList; permuteList2];
            end
        end
        if sum(MO | OBO) < nB
            fprintf('Found switched labels:\n');
            auxList = {'NameA', 'NameB'};
            for i = 1:size(permuteList, 1)
                preList = m.markerLabels(permuteList(i, :));
                fprintf([preList{1} ' - ' preList{2} '\n']);
                warning('off');
                aux = aux.renameLabels(preList, auxList);
                aux = aux.renameLabels(auxList, preList([2, 1]));
                warning('on');
            end
            % Validate fix:
            m = buildNaiveDistancesModel(aux);
            [badFlag, MO, OBO] = validateMarkerModel(m, false);
            if sum(MO | OBO) >= nB
                error('orientedLabTS:fixBadLabels', ...
                    'Something went wrong: tried fixing but failed');
            else
                % Saving RELABELED data into experimentData structure
                this = aux;
            end
        end
    end

    sigma = m.getRobustStd(0.94);
    if median(sigma) < 20 % Static trial most likely
        badFlag = true;
    end
    sigma = naiveDistances.stat2Matrix(sigma);
    sigma = triu(sigma) - triu(sigma, 3);
    sigma(sigma == 0) = NaN;
    modelScore = nanmax(sigma(:));
    modelScore2 = nanmean(sigma(:));
end
end

