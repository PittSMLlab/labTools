%OG study: old subjects adapted abruptly without a catch

handles.group='Old Abrupt No Catch';

%condition numbers
i=1;
for cond = [1:6 8:10]
    set(handles.(['condition' num2str(i)]),'string',num2str(cond))
    i=i+1;
end
set(handles.numofconds,'string','9')

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','slow base')
set(handles.condName3,'string','short split')
set(handles.condName4,'string','fast base')
set(handles.condName5,'string','TM base')
set(handles.condName6,'string','adaptation')
set(handles.condName7,'string','re-adaptation')
set(handles.condName8,'string','OG post')
set(handles.condName9,'string','TM post')

%condition descriptions
set(handles.description1,'string','8m walkway for 6 min')
set(handles.description2,'string','150 strides at 0.5 m/s')
set(handles.description3,'string','10 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description4,'string','150 strides at 1 m/s')
set(handles.description5,'string','150 strides at 0.75 m/s')
set(handles.description6,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description7,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description8,'string','8 m walkway for 6 min')
set(handles.description9,'string','150 strides at 0.75 m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:6')
set(handles.trialnum2,'string','7')
set(handles.trialnum3,'string','8')
set(handles.trialnum4,'string','25')
set(handles.trialnum5,'string','9')
set(handles.trialnum6,'string','10:13')
set(handles.trialnum7,'string','14 15')
set(handles.trialnum8,'string','16:21')
set(handles.trialnum9,'string','22:24')

%set trial types
for t=[1 8]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:7 9]
    set(handles.(['type' num2str(t)]),'string','TM')
end