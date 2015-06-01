%OG study: old subjects adapted gradually

handles.group='Old Gradual';

%condition numbers
i=1;
for cond = [1 2 4:10]
    set(handles.(['condition' num2str(i)]),'string',num2str(cond))
    i=i+1;
end
set(handles.numofconds,'string','9')

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','slow base')
set(handles.condName3,'string','fast base')
set(handles.condName4,'string','TM base')
set(handles.condName5,'string','adaptation')
set(handles.condName6,'string','catch')
set(handles.condName7,'string','re-adaptation')
set(handles.condName8,'string','OG post')
set(handles.condName9,'string','TM post')

%condition descriptions
set(handles.description1,'string','8m walkway for 6 min')
set(handles.description2,'string','150 strides at 0.5 m/s')
set(handles.description3,'string','150 strides at 1 m/s')
set(handles.description4,'string','150 strides at 0.75 m/s')
set(handles.description5,'string','600 strides,gradual split from 1:1 at 0.75 m/s to 2:1 at 1.0m/s and 0.5 m/s')
set(handles.description6,'string','10 strides at 0.75 m/s')
set(handles.description7,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
set(handles.description8,'string','8 m walkway for 6 min')
set(handles.description9,'string','150 strides at 0.75 m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:6')
set(handles.trialnum2,'string','7')
set(handles.trialnum3,'string','8')
set(handles.trialnum4,'string','9')
set(handles.trialnum5,'string','10:13')
set(handles.trialnum6,'string','14')
set(handles.trialnum7,'string','15 16')
set(handles.trialnum8,'string','17:22')
set(handles.trialnum9,'string','23:25')

%set trial types
for t=[1 8]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:7 9]
    set(handles.(['type' num2str(t)]),'string','TM')
end