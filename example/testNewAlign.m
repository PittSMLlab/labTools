%Test new align

%% Load some labTS & events
labTS=expData.data{7}.markerData;
eveTS=expData.data{7}.gaitEvents;
%% Compute the two alignments:
tic; [ATS1,bad1]=labTS.align(eveTS,{'RHS','LTO','LHS','RTO'},[24,76,24,76]); toc; %80s
tic; [ATS2,bad2]=labTS.align_v2(eveTS,{'RHS','LTO','LHS','RTO'},[24,76,24,76]); toc; %0.2s

%% Plot differences in results:
figure; plot(nanmean(ATS2.Data-ATS1.Data,3))

%% Plot differences to actual labTS
idx=1;
figure; hold on;
plot(labTS.Time,labTS.Data(:,idx),'bx')
expEventTimes1=ATS1.expandedEventTimes;
expEventTimes2=ATS2.expandedEventTimes;
% for j=1:size(eventTimes,1)-1 %Strides
% expEventTimes2(j,:)=interp1([1 cumsum(ATS2.alignmentVector)+1],[eventTimes(j,:) eventTimes(j+1,1)],1:sum(ATS2.alignmentVector));
% expEventTimes1(j,:)=interp1([0 cumsum(ATS1.alignmentVector)],[eventTimes(j,:) eventTimes(j+1,1)],1:sum(ATS2.alignmentVector));
% end
plot(expEventTimes2,squeeze(ATS2.Data(:,idx,:)),'r')
plot(expEventTimes1,squeeze(ATS1.Data(:,idx,:)),'k')

%% Quantify differences in results:

norm(ATS2.Data(:)-ATS1.Data(:))/numel(ATS2.Data)