function handles = setExpDescription(handles,expDes)

handles.group = expDes.group;

count = 0;
for ii = 1:handles.lines
    % condition numbers
    if isfield(expDes,['condition' num2str(ii)])
        set(handles.(['condition' num2str(ii)]), ...
            'string',num2str(expDes.(['condition' num2str(ii)])));
        count = count + 1;
    end
    % condition names
    if isfield(expDes,['condName' num2str(ii)])
        set(handles.(['condName' num2str(ii)]), ...
            'string',expDes.(['condName' num2str(ii)]));
    end
    % condition descriptions
    if isfield(expDes,['description' num2str(ii)])
        set(handles.(['description' num2str(ii)]), ...
            'string',expDes.(['description' num2str(ii)]));
    end
    % trial numbers for each condition
    if isfield(expDes,['trialnum' num2str(ii)])
        set(handles.(['trialnum' num2str(ii)]), ...
            'string',expDes.(['trialnum' num2str(ii)]));
    end
    % set trial types
    if isfield(expDes,['type' num2str(ii)])
        set(handles.(['type' num2str(ii)]), ...
            'string',expDes.(['type' num2str(ii)]));
    end
end

if isfield(expDes,'numofconds')
    set(handles.numofconds,'string',expDes.numofconds);
else
    set(handles.numofconds,'string',num2str(count));
end

end

