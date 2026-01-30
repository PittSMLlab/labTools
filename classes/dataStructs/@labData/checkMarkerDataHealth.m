function checkMarkerDataHealth(this)
%checkMarkerDataHealth  Diagnoses issues with marker data
%
%   checkMarkerDataHealth(this) analyzes marker data for
%   missing frames, gap distributions, and potential outliers.
%   Generates diagnostic plots.
%
%   Inputs:
%       this - labData object
%
%   Outputs:
%       None - generates diagnostic figures
%
%   See also: orientedLabTimeSeries

ts = this.markerData;

% First: diagnose missing markers
ll = ts.getLabelPrefix;
dd = ts.getOrientedData;
aux = zeros(size(dd, 1), size(dd, 2));
for i = 1:length(ll)
    l = ll{i};
    aux(:, i) = any(isnan(dd(:, i, :)), 3);
    if any(aux(i, :))
        warning('labData:checkMarkerDataHealth', ['Marker ' l ...
            ' is missing for ' num2str(sum(aux) * ts.sampPeriod) ' secs.']);
        for j = 1:3
            % Filling gaps just for healthCheck purposes
            dd(aux, i, j) = nanmean(dd(:, i, j));
        end
    end
end

figure;
subplot(2, 2, 1); % Missing frames as % of total
hold on;
c = sum(aux, 1) / size(aux, 1);
bar(c);
set(gca, 'XTick', 1:numel(ll), 'XTickLabel', ll, 'XTickLabelRotation', 90);
ylabel('Missing frames (%)');

subplot(2, 2, 2); % Distribution of gap lengths
hold on;
h = [];
s = {};
for i = 1:length(ll)
    if c(i) > 0.01
        w = [0; aux(:, i); 0]; % auxiliary vector
        runs_ones = find(diff(w) == -1) - find(diff(w) == 1);
        h(end + 1) = histogram(runs_ones, .5:1:50, 'DisplayName', ll{i});
        s{end + 1} = ll{i};
    end
end
legend(h, s);
title('Distribution of gap lenghts');
ylabel('Gap count');
xlabel('Gap length');
axis tight;

subplot(2, 2, 3);
hold on;
d = sum(aux, 2);
histogram(d, -.5:1:5.5, 'Normalization', 'probability');
title('Distribution of # missing in each frame');
ylabel('% of frames with missing markers');
xlabel('# missing markers');
axis tight;

% Two: create a model to determine if outliers are present
dd = permute(dd, [2, 3, 1]);
[D, sD] = createZeroModel(dd);
[lp, ~] = determineLikelihoodFromZeroModel(dd, D, sD);
subplot(2, 2, 4);
hold on;
minLike = min(lp, [], 1);
plot(minLike);
medLike = nanmedian(lp, 1);
plot(medLike, 'r');
legend(ll);
ii = find(medLike < -1);
for j = 1:length(ii)
    figure;
    plot3(dd(:, 1, ii(j)), dd(:, 2, ii(j)), dd(:, 3, ii(j)), 'o');
    text(dd(:, 1, ii(j)), dd(:, 2, ii(j)), dd(:, 3, ii(j)), ll);
    hold on;
    [~, zz] = min(lp(:, ii(j)));
    plot3(dd(zz, 1, ii(j)), dd(zz, 2, ii(j)), dd(zz, 3, ii(j)), 'ro');
    title(['median likeli = ' num2str(medLike(ii(j))) ', frame ' ...
        num2str(ii(j))]);
    pause;
end

% % Check for outliers:
% % Do a data translation:
% % refMarker = squeeze(mean(ts.getOrientedData({'LHIP','RHIP'}), 2)); % Assuming these markers exist
% % Do a label-agnostic data translation:
% refMarker = squeeze(nanmean(dd, 2));
% newTS = ts.translate([-refMarker(:, 1:2), zeros(size(refMarker, 1), 1)]); % Assuming z is a known fixed axis
% % Not agnostic rotation:
% % relData = squeeze(markerData.getOrientedData('RHIP'));
% % Label agnostic data rotation:
% newTS = newTS.alignRotate([refMarker(:, 2), -refMarker(:, 1), zeros(size(refMarker, 1), 1)], [0, 0, 1]);
% medianTS = newTS.median; % Gets the median skeleton of the markers
%
% % With this median skeleton, a minimization can be done to
% % find another label agnostic data rotation that does not
% % depend on estimating the translation velocity:
%
% % Another attempt at label agnostic rotation (not using
% % velocity, but actually some info about the skeleton
% % having Left and Right)
% % l1 = cellfun(@(x) x(1:end - 1), ts.getLabelsThatMatch('^L'), 'UniformOutput', false);
% % l2 = cellfun(@(x) x(1:end - 1), ts.getLabelsThatMatch('^R'), 'UniformOutput', false);
% % relDataOTS = newTS.computeDifferenceOTS([], [], l1(1:3:end), l2(1:3:end));
% % relData = squeeze(nanmedian(relDataOTS.getOrientedData, 2)); % Need to work on this
%
% % Try to fit a 2-cluster model, to see if some marker
% % labels are switched at some point during experiment
%
% % Assuming single mode/cluster, find outliers by getting
% % stats on distribution of positions/distance and
% % velocities.
end

