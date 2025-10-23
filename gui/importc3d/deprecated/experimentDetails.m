%%% THIS FUNCTION IS NO LONGER IN USE. INSTEAD OF EDITING THIS CODE, ADD
%%% NEW EXPEPERIMENTS TO THE importc3d/expDetails FOLDER.

function handles = experimentDetails(expDescrip,handles)
%Fill in Condition Info fields of GetInfoGUI based on experiment entered
%
%When adding a new experiment description, follow the examples below or
%refer to "Adding an Experiment Description" in the user guide. Make sure
%to keep condNames values consistant with previous conventions.
%
%INPUTS:
%expDescription: string containing description chosen in GetInfoGUI
%handles: GUI handles from GetInfoGUI
%
%OUTPUT:
%handles: modified handles structure with updated values for
%condition, condName, description, trialnum, and type fields 


switch expDescrip
    case {'Old Abrupt','Young Abrupt','Old Abrupt Second Visit','Young Abrupt Second Visit'}
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
        
    case {'Old Gradual','Young Gradual'}
        
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
        
    case {'Old Abrupt No Catch','Young Abrupt No Catch'}
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
        
    case {'Old Gradual No Catch','Young Gradual No Catch'}
        %condition numbers
        i=1;
        for cond = [1 2 4:6 8:10]
            set(handles.(['condition' num2str(i)]),'string',num2str(cond))
            i=i+1;
        end
        set(handles.numofconds,'string','8')    
        
        %condition names
        set(handles.condName1,'string','OG base')
        set(handles.condName2,'string','slow base')
        set(handles.condName3,'string','fast base')
        set(handles.condName4,'string','TM base')
        set(handles.condName5,'string','adaptation')        
        set(handles.condName6,'string','re-adaptation')
        set(handles.condName7,'string','OG post')
        set(handles.condName8,'string','TM post')
        
        %condition descriptions
        set(handles.description1,'string','8m walkway for 6 min')
        set(handles.description2,'string','150 strides at 0.5 m/s')
        set(handles.description3,'string','150 strides at 1 m/s')
        set(handles.description4,'string','150 strides at 0.75 m/s')
        set(handles.description5,'string','600 strides,gradual split from 1:1 at 0.75 m/s to 2:1 at 1.0m/s and 0.5 m/s')
        set(handles.description6,'string','150 strides 2:1, 1 m/s and 0.5 m/s')
        set(handles.description7,'string','8 m walkway for 6 min')
        set(handles.description8,'string','150 strides at 0.75 m/s')
        
        %trial numbers for each condition
        set(handles.trialnum1,'string','1:6')
        set(handles.trialnum2,'string','7')
        set(handles.trialnum3,'string','24')
        set(handles.trialnum4,'string','8')
        set(handles.trialnum5,'string','9:12')        
        set(handles.trialnum6,'string','13 14')
        set(handles.trialnum7,'string','15:20')
        set(handles.trialnum8,'string','21:23')        
        
        %set trial types
        for t=[1 7]
            set(handles.(['type' num2str(t)]),'string','OG')
        end
        for t=[2:6 8]
            set(handles.(['type' num2str(t)]),'string','TM')
        end 
        
        
    case {'Old Abrupt Self Selected','Young Abrupt Self Selected'}
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
        
    case {'Old Gradual Self Selected','Young Gradual Self Selected'}
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
        
    case {'0002: Distraction'}
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
        
    case {'0002: Old'}
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
        set(handles.condName4,'string','Catch (N/A)')
        set(handles.condName5,'string','Split condition')
        set(handles.condName6,'string','OG post')
        set(handles.condName7,'string','TM post')

        %condition descriptions
        set(handles.description1,'string','8m walk for 10 min')        
        set(handles.description2,'string','300 strides 1.125m/s')        
        set(handles.description3,'string','300 strides 1.125 m/s, 600 gradual until 1.5:.75, 150 split')
        set(handles.description4,'string','N/A')
        set(handles.description5,'string','150 at split 2:1')
        set(handles.description6,'string','8m walk for 10 min')
        set(handles.description7,'string','600 strides 1.125 m/s')
        
        %trial numbers for each condition
        set(handles.trialnum1,'string','1:10')
        set(handles.trialnum2,'string','11:12')
        set(handles.trialnum3,'string','13:19')
        set(handles.trialnum4,'string','')
        set(handles.trialnum5,'string','20')
        set(handles.trialnum6,'string','21:30')
        set(handles.trialnum7,'string','31:34')
        
        %set trial types
        for t=[1 6]
            set(handles.(['type' num2str(t)]),'string','OG')
        end
        for t=[2:5 7]
            set(handles.(['type' num2str(t)]),'string','TM')
        end     
        
end

end