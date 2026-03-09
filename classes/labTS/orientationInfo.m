classdef orientationInfo
    % orientationInfo  Holds information about a 3-D coordinate system.
    %
    %   orientationInfo defines the orientation of a coordinate system
    % by specifying which physical directions (fore-aft, side-to-side,
    % up-down) correspond to which axes (x, y, z) and their signs.
    %
    % orientationInfo properties:
    %   offset      - 1x3 vector for coordinate system origin offset
    %   foreaftAxis - axis for fore-aft direction ('x', 'y', or 'z')
    %   foreaftSign - sign convention (1 if forward is positive)
    %   sideAxis    - axis for side-to-side direction ('x', 'y', or 'z')
    %   sideSign    - sign convention (1 if left to right is positive)
    %   updownAxis  - axis for vertical direction ('x', 'y', or 'z')
    %   updownSign  - sign convention (1 if upwards is positive)
    %
    % orientationInfo methods:
    %   orientationInfo - constructor for orientationInfo object
    %
    % See also: orientedLabTimeSeries

    %% Properties
    properties
        offset      (1,3) double = [0 0 0]
        foreaftAxis (1,:) char ...
            {mustBeMember(foreaftAxis, {'x', 'y', 'z', ''})} = ''
        foreaftSign (1,1) double ...
            {mustBeMember(foreaftSign, [1, -1])}              = 1
        sideAxis    (1,:) char ...
            {mustBeMember(sideAxis,    {'x', 'y', 'z', ''})} = ''
        sideSign    (1,1) double ...
            {mustBeMember(sideSign,    [1, -1])}              = 1
        updownAxis  (1,:) char ...
            {mustBeMember(updownAxis,  {'x', 'y', 'z', ''})} = ''
        updownSign  (1,1) double ...
            {mustBeMember(updownSign,  [1, -1])}              = 1
    end

    %% Constructor
    methods
        function this = orientationInfo(offset, foreaftAx, sideAx, ...
                updownAx, foreaftSign, sideSign, updownSign)
            % orientationInfo  Constructor for orientationInfo class.
            %
            %   this = orientationInfo() creates an orientationInfo object
            %   with default property values.
            %
            %   this = orientationInfo(offset, foreaftAx, sideAx, updownAx,
            %   foreaftSign, sideSign, updownSign) creates an
            %   orientationInfo object with specified parameters.
            %
            %   Inputs:
            %     offset      - (optional) 1x3 origin offset vector
            %     foreaftAx   - (optional) Fore-aft axis: 'x', 'y', or 'z'
            %     sideAx      - (optional) Side axis: 'x', 'y', or 'z'
            %     updownAx    - (optional) Vertical axis: 'x', 'y', or 'z'
            %     foreaftSign - (optional) Fore-aft sign (+1 or -1)
            %     sideSign    - (optional) Side sign (+1 or -1)
            %     updownSign  - (optional) Vertical sign (+1 or -1)
            %
            %   Outputs:
            %     this - orientationInfo object
            %
            %   See also: orientedLabTimeSeries

            if nargin > 0 && ~isempty(offset)
                this.offset = offset;
            end
            if nargin > 1 && ~isempty(foreaftAx) && ischar(foreaftAx)
                if ismember(foreaftAx, {'x', 'y', 'z'})
                    this.foreaftAxis = foreaftAx;
                else
                    error('OrientationInfo:Constructor', ...
                        'Axis is not one of ''x'', ''y'' or ''z''.');
                end
            end
            if nargin > 2 && ~isempty(sideAx) && ischar(sideAx)
                if ismember(sideAx, {'x', 'y', 'z'})
                    this.sideAxis = sideAx;
                else
                    error('OrientationInfo:Constructor', ...
                        'Axis is not one of ''x'', ''y'' or ''z''.');
                end
            end
            if nargin > 3 && ~isempty(updownAx) && ischar(updownAx)
                if ismember(updownAx, {'x', 'y', 'z'})
                    this.updownAxis = updownAx;
                else
                    error('OrientationInfo:Constructor', ...
                        'Axis is not one of ''x'', ''y'' or ''z''.');
                end
            end
            if nargin > 4 && ~isempty(foreaftSign)
                this.foreaftSign = foreaftSign;
            end
            if nargin > 5 && ~isempty(sideSign)
                this.sideSign = sideSign;
            end
            if nargin > 6 && ~isempty(updownSign)
                this.updownSign = updownSign;
            end
        end
    end

end

