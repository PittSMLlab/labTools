classdef processingInfo
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %bandwidth; %Needs to be a 1x2 double, represents the pass-band filter used on the raw data
        %f_cut; %Scalar, represents the cut frequency for the amplitude low-pass filter
        %notchList; %1xn double, represents the central frequencies of the notch filters applied to the raw data
        filterList
    end
    
    methods
        function this=processingInfo(filterList)
            
%             if numel(bw)==2
%                 this.bandwidth=bw;
%             else
%                 ME=MException('processingInfo:Constructor','Bandwidth is not a 1x2 double');
%                 throw(ME)
%             end
%             if numel(f_cut)==1
%                 this.f_cut=f_cut;
%             else
%                 ME=MException('processingInfo:Constructor','f_cut is not a scalar.');
%                 throw(ME)
%             end
%             if length(notchLst)==numel(notchLst)
%                 this.notchList=notchLst;
%             else
%                 ME=MException('processingInfo:Constructor','NotchList is not a 1xn double');
%                 throw(ME)
%             end
            if ~isa(filterList,'cell')
                ME=MException('processingInfo:Constructor','Filter list is not a cell array');
            end
            this.filterList=filterList;
        end
    end
    
end

