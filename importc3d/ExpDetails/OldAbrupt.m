%OG study: old subjects adapted abruptly

handles.group='Old Abrupt';

%condition numbers
for cond = 1:10
    set(handles.(['condition' num2str(cond)]),'string',num2str(cond))
end
set(handles.numofconds,'string','10')    

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','slow base')
set(handles.condName3,'string','short split')
set(handles.condName4,'string','fast base')
set(handles.condName5,'string','TM base')
set(handles.condName6,'string','adaptation')
set(handles.condName7,'string','catch')
set(handles.condName8,'string','re-adaptation')
set(handles.condName9,'string','OG post')
set(handles.condName10,'string','TM post')

%condition descriptions
set(handles.description1,'string','8m walkway for 6 min')
set(handles.description2,'string','150 strides at 0.5 m/s')
set(handles.description3,'string','10 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description4,'string','150 strides at 1 m/s')
set(handles.description5,'string','150 strides at 0.75 m/s')
set(handles.description6,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description7,'string','10 strides at 0.75 m/s')
set(handles.description8,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description9,'string','8 m walkway for 6 min')
set(handles.description10,'string','150 strides at 0.75 m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:6')
set(handles.trialnum2,'string','7')
set(handles.trialnum3,'string','8')
set(handles.trialnum4,'string','9')
set(handles.trialnum5,'string','10')
set(handles.trialnum6,'string','11:14')
set(handles.trialnum7,'string','15')
set(handles.trialnum8,'string','16 17')
set(handles.trialnum9,'string','18:23')
set(handles.trialnum10,'string','24:26')

%set trial types
for t=[1 9]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:8 10]
    set(handles.(['type' num2str(t)]),'string','TM')
end