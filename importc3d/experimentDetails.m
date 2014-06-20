function handles = experimentDetails(expDescrip,handles)

switch expDescrip
    case {'Old Abrupt','Young Abrupt'}
        %condition numbers
        for cond = 1:10
            eval(['set(handles.condition',num2str(cond),',''string'',''',num2str(cond),''')'])
        end
        set(handles.numofconds,'string','10')        
        
        %condition descriptions
        set(handles.description1,'string','over ground baseline')
        set(handles.description2,'string','slow basleine 150 strides')
        set(handles.description3,'string','short split 10 strides')
        set(handles.description4,'string','fast baseline 150 strides')
        set(handles.description5,'string','medium baseline 150 strides')
        set(handles.description6,'string','adaptation 4x150 strides')
        set(handles.description7,'string','catch 10 strides')
        set(handles.description8,'string','re-adaptation 2x150 strides')
        set(handles.description9,'string','over ground post-adaptation')
        set(handles.description10,'string','treadmill post-adaptation')
        
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
                
        %condition descriptions
        set(handles.description1,'string','over ground baseline')
        set(handles.description2,'string','slow basleine 150 strides')
        set(handles.description3,'string','fast baseline 150 strides')
        set(handles.description4,'string','medium baseline 150 strides')
        set(handles.description5,'string','adaptation 4x150 strides')
        set(handles.description6,'string','catch 10 strides')
        set(handles.description7,'string','re-adaptation 2x150 strides')
        set(handles.description8,'string','over ground post-adaptation')
        set(handles.description9,'string','treadmill post-adaptation')
        
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