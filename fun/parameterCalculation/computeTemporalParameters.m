function [out] = computeTemporalParameters(strideEvents)
%%
timeSHS=strideEvents.tSHS;
timeFTO=strideEvents.tFTO;
timeFHS=strideEvents.tFHS;
timeSTO=strideEvents.tSTO;
timeSHS2=strideEvents.tSHS2;
timeFTO2=strideEvents.tFTO2;
%% Labels and descriptions:
aux={'swingTimeSlow',            'time from STO to SHS2 (in s)';...
    'swingTimeFast',            'time from FTO to FHS (in s)';...
    'stanceTimeSlow',           'time from SHS to STO (in s)';...
    'stanceTimeFast',           'time from FHS to FTO2 (in s)';... %Fixed description on 7/15/15
    'doubleSupportSlow',        'time from FHS to STO (in s)';...
    'doubleSupportFast',        'time from SHS2 to FTO2 (in s)';... %Fixed description on 7/15/15
    'doubleSupportTemp',        'time from SHS to FTO (in s)';...
    'stepTimeSlow',             'time from FHS to SHS2 (in s)';...
    'stepTimeFast',             'time from SHS to FHS (in s)';...
    'toeOffSlow',               'time from STO to FTO2 (in s)';...
    'toeOffFast',               'time from FTO to STO (in s)';...
    'strideTimeSlow',           'time from SHS to SHS2 (in s)';...
    'strideTimeFast',           'time from FTO to FTO2 (in s)';...
    'cadenceSlow',              '1/strideTimeSlow (in Hz)';...
    'cadenceFast',              '1/strideTimeFast (in Hz)';...
    'stepCadenceSlow',          '1/stepTimeSlow (in Hz)';...
    'stepCadenceFast',          '1/stepTimeFast (in Hz)';...
    'doubleSupportPctSlow',     '(doubleSupportSlow/strideTimeSlow)*100';...
    'doubleSupportPctFast',     '(doubleSupportFast/strideTimeFast)*100';...
    'doubleSupportDiff',        'doubleSupportSlow-doubleSupportFast (in s)';...    
    'stepTimeDiff',             'stepTimeFast-stepTimeSlow (in s)';...
    'stanceTimeDiff',           'stanceTimeSlow-stanceTimeFast (in s)';...
    'swingTimeDiff',            'swingTimeFast-swingTimeSlow (in s)';...
    'doubleSupportAsym',        '(doubleSupportPctFast-doubleSupportPctSlow)/(doubleSupportPctFast+doubleSupportPctSlow)';...
    'Tout',                     'stepTimeDiff/strideTimeSlow';...
    'Tgoal',                    'stanceTimeDiff/strideTimeSlow';...
    'TgoalSW',                  'swingTimeDiff/strideTimeSlow (should be same as Tgoal)'};

paramLabels=aux(:,1);
description=aux(:,2);

%% Compute:
       
        %%% intralimb
        
        %swing times
        swingTimeSlow=timeSHS2-timeSTO;
        swingTimeFast=timeFHS-timeFTO;
        %stance times
        stanceTimeSlow=timeSTO-timeSHS;
        stanceTimeFast=timeFTO2-timeFHS;
        %double support times
        doubleSupportSlow=timeSTO-timeFHS;
        doubleSupportTemp=timeFTO-timeSHS;
        doubleSupportFast=timeFTO2-timeSHS2; %PAblo: changed on 11/11/2014 to use the second step instead of the first one, so stance time= step time + double support time with the given indexing.
        %step times (time between heel strikes)
        stepTimeSlow=timeSHS2-timeFHS;
        stepTimeFast=timeFHS-timeSHS;
        %time betwenn toe offs
        toeOffSlow=timeFTO2-timeSTO;
        toeOffFast=timeSTO-timeFTO;
        %stride times
        strideTimeSlow=timeSHS2-timeSHS;
        strideTimeFast=timeFTO2-timeFTO;
        %cadence (stride cycles per s)
        cadenceSlow=1./strideTimeSlow;
        cadenceFast=1./strideTimeFast;
        %step cadence (steps per s)
        stepCadenceSlow=1./stepTimeSlow;
        stepCadenceFast=1./stepTimeFast;
        %double support percent
        doubleSupportPctSlow=doubleSupportSlow./strideTimeSlow*100;
        doubleSupportPctFast=doubleSupportFast./strideTimeFast*100;
        
        %%% interlimb
        %note: the decision on Fast-Slow vs Slow-Fast was made based on how
        %the parameter looks when plotted.
        doubleSupportDiff=doubleSupportSlow-doubleSupportFast;
        stepTimeDiff=stepTimeFast-stepTimeSlow;
        stanceTimeDiff=stanceTimeSlow-stanceTimeFast;
        swingTimeDiff=swingTimeFast-swingTimeSlow;
        doubleSupportAsym=(doubleSupportPctFast-doubleSupportPctSlow)./(doubleSupportPctFast+doubleSupportPctSlow);
        Tout=(stepTimeDiff)./strideTimeSlow;
        Tgoal=(stanceTimeDiff)./strideTimeSlow;
        TgoalSW=(swingTimeDiff)./strideTimeSlow;

%% Assign parameters to data matrix
data=nan(length(timeSHS),length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Create parameterSeries
out=parameterSeries(data,paramLabels,[],description);        

end

