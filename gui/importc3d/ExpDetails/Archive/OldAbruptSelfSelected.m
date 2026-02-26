%OG study: old subjects adapted abruptly at self-selected speed

handles.group= 'Old Abrupt Self Selected';

%condition numbers
i=1;
for cond = [1 3 5 6:11 4 2]
    set(handles.(['condition' num2str(i)]),'string',num2str(cond))
    i=i+1;
end
set(handles.numofconds,'string','11')

%condition names
set(handles.condName1,'string','OG base')
set(handles.condName2,'string','short split')
set(handles.condName3,'string','TM base')
set(handles.condName4,'string','adaptation')
set(handles.condName5,'string','catch')
set(handles.condName6,'string','re-adaptation')
set(handles.condName7,'string','OG post')
set(handles.condName8,'string','TM post')
set(handles.condName9,'string','self selected')
set(handles.condName10,'string','fast base')
set(handles.condName11,'string','slow base')

%condition descriptions
set(handles.description1,'string','8m walkway for 6 min')
set(handles.description2,'string','10 strides 2:1, at SS +/- 0.333*SS m/s')
set(handles.description3,'string','150 strides at SS')
set(handles.description4,'string','150 strides 2:1, at SS +/- 0.333*SS m/s')
set(handles.description5,'string','10 strides at SS')
set(handles.description6,'string','150 strides 2:1, at SS +/- 0.333*SS m/s')
set(handles.description7,'string','8 m walkway for 6 min')
set(handles.description8,'string','150 strides at SS')
set(handles.description9,'string','>=600 strides at self set pace')
set(handles.description10,'string','150 strides at SS+0.333*SS m/s')
set(handles.description11,'string','150 strides at SS-0.333*SS m/s')

%trial numbers for each condition
set(handles.trialnum1,'string','1:6')
set(handles.trialnum2,'string','14')
set(handles.trialnum3,'string','15')
set(handles.trialnum4,'string','16:19')
set(handles.trialnum5,'string','20')
set(handles.trialnum6,'string','21 22')
set(handles.trialnum7,'string','23:27')
set(handles.trialnum8,'string','28 29 30')
set(handles.trialnum9,'string','7:12')
set(handles.trialnum10,'string','31')
set(handles.trialnum11,'string','13')

%set trial types
for t=[1 7]
    set(handles.(['type' num2str(t)]),'string','OG')
end
for t=[2:6 8:11]
    set(handles.(['type' num2str(t)]),'string','TM')
end