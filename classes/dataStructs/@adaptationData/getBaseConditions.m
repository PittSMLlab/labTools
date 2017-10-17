function [baseConds,trialTypes]=getBaseConditions(this,trialType)
  if nargin<2
  trialTypes=this.trialTypes; %Pablo added this on 5/18 and a function in adaptationData that makes this code back compatible
  types=unique(trialTypes(~cellfun(@isempty,trialTypes)));
else
  types=trialType;
end
  for itype=1:length(types)
      allTrials=find(strcmp(this.trialTypes,types{itype}));
      [baseCond]=this.metaData.getConditionsThatMatch('base',types{itype});
      if length(baseCond)>1
          warning('More than one base condition was provided/found. Using only the first one.')
          disp('List of baseline conditions provided:')
          disp(baseCond)
          baseCond=baseCond{1};
      end
      baseConds{itype}=baseCond;
  end
  trialTypes=types;

end
