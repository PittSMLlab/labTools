classdef orientationInfo
    %orientationInfo  Holds information about a three-dimensional
    %coordinate system
    %
    %   orientationInfo defines the orientation of a coordinate system by
    %   specifying which physical directions (fore-aft, side-to-side,
    %   up-down) correspond to which axes (x, y, z) and their signs.
    %
    %orientationInfo properties:
    %   offset - 1x3 vector for coordinate system origin offset
    %   foreaftAxis - axis for fore-aft direction ('x', 'y', or 'z')
    %   foreaftSign - sign convention (1 if forward is positive)
    %   sideAxis - axis for side-to-side direction ('x', 'y', or 'z')
    %   sideSign - sign convention (1 if left to right is positive)
    %   updownAxis - axis for vertical direction ('x', 'y', or 'z')
    %   updownSign - sign convention (1 if upwards is positive)
    %
    %orientationInfo methods:
    %   orientationInfo - constructor for orientation info
    %
    %See also: orientedLabTimeSeries

    %% Properties
    properties
        offset = 0; % Should be 1x3 for vector data
        foreaftAxis = ''; % Either 'x', 'y' or 'z' (NO caps!)
        foreaftSign = 1; % Should be 1 if forward is positive
        sideAxis = '';
        sideSign = 1; % should be 1 if left to right is positive
        updownAxis = '';
        updownSign = 1; % Should be 1 if upwards is positive
    end

    %% Constructor
    methods
        function this = orientationInfo(offset, foreaftAx, sideAx, ...
                updownAx, foreaftSign, sideSign, updownSign)
            %orientationInfo  Constructor for orientationInfo class
            %
            %   this = orientationInfo() creates orientation info with
            %   default values
            %
            %   this = orientationInfo(offset, foreaftAx, sideAx,
            %   updownAx, foreaftSign, sideSign, updownSign) creates
            %   orientation info with specified parameters
            %
            %   Inputs:
            %       offset - 1x3 vector for origin offset (optional)
            %       foreaftAx - axis for fore-aft, 'x', 'y', or 'z'
            %                   (optional)
            %       sideAx - axis for side-to-side, 'x', 'y', or 'z'
            %                (optional)
            %       updownAx - axis for up-down, 'x', 'y', or 'z'
            %                  (optional)
            %       foreaftSign - sign for fore-aft (+1 or -1) (optional)
            %       sideSign - sign for side-to-side (+1 or -1) (optional)
            %       updownSign - sign for up-down (+1 or -1) (optional)
            %
            %   Outputs:
            %       this - orientationInfo object
            %
            %   See also: orientedLabTimeSeries

            if nargin > 0 && ~isempty(offset)
                this.offset = offset;
            end
            if nargin > 1 && ~isempty(foreaftAx) && isa(foreaftAx, 'char')
                if strcmp(foreaftAx, 'x') || strcmp(foreaftAx, 'y') || ...
                        strcmp(foreaftAx, 'z')
                    this.foreaftAxis = foreaftAx;
                else
                    error('OrientationInfo:Constructor', ...
                        'Axis is not one of ''x'', ''y'' or ''z''.');
                end
            end
            if nargin > 2 && ~isempty(sideAx) && isa(sideAx, 'char')
                if strcmp(sideAx, 'x') || strcmp(sideAx, 'y') || ...
                        strcmp(sideAx, 'z')
                    this.sideAxis = sideAx;
                else
                    error('OrientationInfo:Constructor', ...
                        'Axis is not one of ''x'', ''y'' or ''z''.');
                end
            end
            if nargin > 3 && ~isempty(updownAx) && isa(updownAx, 'char')
                if strcmp(updownAx, 'x') || strcmp(updownAx, 'y') || ...
                        strcmp(updownAx, 'z')
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

