function [figHandle,veryEarlyPoints,earlyPoints,latePoints]=plotGroupedSubjects(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)
    warning('adaptationData.plotGroupedSubjects will be deprecated soon. Use plotGroupedSubjectsBars instead');
    [figHandle,veryEarlyPoints,earlyPoints,latePoints]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames);
end
