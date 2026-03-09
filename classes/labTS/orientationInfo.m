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
            %   orientationInfo object with the specified parameters.
            %   Input validation is enforced by property validators on
            %   assignment; see the property block for permitted values.
            %
            %   Inputs:
            %     offset      - (optional) 1x3 origin offset vector;
            %                   defaults to [0 0 0]
            %     foreaftAx   - (optional) Fore-aft axis: 'x', 'y', or 'z';
            %                   defaults to ''
            %     sideAx      - (optional) Side axis: 'x', 'y', or 'z';
            %                   defaults to ''
            %     updownAx    - (optional) Vertical axis: 'x', 'y', or 'z';
            %                   defaults to ''
            %     foreaftSign - (optional) Fore-aft sign (1 or -1);
            %                   defaults to 1
            %     sideSign    - (optional) Side sign (1 or -1);
            %                   defaults to 1
            %     updownSign  - (optional) Vertical sign (1 or -1);
            %                   defaults to 1
            %
            %   Outputs:
            %     this - orientationInfo object
            %
            %   See also: orientedLabTimeSeries

            arguments
                offset      (1,3) double = [0 0 0]
                foreaftAx   (1,:) char   = ''
                sideAx      (1,:) char   = ''
                updownAx    (1,:) char   = ''
                foreaftSign (1,1) double = 1
                sideSign    (1,1) double = 1
                updownSign  (1,1) double = 1
            end
            this.offset      = offset;
            this.foreaftAxis = foreaftAx;
            this.sideAxis    = sideAx;
            this.updownAxis  = updownAx;
            this.foreaftSign = foreaftSign;
            this.sideSign    = sideSign;
            this.updownSign  = updownSign;
        end
    end

end

