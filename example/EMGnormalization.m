%Example on how to normalize EMG parameters in an automated fashion:

%% Load adaptData object

%From here on we assume that an adaptationData object of name 'adaptData'
%exists in workspace, and contains some EMG data

%%
%Define list of muscles I care about:
mList={'TA','PER','MG','LG','SOL','BF','SEMT','SEMB','VM','VL','RF','ADM','HIP','TFL','GLU'};

%Expand list to include both sides of body, and append 's' suffix to
%clarify I want the amplitude of EMG divided in 12 phases (see
%computeEMGparameters to get the details on each EMG parameter in
%existence)
expandedMList=[strcat('f',strcat(mList,'s')) strcat('s',strcat(mList,'s'))];

%Do the normalization:
test=adaptData.normalizeToBaseline(expandedMList);

%Plot to check:
aa=test.data.getDataAsVector(test.data.getLabelsThatMatch('^Norm'));
idx=test.getIndsInCondition('TM base');
figure; surf(reshape(nanmean(aa(idx{1},:)),[12,30]),'EdgeColor','none'); caxis([-1 1]);