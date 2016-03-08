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
            if nargin<2 || ~(isa(labels,'char') || (isa(labels,'cell') && all(cellfun(@(x) isa(x,'char'),labels)) ))
                error('adaptationData:getEarlyLateData','Labels must be a string or a cell array containing strings.')
            end
            if nargin<5 || isempty(numberOfStrides)
                numberOfStrides=[-5,20];
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
            if nargin<4 || isempty(removeBiasFlag) || removeBiasFlag==1
                this=this.removeBadStrides; 
                removeBiasFlag=1; %Default
            else
                %this=adaptData;
            end
            
            %this=this.removeBadStrides;
            [inds]=this.getEarlyLateIdxs(conds,numberOfStrides,exemptLast,exemptFirst);
            this=this.removeBiasV2([],removeBiasFlag);
            conditionIdxs=this.getConditionIdxsFromName(conds);
            for j=1:length(numberOfStrides)
                for i=1:nConds
                    %dataPoints{j}(i,:.:)=
                    %First: find if there is a condition with a
                    %similar name to the one given
                    condIdx=conditionIdxs(i);
                    aux=this.getParamInCond(labels,conditionIdxs(i),0); %No bias removal, it was already done
                    N=size(aux,1);
                    if ~isempty(condIdx) && ~isempty(aux)
                        data=nan(abs(numberOfStrides(j)),length(labels));
                        if numberOfStrides(j)<=0 %Last N strides
                            data(1:min([N-Ne,abs(numberOfStrides(j))]),:)=aux(max([1,end-Ne+numberOfStrides(j)+1]):end-Ne,:); %Gets the last numberOfStrides(j) strides, exempting the very last Ne, and considers the possibility that there are less strides available than requested.
                        else
                            data(1:min([N-Nf,abs(numberOfStrides(j))]),:)=aux(Nf+1:min([Nf+numberOfStrides(j),N]),:);
                        end
                        dataPoints{j}(i,1:abs(numberOfStrides(j)),:)=data;
                    else
                        disp(['Condition ' conds{i} ' not found for subject ' this.subData.ID])
                        dataPoints{j}(i,1:abs(numberOfStrides(j)),:)=NaN;
                    end
                end
            end
        end