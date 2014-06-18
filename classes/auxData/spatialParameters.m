classdef spatialParameters
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        swingAmpL=0; %Distance of left ankle from LTO until next LHS, relative to hip
        swingAmpR=0; %Distance of right ankle from RTO until next RHS, relative to hip
        placeL=0; %Left ankle placement at LHS, relative to hip
        placeR=0; %Right ankle placement at RHS, relative to hip
        stepAmpL=0; %Distance from left ankle to right ankle at LHS
        stepAmpR=0; %Distance from right ankle to left ankle at RHS
        takeOffL=0; %Left ankle placement at LTO, relative to hip
        takeOffR=0; %Right ankle placement at RTO, relative to hip
        bad=0;
    end
    
    methods
        %Constructor:
        function this=spatialParameters(gaitEvents,markerData)
            %To Do!
        end
    end
    
end

