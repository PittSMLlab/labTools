function mov = animate2(this, t0, t1, frameRate, writeFileFlag, ...
    filename, mode)
%animate2  Creates animation with balloon model
%
%   mov = animate2(this, t0, t1, frameRate, writeFileFlag, filename,
%   mode) renders movie of 3D marker positions
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       t0 - start time (optional, default: beginning)
%       t1 - end time (optional, default: end)
%       frameRate - frames per second (optional, default: 25)
%       writeFileFlag - if 1, writes to file (optional, default: 0)
%       filename - output filename (optional, auto-generated)
%       mode - visualization mode: 1 (lines) or 2 (balloon) (optional,
%              default: 2)
%
%   Outputs:
%       mov - video writer object if writing to file
%
%   Note: Only makes sense for markerData type objects
%
%   See also: animate, plot3

% This function renders a movie of the 3-D position stored in the
% orientedLabData object. It only makes sense for markerData type
% objects.

if nargin < 2 || isempty(t0) || isempty(t1)
    t0 = this.Time(1);
    t1 = this.Time(end);
end
if nargin < 7 || isempty(mode)
    mode = 2;
end
if nargin < 5 || isempty(writeFileFlag)
    writeFileFlag = 0;
end
if nargin < 4 || isempty(frameRate)
    frameRate = 25;
end
if nargin < 6 || isempty(filename)
    filename = ['anim_t=[' num2str(round(t0 * 10) / 10) ',' ...
        num2str(round(t1 * 10) / 10) '].avi'];
end
f = round(this.sampFreq / frameRate);
frameRate = this.sampFreq / f;
this = this.split(t0, t1); % Keeping the requested data only

if writeFileFlag == 1

    % mov = VideoWriter(filename, 'Archival');
    mov = VideoWriter(filename, 'Uncompressed AVI');
    mov.FrameRate = frameRate;
    % mov.Quality = 100;
    open(mov);
end

list = {'TOE', 'HEE', 'HEEL', 'ANK', 'SHANK', 'TIB', 'KNE', 'KNEE', ...
    'THI', 'THIGH', 'HIP', 'GT', 'ASI', 'ASIS', 'PSI', 'PSIS'};
[b, ~] = this.isaLabelPrefix(strcat('L', list));
list = list(b);
ll = this.getOrientedData(unique(cellfun(@(x) x(1:end - 1), ...
    this.getLabelsThatMatch('^L'), 'UniformOutput', false)));
ll = this.getOrientedData(strcat('L', list));
rr = this.getOrientedData(unique(cellfun(@(x) x(1:end - 1), ...
    this.getLabelsThatMatch('^R'), 'UniformOutput', false)));
rr = this.getOrientedData(strcat('R', list));
dd = this.getOrientedData;
fh = figure;
h_axes = gca;
% drawnow limitrate
% u = uicontrol('Style', 'slider', 'Position', [10 50 20 340], 'Min',
%     1, 'Max', size(ll, 1), 'Value', 1);


axis equal;
axis([min(min(dd(:, :, 1))) - 50 max(max(dd(:, :, 1))) + 50 ...
    min(min(dd(:, :, 2))) - 50 max(max(dd(:, :, 2))) + 50 ...
    min(min(dd(:, :, 3))) - 50 max(max(dd(:, :, 3))) + 900]);
