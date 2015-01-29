function [h] = procEMGhealthCheck(procExperimentData)

signalBW=[20,450];
colors={[1,0,0],[0,0,1],[0,.6,.3],[.7,.7,.7]};

for trial=1:length(procExperimentData.data)
    if ~isempty(procExperimentData.data{trial})
        %Visual check:
        data=procExperimentData.data{trial}.procEMGData;
        N=size(data.Data,2);
        h(trial)=figure(trial);
        set(h(trial),'units','Normalized','OuterPosition',[0,0,1,1]);
        k=4;
        legInds=zeros(ceil(N/k),mod(N-1,k)+1);
        legLabs=zeros(ceil(N/k),mod(N-1,k)+1);
        for j=1:N
            sp=ceil(j/k);
            M=mod(j-1,k)+1;
            hh(sp)=subplot(ceil(N/8),2,sp);
            hold on
            a=plot(data.Time,data.Data(:,j),'LineWidth',2,'Color',colors{M});
            legInds(sp,M)=a;
            legLabs(sp,M)=j;
            if M==k || j==N
                legend(legInds(sp,legLabs(sp,:)>0),data.labels{legLabs(sp,legLabs(sp,:)>0)})
            end
            hold off
            
        end
        linkaxes(hh,'x')
        %uiwait(h(trial))
    end
end





end

