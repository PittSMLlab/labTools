        function [figHandle,plotHandles]=plotParamBarsByConditionsv2(this,label,number,exemptLast,exemptFirst,condList,mode,plotHandles)
            %TODO: this file should be updated to call upon plotGroupedBars
           if nargin<3 || isempty(number)
                n=[5,20]; %early number of points
           else
                n=number;
           end
            if nargin<4 || isempty(exemptLast)
                Ne=5;
            else
                Ne=exemptLast;
            end
            if nargin<5 || isempty(exemptFirst)
                Nf=0;
            else
                Nf=exemptLast;
            end
            
            if nargin<8 || isempty(plotHandles) || length(label)~=length(plotHandles)
                [ah,figHandle]=optimizedSubPlot(length(label),4,1);           
            else
                ah=plotHandles;
            end
            if nargin<6 || isempty(condList)
                conds=find(~cellfun(@isempty,this.metaData.conditionName));
            else
                conds=this.getConditionIdxsFromName(condList);
                conds=conds(~isnan(conds));
            end
            nConds=length(conds);
            [dataPoints]=getEarlyLateData_v2(this,label,this.metaData.conditionName(conds),0,n,Ne,Nf);
            legStr=cell(size(n));
            for l=1:length(label)
                dd=nan(length(conds),length(dataPoints));
                ee=nan(length(conds),length(dataPoints));
                for j=1:length(dataPoints)
                    dd(:,j)=nanmean(dataPoints{j}(:,:,l),2); %Mean for each condition, along dim=2
                    ee(:,j)=nanstd(dataPoints{j}(:,:,l),[],2)/sqrt(size(dataPoints{j},2));
                    xx(:,j)=[j:(length(dataPoints)+1):(numel(dd)+length(conds))]';
                    if n(j)<0
                        legStr{j}=['Last ' num2str(-n(j)) ' strides'];
                    else
                        legStr{j}=['First ' num2str(n(j)) ' strides'];
                    end
                end

                %axes(ah(l))
                subplot(ah(l))
                hold on
                if nargin<7 ||isempty(mode)
                    mode=1;
                end
                switch mode
                    case 1
                        hBar=bar(dd);
                        drawnow %This is needed, otherwise hBar.XOffset is ill-defined on the next line
                        xb = bsxfun(@plus, hBar(1).XData, [hBar.XOffset]');
                        errorbar(xb',dd,ee,'.','LineWidth',2)
                        xTickPos=mean(xb,1);
                    otherwise
                        if length(n)>1
                        dd=[dd'; nan(length(conds),2)'];
                        ee=[ee'; nan(length(conds),2)'];
                        end
                        errorbar(dd(:),ee(:),'LineWidth',2)
                        xTickPos=[1:size(dd,1):numel(dd)] +(length(dataPoints)-1)/2;
                        legStr2=this.subData.ID;
                end
                    
                
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([label{l},' (',this.subData.ID ')'])
                hold off
            end
            switch mode
                case 1
                    legend(legStr);
                case 2
                    legend(legStr2)
            end
            plotHandles=ah;
        end