view(90, 0);
hold on;
switch mode
    case 1
        % Option 1: plain lines

        L = animatedline(ll(1, :, 1), ll(1, :, 2), ll(1, :, 3), ...
            'Marker', 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'r');
        R = animatedline(rr(1, :, 1), rr(1, :, 2), rr(1, :, 3), ...
            'Marker', 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'b');
        % set(gca, 'NextPlot', 'replacechildren')
        for k = 1:f:size(ll, 1)
            %
            % hold on
            % axes(ax)
            clearpoints(L);
            addpoints(L, ll(k, :, 1), ll(k, :, 2), ll(k, :, 3));
            clearpoints(R);
            addpoints(R, rr(k, :, 1), rr(k, :, 2), rr(k, :, 3));
            % hold off
            % u.Value = k;
            M(k) = getframe(gcf);
        end

    case 2
        % set mannequin color
        color = [0.2 0.2 0.2]; % gray
        % Option 2: balloon cartoon (GTO style)
        for k = 1:f:size(ll, 1)
            cla;
            for side = 1:2 % For each side
                switch side
                    case 1
                        s = rr; % Right side
                        colorLegs = [0 160 198] / 255;
                    case 2
                        s = ll; % Left side
                        colorLegs = [255 153 0] / 255;
                end
                for seg = 1:3
                    switch seg
                        case 1
                            ind1 = 1; % Toe
                            ind2 = 3; % Ank
                            radius = [1 .5 .5];
                        case 2
                            ind1 = 3; % Ank
                            ind2 = 5; % Knee
                            radius = [1 .25 .25];
                        case 3
                            ind1 = 5; % Knee
                            ind2 = 7; % hip
                            radius = [1 .35 .35];
                    end
                    X = s(k, [ind1 ind2], 1);
                    Y = s(k, [ind1 ind2], 2);
                    Z = s(k, [ind1 ind2], 3);
                    orientedLabTimeSeries.drawsegment(h_axes, X, Y, Z, ...
                        radius, colorLegs);
                end
                % draw hip joints
                X = s(k, 7, 1);
                Y = s(k, 7, 2);
                Z = s(k, 7, 3);
                orientedLabTimeSeries.drawball(h_axes, X, Y, Z, 50, ...
                    color);
                % draw shoulder joints: using hip data by default
                X = s(k, 7, 1);
                Y = s(k, 7, 2);
                Z = s(k, 7, 3) + 530;
                orientedLabTimeSeries.drawball(h_axes, X, Y, Z, 50, ...
                    color);
            end
            % Draw pelvis
            X = [rr(k, 7, 1) ll(k, 7, 1)];
            Y = [rr(k, 7, 2) ll(k, 7, 2)];
            Z = [rr(k, 7, 3) ll(k, 7, 3)];
            orientedLabTimeSeries.drawsegment(h_axes, X, Y, Z, ...
                [1 .4 .4], color);
            % Draw shoulder
            X = [rr(k, 7, 1) ll(k, 7, 1)];
            Y = [rr(k, 7, 2) ll(k, 7, 2)];
            Z = [rr(k, 7, 3) ll(k, 7, 3)] + 530;
            orientedLabTimeSeries.drawsegment(h_axes, X, Y, Z, ...
                [1 .35 .35], color);
            % Draw torso
            X = .5 * (rr(k, 7, 1) + ll(k, 7, 1)) + [0 0];
            Y = .5 * (rr(k, 7, 2) + ll(k, 7, 2)) + [0 0];
            % Fake torso height
            Z = .5 * (rr(k, 7, 3) + ll(k, 7, 3)) + [0 500];
            orientedLabTimeSeries.drawsegment(h_axes, X, Y, Z, ...
                [1 .4 .4], color);
            % Draw head
            X = .5 * (rr(k, 7, 1) + ll(k, 7, 1)) + [0 0];
            Y = .5 * (rr(k, 7, 2) + ll(k, 7, 2)) + [0 0];
            % Fake head height
            Z = .5 * (rr(k, 7, 3) + ll(k, 7, 3)) + 500 + [60 360];
            orientedLabTimeSeries.drawsegment(h_axes, X, Y, Z, ...
                [1 .75 .75], color);

            % Save frame
            camlight headlight;
            set(findobj(gca, 'type', 'surface'), ...
                'FaceLighting', 'gouraud', ...
                'AmbientStrength', .3, ...
                'DiffuseStrength', .8, ...
                'SpecularStrength', .8, ...
                'SpecularExponent', 25, ...
                'BackFaceLighting', 'reverselit');
            currFrame = getframe;
            if writeFileFlag == 1
                writeVideo(mov, currFrame);
            end
        end
end
hold off;
if writeFileFlag == 1
    close(mov);
end
end

