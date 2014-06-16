classdef orientationInfo
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        offset=0; %Should be 1x3 for vector data;
        foreaftAxis=''; %Either 'x', 'y' or 'z' (NO caps!)
        foreaftSign=1; % Should be 1 if forward is positive;
        sideAxis='';
        sideSign=1; %should be 1 if left to right is positive;
        updownAxis='';
        updownSign=1; %Should be 1 if upwards is positive;
    end
    
    methods
        function this=orientationInfo(offset,foreaftAx,sideAx,updownAx,foreaftSign,sideSign,updownSign)
           if nargin>0 && ~isempty(offset)
               this.offset=offset;
           end
           if nargin>1 && ~isempty(foreaftAx) && isa(foreaftAx,'char')
               if strcmp(foreaftAx,'x') || strcmp(foreaftAx,'y') || strcmp(foreaftAx,'z')
                    this.foreaftAxis=foreaftAx;
               else
                   error('OrientationInfo:Constructor','Axis is not one of ''x'', ''y'' or ''z''.')
               end
           end
           if nargin>2 && ~isempty(sideAx) && isa(sideAx,'char')
               if strcmp(sideAx,'x') || strcmp(sideAx,'y') || strcmp(sideAx,'z')
                    this.sideAxis=sideAx;
               else
                   error('OrientationInfo:Constructor','Axis is not one of ''x'', ''y'' or ''z''.')
               end
           end
           if nargin>3 && ~isempty(updownAx) && isa(updownAx,'char')
               if strcmp(updownAx,'x') || strcmp(updownAx,'y') || strcmp(updownAx,'z')
                    this.updownAxis=updownAx;
               else
                   error('OrientationInfo:Constructor','Axis is not one of ''x'', ''y'' or ''z''.')
               end
           end
           if nargin>4 && ~isempty(foreaftSign)
               this.foreaftSign=foreaftSign;
           end
           if nargin>5 && ~isempty(sideSign)
               this.sideSign=sideSign;
           end
           if nargin>6 && ~isempty(updownSign)
               this.updownSign=updownSign;
           end
        end
    end
    
end

