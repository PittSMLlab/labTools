function [dataPoints]=getEarlyLateData_v2(this,labels,conds,removeBiasFlag,numberOfStrides,exemptLast,exemptFirst)
        %obtain the earliest and late data points for conditions
		%allow to eliminate very late data points 
		%Predefine values:  
		%earlyNumber=5
		%veryEarlyPoints=3
		%latePoints=20
		%exemptLast=5
        %exemptFirst=0
		%
		%INPUTS:
		%this:experimentData object 
		%labels: parameters to plot 
		%conds: condition that information is needed 
		%removeBiasFlag:1 to activate function to remove bias, 0 or empty to no activate function
		%numberOfStrides: vector of any size, specifying how many stride
		%cycles to group. Positive values are interpreted as 'first N'
		%strides, while negative values are interpreted as 'last N'. Zero
		%values create an empty group
		%OUTPUTS:
		%dataPoints: cell array with the requested data.
		%
		%EX:[veryEarlyPoints,earlyPoints,latePoints]=adaptData.getEarlyLateData({'Sout'},{'TM base'},1,5,40,5);
		
			earlyPoints=[];
            veryEarlyPoints=[];
            latePoints=[];
            N1=3;%all(cellfun(@(x) isa(x,'char'),conds))
            if isa(conds,'char')
                conds={conds};
            elseif ~isa(conds,'cell') || ~all(cellfun(@(x) (isa(x,'char') || isa(x,'cell')),conds))
                error('adaptationData:getEarlyLateData','Conditions must be a string or a cell array containing strings.');
            end
            nConds=length(conds);
            if nargin<2 
                labels=[]; %Empty labels interpreted as ALL labels down-stream
            elseif ~isempty(labels) && ( ~(isa(labels,'char') || (isa(labels,'cell') && all(cellfun(@(x) isa(x,'char'),labels)) )))
                error('adaptationData:getEarlyLateData','Labels must be a string or a cell array containing strings.')
            end
            if nargin<5 || isempty(numberOfStrides)
                numberOfStrides=[5,-20]; %First 5 and last 20
            end
            dataPoints=cell(size(numberOfStrides));
            if nargin<6 || isempty(exemptLast)
                Ne=5;
            else
                Ne=exemptLast;
            end
            if nargin<7 || isempty(exemptFirst)
                Nf=0;
            else
                Nf=exemptFirst;
            end
            if nargin<4 || isempty(removeBiasFlag) 
                removeBiasFlag=1; %Default, bias removal
            else
                %this=adaptData;
            end
            
            %this=this.removeBadStrides; %Should this be default? Pablo: I don't think we should be changing the # of strides in the middle of a request for data.
            [inds]=this.getEarlyLateIdxs(conds,numberOfStrides,exemptLast,exemptFirst);
            switch removeBiasFlag
                case 1
                    this=this.removeBias;
                case 2
                    this=this.normalizeBias;
                case 0
                    %nop
                otherwise
                    error('Unexpected value for removeBiasFlag')
            end
            dataPoints=this.getDataFromInds(inds,labels);
        end