% Pablo: distraction study

handles.group='0002: Distraction';

%condition numbers
i=1;
for cond = [1:7]
    set(handles.(['condition' num2str(i)]),'string',num2str(cond))
    i=i+1;
end
set(handles.numofconds,'string','7')

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','TM base')
set(handles.condName3,'string','Gradual adaptation')
set(handles.condName4,'string','Catch')
set(handles.condName5,'string','Re-adaptation')
set(handles.condName6,'string','OG post')
set(handles.condName7,'string','TM post')

%condition descriptions
set(handles.description1,'string','8m walk for 10 min')
set(handles.description2,'string','300 strides 1.125m/s')
set(handles.description3,'string','300 strides 1.125 m/s, 600 gradual until 1.5:.75, 150 split')
set(handles.description4,'string','10 strides 1.125 m/s')
set(handles.description5,'string','150 at split 2:1')
set(handles.description6,'string','8m walk for 10 min')
set(handles.description7,'string','600 strides 1.125 m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:2')
set(handles.trialnum2,'string','3')
set(handles.trialnum3,'string','4')
set(handles.trialnum4,'string','5')
set(handles.trialnum5,'string','6')
set(handles.trialnum6,'string','7:8')
set(handles.trialnum7,'string','9')

%set trial types
for t=[1 6]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:5 7]
    set(handles.(['type' num2str(t)]),'string','TM')
end