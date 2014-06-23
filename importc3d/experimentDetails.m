function handles = experimentDetails(expDescrip,handles)

switch expDescrip
    case {'Old Abrupt','Young Abrupt'}
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
end

end