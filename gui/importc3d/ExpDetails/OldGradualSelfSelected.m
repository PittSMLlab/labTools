%OG study: old subjects adapted abruptly at self-selected speed

handles.group='Old Gradual Self Selected';

%condition numbers
i=1;
for cond = [1 5 6:11 2 3 4]
    set(handles.(['condition' num2str(i)]),'string',num2str(cond))
    i=i+1;
end
set(handles.numofconds,'string','11')

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','TM base')
set(handles.condName3,'string','adaptation')
set(handles.condName4,'string','catch')
set(handles.condName5,'string','re-adaptation')
set(handles.condName6,'string','OG post')
set(handles.condName7,'string','TM post')
set(handles.condName8,'string','self selected')
set(handles.condName9,'string','slow base')
set(handles.condName10,'string','short split')
set(handles.condName11,'string','fast base')

%condition descriptions
set(handles.description1,'string','8m walkway for 6 min')
set(handles.description2,'string','150 strides at SS')
set(handles.description3,'string','600 strides,gradual split from 1:1 at SS to 2:1 at at SS +/- 0.333*SS m/s')
set(handles.description4,'string','10 strides at SS')
set(handles.description5,'string','150 strides 2:1, at SS +/- 0.333*SS m/s')
set(handles.description6,'string','8 m walkway for 6 min')
set(handles.description7,'string','150 strides at SS')
set(handles.description8,'string','>=600 strides at self set pace')
set(handles.description9,'string','150 strides at SS-0.333*SS m/s')
set(handles.description10,'string','10 strides 2:1, at SS +/- 0.333*SS m/s')
set(handles.description11,'string','150 strides at SS+0.333*SS m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:3')
set(handles.trialnum2,'string','8')
set(handles.trialnum3,'string','9:12')
set(handles.trialnum4,'string','13')
set(handles.trialnum5,'string','14 15')
set(handles.trialnum6,'string','16:21')
set(handles.trialnum7,'string','22:24')
set(handles.trialnum8,'string','4:7')
set(handles.trialnum9,'string','12')
set(handles.trialnum10,'string','11')
set(handles.trialnum11,'string','25')

%set trial types
for t=[1 6]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:5 7:11]
    set(handles.(['type' num2str(t)]),'string','TM')
end