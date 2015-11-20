function [inds,names]=getEarlyLateIdxs(this,conds,numberOfStrides,exemptLast,exemptFirst)
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
		%conds: condition that information is needed 
		%numberOfStrides: vector of any size, specifying how many stride
		%cycles to group. Positive values are interpreted as 'first N'
		%strides, while negative values are interpreted as 'last N'. Zero
		%values create an empty group
		%OUTPUTS:

            if isa(conds,'char')
                conds={conds};
            elseif ~isa(conds,'cell') || ~all(cellfun(@(x) (isa(x,'char') || isa(x,'cell')),conds))
                error('adaptationData:getEarlyLateData','Conditions must be a string or a cell array containing strings.');
            end
            nConds=length(conds);
            if nargin<3 || isempty(numberOfStrides)
                numberOfStrides=[-5,20];
            end
            dataPoints=cell(size(numberOfStrides));
            if nargin<4 || isempty(exemptLast)
                Ne=5;
            else
                Ne=exemptLast; %TODO: Check that it is positive
            end
            if nargin<5 || isempty(exemptFirst)
                Nf=0;
            else
                Nf=exemptFirst; %TODO: Check that it is positive
            end

            conditionIdxs=this.getConditionIdxsFromName(conds);
            inds=cell(length(numberOfStrides),1);
            indsAux=this.getIndsInCondition(conditionIdxs);
            for j=1:length(numberOfStrides)
                inds{j}=nan(abs(numberOfStrides(j)),nConds);
                pr=[];
                switch sign(numberOfStrides(j))
                    case -1
                        pr='Last ';
                    case 2
                        pr='First ';
                end
                pr=[pr num2str(abs(numberOfStrides(j)))];
                for i=1:nConds
                    
                    names{j}{i}=[pr ' ' conds(i)];
                    %First: find if there is a condition with a
                    %similar name to the one given
                    
                    N=length(indsAux{i});
                    if numberOfStrides(j)<0 %Last N strides
                        relInds=indsAux{i}(max([N-exemptLast+numberOfStrides(j)+1,1]):N-exemptLast);
                    else %First N
                        relInds=indsAux{i}(exemptFirst+1:min([exemptFirst+numberOfStrides(j),N]));
                    end
                    inds{j}(1:length(relInds),i)=relInds; %This allows for there to exist less strides than requested
                    if length(relInds)<abs(numberOfStrides)
                        warning(['Requested ' num2str(abs(numberOfStrides)) ' but after removing the exempt ones, there are only ' num2str(length(relInds))])
                    end
                end
            end
        end