function Subs = makeSMatrixV2

sub=struct;

%find all files in pwd
files=what; 
fileList=files.mat;

for i=1:length(fileList)
    %find files in pwd that are (Subject)param.mat files
    aux1=strfind(lower(fileList{i}),'params');
    if ~isempty(aux1)
        subID=fileList{i}(1:(aux1-1));
        %subID=adaptData.subData.ID; %I think this is more appropriate.-Pablo
        load(fileList{i});
        
        %get group
        group=adaptData.metaData.ID;
        abrevGroup=group(ismember(group,['A':'Z' 'a':'z'])); %remove non-alphabetic characters
        if isempty(abrevGroup)
            abrevGroup='NoDescription';            
        end
%         spaces=find(group==' ');
%         abrevGroup=group(spaces+1);%         
%         abrevGroup=[group(1) abrevGroup];        
                
        if isfield(sub,abrevGroup)
            sub.(abrevGroup).IDs{end+1}=subID;
            sub.(abrevGroup).adaptData{end+1}=adaptData;            
        else
            sub.(abrevGroup).IDs= {subID};
            sub.(abrevGroup).adaptData={adaptData};           
        end       
    end
end

groups=fields(sub);
for i=1:length(groups)
    Subs.(groups{i})=groupAdaptationData(sub.(groups{i}).IDs,sub.(groups{i}).adaptData);
end

end