function handles = experimentDetails(expDescrip,handles)

switch expDescrip
    case {'Old Abrupt','Young Abrupt','Old Abrupt Second Visit','Young Abrupt Second Visit'}
        %condition numbers
        for cond = 1:10
            eval(['set(handles.condition',num2str(cond),',''string'',''',num2str(cond),''')'])
        end
        set(handles.numofconds,'string','10')    
        
        %condition names
        set(handles.condName1,'string','over ground baseline')
        set(handles.condName2,'string','slow basleine')
        set(handles.condName3,'string','short split')
        set(handles.condName4,'string','fast baseline')
        set(handles.condName5,'string','medium baseline')
        set(handles.condName6,'string','adaptation')
        set(handles.condName7,'string','catch')
        set(handles.condName8,'string','re-adaptation')
        set(handles.condName9,'string','over ground post-adaptation')
        set(handles.condName10,'string','treadmill post-adaptation')
        
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
        
        %check appropriate OG conditions
        set(handles.OGcheck1,'value',1)
        set(handles.OGcheck9,'value',1)
        
    case {'Old Gradual','Young Gradual'}
        
        %condition numbers
        i=1;
        for cond = [1 2 4:10]
            eval(['set(handles.condition',num2str(i),',''string'',''',num2str(cond),''')'])
            i=i+1;
        end
        set(handles.numofconds,'string','9')
         
        %condition names
        set(handles.condName1,'string','over ground baseline')
        set(handles.condName2,'string','slow basleine')        
        set(handles.condName3,'string','fast baseline')
        set(handles.condName4,'string','medium baseline')
        set(handles.condName5,'string','adaptation')
        set(handles.condName6,'string','catch')
        set(handles.condName7,'string','re-adaptation')
        set(handles.condName8,'string','over ground post-adaptation')
        set(handles.condName9,'string','treadmill post-adaptation')
        
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
        
        %check appropriate OG conditions
        set(handles.OGcheck1,'value',1)
        set(handles.OGcheck8,'value',1)
    case {'Old Abrupt No Catch','Young Abrupt No Catch'}
        %condition numbers
        i=1;
        for cond = [1:6 8:10]
            eval(['set(handles.condition',num2str(i),',''string'',''',num2str(cond),''')'])
            i=i+1;
        end
        set(handles.numofconds,'string','9')    
        
        %condition names
        set(handles.condName1,'string','over ground baseline')
        set(handles.condName2,'string','slow basleine')
        set(handles.condName3,'string','short split')
        set(handles.condName4,'string','fast baseline')
        set(handles.condName5,'string','medium baseline')
        set(handles.condName6,'string','adaptation')        
        set(handles.condName7,'string','re-adaptation')
        set(handles.condName8,'string','over ground post-adaptation')
        set(handles.condName9,'string','treadmill post-adaptation')
        
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
        
        %check appropriate OG conditions
        set(handles.OGcheck1,'value',1)
        set(handles.OGcheck8,'value',1)
    case {'Old Abrupt Self Selected','Young Abrupt Self Selected'}
        %condition numbers
        i=1;
        for cond = [1 3 5 6:11 4 2]
            eval(['set(handles.condition',num2str(i),',''string'',''',num2str(cond),''')'])
            i=i+1;
        end        
        set(handles.numofconds,'string','11')    
        
        %condition names
        set(handles.condName1,'string','over ground baseline')        
        set(handles.condName2,'string','short split')        
        set(handles.condName3,'string','medium baseline')
        set(handles.condName4,'string','adaptation')
        set(handles.condName5,'string','catch')
        set(handles.condName6,'string','re-adaptation')
        set(handles.condName7,'string','over ground post-adaptation')
        set(handles.condName8,'string','treadmill post-adaptation')
        set(handles.condName9,'string','self selected')
        set(handles.condName10,'string','fast baseline')
        set(handles.condName11,'string','slow basleine')
        
        
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
        
        %check appropriate OG conditions
        set(handles.OGcheck1,'value',1)
        set(handles.OGcheck7,'value',1)
end

end