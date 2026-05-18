%TESTMARKEROUTLIERDETECTANDCORRECT Example: detect and correct marker outliers using skeleton models.
%
%   Demonstrates skeleton model learning (sk3Dlearn, skDistlearn),
% outlier detection, and MLE-based reconstruction for a missing marker.
% Uses the sample data in example/data/; LANK is missing for the first
% ~30 seconds of the trial.
%
% See also SK3DLEARN, SKDISTLEARN, SK3DDETECT, SK3DENFORCE.

%% Load data
% NOTE: This marker set is missing 'LANK' for first ~30 seconds of trial
load('./data/LI16_Trial9_expData.mat')
labels = {'LHIP' 'RHIP' 'LKNE' 'RKNE' 'LANK' 'RANK' 'LTOE' 'RTOE' ...
    'LHEE' 'RHEE' 'RASIS' 'LASIS' 'RPSIS' 'LPSIS' 'RTHI' 'LTHI' ...
    'RSHK' 'LSHNK'};
pos = LI16_Trial9_expData.markerData.getOrientedData(labels);
pos = permute(pos, [2, 3, 1]);

%% Generate dummy data (alternative to loading real data)
% pos = 10 * randn(54, 5) * randn(5, 1000) + randn(54, 1000);
% pos = reshape(pos, 18, 3, 1000);

%% Learn skeleton from a reliable segment (200–220 s)
% NOTE: sk3Dlearn does not work well with OG (overground) data.
[m, R]    = sk3Dlearn(pos(:, :, 20000:22000));
[md, Rd]  = skDistlearn(pos(:, :, 20000:22000));

%% Detect bad markers using skeleton
scores  = sk3Ddetect(pos, m, R);
scoresD = skDistdetect(pos, md, Rd);
figure;
plot(scores(5, :)');
legend(labels);
hold on;
plot(scoresD(5, :)');

%% Set up MLE reconstruction for missing LANK marker
[N, D, M] = size(pos);
P = 0.1 * eye(N * D);  % isotropic marker position uncertainty

% Simulate LANK completely missing.
idx  = find(strcmp(labels, 'LANK'));
pos2 = pos;
pos2(idx, :, :) = NaN;

%% Reconstruct missing marker via MLE
% Large covariance inflation models a completely unknown marker.
M1    = M;
xMLE  = nan(N * D, M1);
xMLEd = nan(N * D, M1);
for ii = 1:M1
    xMLE(:,ii) = sk3Denforce(pos2(:,:,ii), P, m(:), ...
        R + 1e3 * abs(max(R(:))) * [eye(N) eye(N) eye(N)]);
    xMLEd(:,ii) = skDistenforce(pos2(:,:,ii), P, md(:), ...
        Rd + 1e3 * abs(max(Rd(:))) * eye(N));
end
xMLE = reshape(xMLE, N, D, M1);
% xMLEd = reshape(xMLEd, N, D, M1);

%% Compare detection scores before and after correction
correctedScores = sk3Ddetect(xMLE, m, R);
figure;
plot(scores(5, :));
hold on;
plot(correctedScores(5, :), 'LineWidth', 4);

%% Plot reconstructed vs. original positions
pos(idx, :, 1:10000) = NaN;  % known bad samples
figure;
for ii = 1:3
    subplot(3, 3, 3 * (ii - 1) + (1:2))
    plot(squeeze(xMLE(idx, ii, :)))
    hold on
    plot(squeeze(pos(idx, ii, :)))
    if ii == 1
        title('Reconstruction values')
    elseif ii == 3
        xlabel('Time (s)')
    end
    ylabel([('x' + ii - 1) ' (mm)']);

    subplot(3, 3, 3 * ii)
    dd = squeeze(xMLE(idx, ii, :) - pos(idx, ii, :));
    histogram(dd, -20:1:20)
    if ii == 1
        title('Histogram of errors')
    elseif ii == 3
        xlabel('Error (mm)')
    end
    hold on
    text(-19, 1500, ['\mu=' num2str(mean(dd, 'omitnan'), 2)])
    text(-19, 1000, ['\sigma=' num2str(std(dd, 'omitnan'), 2)])
    text(-19, 500, ['m=' num2str(median(dd, 'omitnan'), 2)])
end

%% Compare mean positions (notice change in LANK position)
auxPos    = mean(pos(:,:,1:M1), 3, 'omitnan');
auxNewPos = mean(xMLE(:,:,1:M1), 3, 'omitnan');
figure;
plot3(auxPos(:,1), auxPos(:,2), auxPos(:,3), 'x');
hold on;
plot3(auxNewPos(:,1), auxNewPos(:,2), auxNewPos(:,3), 'o');
axis equal

%% Compute reconstruction error
xMLE = reshape(xMLE, N, D, M);
err  = xMLE - pos;
imagesc(mean(err, 3))
