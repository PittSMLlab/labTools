function handles = setExpDescription(handles,expDes)

handles.group=expDes.group;

c=0;
for i = 1:handles.lines
    %condition numbers
    if isfield(expDes,['condition' num2str(i)])
        set(handles.(['condition' num2str(i)]),'string',num2str(expDes.(['condition' num2str(i)])))
        c=c+1;
    end
    %condition names
    if isfield(expDes,['condName' num2str(i)])
        set(handles.(['condName' num2str(i)]),'string',expDes.(['condName' num2str(i)]))
    end
    %condition descriptions
    if isfield(expDes,['description' num2str(i)])
        set(handles.(['description' num2str(i)]),'string',expDes.(['description' num2str(i)]))
    end
    %trial numbers for each condition
    if isfield(expDes,['trialnum' num2str(i)])
        set(handles.(['trialnum' num2str(i)]),'string',expDes.(['trialnum' num2str(i)]))
    end
    %set trial types
    if isfield(expDes,['type' num2str(i)])
        set(handles.(['type' num2str(i)]),'string',expDes.(['type' num2str(i)]))
    end       
end
if isfield(expDes, 'numofconds')
    set(handles.numofconds,'string',expDes.numofconds)
else
    set(handles.numofconds,'string',num2str(c)) 
end


