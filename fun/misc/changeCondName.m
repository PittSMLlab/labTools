function changeCondName(subID,oldNames,newNames)
%Changes the condition names of a param file. 
%   INPTUS:
%   subID: a string (or cell array of strings) with the subject's ID (i.e. the
%   characters preceeding 'params' in the file name)
%   oldNames: a string (or cell array of strings) with the condition name(s) to be replaced
%   newNames: a string (or cell array of strings) with the condition name(s) that should replace the old ones

%Check inputs.

if isa(subID,'char')
    subID={subID};
elseif ~(isa(subID,'cell') && isa(subID{1},'char'))       
    ME=MException('changeCondName:inputMismatch','subID needs to be a string or cell array of strings.');
    throw(ME);
end

if isa(oldNames,'char')
    oldNames={oldNames};
elseif ~(isa(oldNames,'cell') && isa(oldNames{1},'char'))       
   ME=MException('changeCondName:inputMismatch','oldNames needs to be a string or cell array of strings.');
   throw(ME);
end

if isa(newNames,'char')
    newNames={newNames};
elseif ~(isa(newNames,'cell') && isa(newNames{1},'char'))       
   ME=MException('changeCondName:inputMismatch','oldNames needs to be a string or cell array of strings.');
   throw(ME);
end

if length(oldNames) ~= length(newNames)
   ME=MException('changeCondName:badInput','oldNames and newNames inputs must be the same length.');
   throw(ME);
end

for s=1:length(subID)
    try
        load([subID{s} 'params.mat'])
    catch
        ME=MException('changeCondName:badInput',['The params file for ' subID{s} ' does not appear to be in your curent folder.']);
        throw(ME);
    end
    
    for c=1:length(oldNames)
        ind=find(ismember(adaptData.metaData.conditionName,oldNames(c)));
        if isempty(ind)
            warning([subID{s}  '''s file does not contain condition ''' oldNames{c} ''' and was not replaced with ''' newNames{c} ''''])
            continue
        else
            adaptData.metaData.conditionName{ind}=newNames{c};        
        end
    end
    save([subID{s} 'params.mat'],'adaptData','-v7.3')
end
    
    