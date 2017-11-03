%Script to process a python biofeedback data file and add the columns of
%data onto the end of the subject's adaptData instance
% 
%  No inputs required, inputs are asked for during the execution. However,
%  it is required that Nexus processing has already been done prior to
%  calling this function. otherwise it will not be able to find the
%  labtools objects to update.
%
%  No output is returned, however a message is displayed which indicates
%  success or failure
%
%This function is intended to be universaly usefull, in other words it
%will be useful for any study collecting biofeedback in conjunction with a
%nexus gait trial. This is not designed for biofeedback trials outside of
%gait (it doesn't make sense to be doing this if there is no gait).
%
%written 10/26/2015 WDA


% clear
% clc


%select processed subject data to add biofeedback info to:
[notname,LTpathname]=uigetfile('.mat','Select Subject File:');%you can pick any of the matlab files SUB.RAW or sub.info or sub.params etc.
cd(LTpathname);
%enter the subject code
LTfilename = inputdlg('Please enter the subject code:','',1,{notname(1:6)});%notname is a guess, make sure to check or this will crash
LTfilename = LTfilename{1};
%load subject files
WB = waitbar(0,'Loading RAW file');
load([LTfilename 'RAW.mat']);
waitbar(0.33,WB,'Loading main file');
load([LTfilename '.mat']);
waitbar(0.66,WB,'Loading params file');
load([LTfilename 'params.mat']);
waitbar(1,WB,'Loading complete');
pause(0.25)
close(WB)


global t;%variable for uitable later on
global mdata;
global ndata;
global condition%get condition names
condition= adaptData.metaData.conditionName;
global trialsincond
trialsincond = adaptData.metaData.trialsInCondition;

% select python file(s) to process
[filenames,path] = uigetfiles('*.*','Select python files');
% 
if iscell(filenames)
    %construct a uitable as a makeshift GUI that will help user assign
    %python files to nexus trials
    f = figure;
    mdata = cell(length(filenames),3);
    mdata(:,1)=filenames;
    
    colnames = {'Filename','Nexus Trial #','condition'};
    columnformat = {'char','numeric',condition};

    t=uitable(f,'Position',[10,10,375,375],'Data',mdata,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[false false true],'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
    set(t,'celleditcallback','global condition;global trialsincond;global t;temp = get(t,''Data'');cel=get(t,''UserData'');tcond = temp(cel(1),cel(2));[~,~,ind]=intersect(tcond,condition);temp{cel(1),2}=trialsincond{ind}(end);set(t,''Data'',temp)');
    set(t,'DeleteFcn','global mdata;mdata = get(t,''Data'');');
    waitfor(t)%wait until user closes the table to continue
    
    WB = waitbar(0,['Processing Trial ' num2str(1)]);
    
    strideplace = adaptData.data.stridesTrial;%where to insert data from Python trials
%     appendm = nan(length(strideplace),1);
    %proceed to synchronize trials
    for z=1:length(filenames)
        
        waitbar((z-1)/length(filenames),WB,['Loading Trial ' num2str(z)]);
        
        f = fopen([path{z} filenames{z}]);
        g = fgetl(f);
        fclose(f);
        
        if strcmp(g(1),'[')
            [Pheader,Pdata] = JSONtxt2cell([path{z} filenames{z}]);
        else
            S = importdata([path{z} filenames{z}],',',1);
            Pdata = S.data;
            Pheader = S.textdata;
        end
        
        
        %in the end we can only patch in data to good strides, so give the
        %user a chance to select which variables to patch in
        %use listdlg
        if z==1
            
            f = figure;
            ndata = cell(length(Pheader),3);
            ndata(:,1)=Pheader;
            ndata(:,2)={'NO'};%presume that all of the parameters are to be added, don't force user to pick
            ndata(:,3)={'HS'};
            
            colnames = {'Variable','Include?','Alignment'};
            columnformat = {'char',{'YES','NO'},{'HS','TO'}};
            t=uitable(f,'Position',[10,10,375,375],'Data',ndata,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[false true true],'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
            set(t,'DeleteFcn','global ndata;ndata = get(t,''Data'');');
            waitfor(t)%wait until user closes the table to continue

        end
        
        waitbar((z-1)/length(filenames),WB,['Synchronizing Trial ' num2str(z)]);
        %get nexus data
        GRRz=getDataAsVector(expData.data{mdata{z,2}}.GRFData,'RFz');
        GRLz=getDataAsVector(expData.data{mdata{z,2}}.GRFData,'LFz');
        
        %TO DO, enable variable sampling frequency inputs, since some BF is
        %collected at 100 Hz
        %downsample from 1000 to 100Hz
        NexusRlowFreq=resample(GRRz,1,10);
        NexusLlowFreq=resample(GRLz,1,10);
        
        %Creating NaN matrix with the lenght of the data
        newData=nan((((Pdata(end,1)-Pdata(1,1)))+1),size(Pheader,2));
        newData2=nan((((Pdata(end,1)-Pdata(1,1)))+1),size(Pheader,2));
        
        %Making frames from Pyton start at 1
        Pdata(:,1)=Pdata(:,1)-Pdata(1,1)+1;
        Pdata2=unique(Pdata(:,1));
        
        %finding unique colums
        for zz=1:length(Pdata2)
            [datarows(zz),~]=find(Pdata(:,1)==Pdata2(zz),1,'first');
        end
        Pdata=Pdata(datarows,:);
        clear datarows
        %Creating a linear interpolate matrix from Pyton data
        newData=interp1(Pdata(:,1),Pdata(:,1:end),[Pdata(1,1):Pdata(end,1)]);
        
        %Creating a Matrix with NaN in gaps from Pyton
        for i=1:length(Pdata)
            newData2(Pdata(i,1),1:end)=Pdata(i,:);
        end
        
        indc = strfind(Pheader,'Rfz');%figure out which column contains the Rfz data
        indc = find(not(cellfun('isempty',indc)));
        %synchronize with cross correlation
        [acor, lag]=xcorr(NexusRlowFreq,newData(:,indc));%use RFz from Pdata
        [~,I]=max((acor));
        delay=I-max(length(NexusRlowFreq),length(newData(:,indc)));
        
        %remove extra python data at the beginning
        if (delay < 0)
            tempdata = newData(abs(delay)+1:end,:);
        elseif (delay > 0)
            tempdata = newData(abs(delay)+1:end,:);
            disp('WARNING: positive delay detected between Python and Labtools, unpredictable alignment is imminent...');
        end
        
        %append or delete python data to match labtools
        if length(tempdata)<length(NexusRlowFreq)
            tempdata(end:length(NexusRlowFreq),:)=nan;
        elseif length(tempdata)>length(NexusRlowFreq)
            tempdata(length(NexusRlowFreq):end,:)=[];
        end
        
%         figure(60)
%         subplot(2,1,1)
%         hold on
%         plot(NexusRlowFreq,'b');
%         plot([delay+1:length(newData(:,indc))+delay],newData(:,indc),'r');
%         
%         subplot(2,1,2)
%         hold on
%         plot(0:length(NexusRlowFreq)-1,NexusRlowFreq,'b');
%         plot(0:length(tempdata)-1,tempdata(:,indc),'r');
        
%         keyboard
        %apply alignment
        newData = tempdata;
        
        %old method
%         if timeDiff<0
%             newData=newData(abs(timeDiff)+1:end,1:end);
%             newData2=newData2(abs(timeDiff)+1:end,1:end);
%         elseif timeDiff>0
%             newData=[zeros([timeDiff,size(Pheader,2)]);newData];
%             newData2=[zeros([timeDiff,size(Pheader,2)]);newData2];
%             
%         end
%         keyboard
        
        try
            [~,rhsc,~] = intersect(Pheader,'RHS');%find which column contains RHS as detected by Python
            [~,lhsc,~] = intersect(Pheader,'LHS');
            [~,rtoc,~] = intersect(Pheader,'RTO');
            [~,ltoc,~] = intersect(Pheader,'LTO');
            [~,Rfzc,~] = intersect(Pheader,'Rfz');
            [~,Lfzc,~] = intersect(Pheader,'Lfz');
        catch me
            disp('WARNING! One or more requested events was not located in the Python file');
        end
        
        %Finding HS from Nexus at 100HZ and Interpolated Pyton data, interpolate
        %data is used to make sure that we dont take in consideration extras HS.
        %check Gait events
        [LHSnexus,RHSnexus,LTOnexus,RTOnexus]= getEventsFromForces(NexusLlowFreq,NexusRlowFreq,100);
        %aligned python data events:
        [LHSpyton,RHSpyton,LTOpyton,RTOpyton]= getEventsFromForces(newData(:,Lfzc),newData(:,Rfzc),100);
        
        
        %localication of HS==1);
        locLHSpyton=find(LHSpyton==1);
        locRHSpyton=find(RHSpyton==1);
        locRHSnexus=find(RHSnexus==1);
        locLHSnexus=find(LHSnexus==1);
        
        
        %verify event detection is acceptable
%         figure(61)
% %         subplot(2,1,1)
%         hold on
% %         plot(NexusRlowFreq,'b');
%         plot(RHSnexus,'r');
% %         plot(newData(:,Rfzc),'g');
%         plot(RHSpyton,'o','MarkerFaceColor','black');
        
        
%         keyboard
        
        locRindex = locRHSnexus;%HS indices
        locLindex = locLHSnexus;
        locR2index=find(newData2(:,rtoc)==1);%toe off indices
        locL2index=find(newData2(:,ltoc)==1);
        
        if length(locRindex)<length(locRHSpyton)
            warning('Not all the HS where detected in Live mode, appending with NaN.')
        end


        selections = strfind(ndata(:,2),'YES');%find which column contains RHS as detected by Python
        selections(cellfun('isempty',selections))={0};
        selections = find(cell2mat(selections));
        if z==1
            labels=Pheader(selections);
            PPheader = Pheader;%in case some parameters are not in all the files to be processed
        end
        %initialize appending matrix
        if z ==1
            appendm = nan(length(strideplace),length(selections));%going to be the matrix that gets appended to adaptparams
        end
            %make vectors of variable to splice into adapData
            for d = 1:length(selections)
%                 disp(z)
%                 disp(d)
                if length(Pheader)<selections(d)%in case one of the parameters is not in this file
                    eval(['missing' num2str(d) ' = nan(length(locRindex),1);']);
                else
                    if ismember('R',Pheader{selections(d)})==1
                        event = ndata(selections(d),3);
                        if strcmp(event,'HS')
                            eval([Pheader{selections(d)} ' = newData(locRindex,' num2str(selections(d)) ');']);
                        else
                            eval([Pheader{selections(d)} ' = newData(locR2index,' num2str(selections(d)) ');']);
                        end
                    elseif ismember('L',Pheader{selections(d)})==1
                        event = ndata(selections(d),3);
                        if strcmp(event,'HS')
                            eval([Pheader{selections(d)} ' = newData(locLindex,' num2str(selections(d)) ');']);
                        else
                            eval([Pheader{selections(d)} ' = newData(locL2index,' num2str(selections(d)) ');']);
                        end
                    else
                        disp('Can''t which leg current variable belongs to...adding to Right Leg')
                        disp(Pheader{selections(d)});
                        event = ndata(selections(d),3);
                        if strcmp(event,'HS')
                            eval([Pheader{selections(d)} ' = newData(locRindex,' num2str(selections(d)) ');']);
                        else
                            eval([Pheader{selections(d)} ' = newData(locR2index,' num2str(selections(d)) ');']);
                        end
                    end
                end
                
%                 figure(z+100)
%                 subplot(length(selections),1,d)
%                 hold on
%                 eval(['plot(locRindex,' Pheader{selections(d)} ',''o'',''MarkerFaceColor'',''black'');']);
%                 plot(newData(:,selections(d)),'b');
%                 plot(RHSpyton,'g');
%                 plot(newData(:,4),'r');
                
            end

            
            

            
            for d = 1:length(selections)
                indx = find(strideplace==mdata{z,2});
                if length(Pheader)<selections(d)%in case parameter isn't in a particular file, just add nans
                    eval(['appendm(indx,d) = nan(length(indx),1);']);%insert data
                else

                    if length(indx)>length(eval(Pheader{selections(d)}))
                        eval([Pheader{selections(d)} '(end:length(indx)) = nan;']);
                    end
                    eval(['appendm(indx,d) = ' Pheader{selections(d)} '(1:length(indx));']);%insert data
                end
            end
    
        
    end
    
    
    
    
    %finally, append to
    pData=adaptData.data;
%     labels=Pheader(selections);
    [aux,idx]=pData.isaLabel(labels);
    if all(aux)
        adaptData.data.Data(:,idx)=appendm;
    else
        this=parameterSeries([adaptData.data.Data,appendm],[adaptData.data.labels;PPheader(selections)'],1:length(adaptData.data.Data),cell(length(adaptData.data.labels)+length(selections)),adaptData.data.trialTypes);
        %this=paramData([adaptData.data.Data,StepsR,StepsL,Steps,Stepsnexus],[adaptData.data.labels; 'TargetHitR'; 'TargetHitL' ;'TargetHit'; 'TargetNexus'],adaptData.data.indsInTrial,adaptData.data.trialTypes);
        adaptData=adaptationData(rawExpData.metaData,rawExpData.subData,this);
    end
    
    waitbar(1,WB,'Synchronizing Finished');
    pause(0.5);
    close(WB)
    
    %now save the adap params
    saveloc=[];
    save([saveloc LTfilename 'params.mat'],'adaptData');
    
else
    
    f = figure;
    mdata = cell(1,3);
    mdata{1,1}=filenames;
    
    colnames = {'Filename','Nexus Trial #','condition'};
    columnformat = {'char','numeric',condition};

    t=uitable(f,'Position',[10,10,375,375],'Data',mdata,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[false false true],'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
    set(t,'celleditcallback','global condition;global trialsincond;global t;temp = get(t,''Data'');cel=get(t,''UserData'');tcond = temp(cel(1),cel(2));[~,~,ind]=intersect(tcond,condition);temp{cel(1),2}=trialsincond{ind};set(t,''Data'',temp)');
    set(t,'DeleteFcn','global mdata;mdata = get(t,''Data'');');
    waitfor(t)%wait until user closes the table to continue
    
    WB = waitbar(0,['Processing Trial ' num2str(1)]);
    
    strideplace = adaptData.data.stridesTrial;%where to insert data from Python trials
    [Pheader,Pdata] = JSONtxt2cell([path filenames]);%load python data

    %in the end we can only patch in data to good strides, so give the
    %user a chance to select which variables to patch in and what event to
    %align them with:
    %use uitable
    f = figure;
    ndata = cell(length(Pheader),3);
    ndata(:,1)=Pheader;
    ndata(:,2)={'YES'};%presume that all of the parameters are to be added, don't force user to pick
    ndata(:,3)={'HS'};
    
    colnames = {'Variable','Include?','Alignment'};
    columnformat = {'char',{'YES','NO'},{'HS','TO'}};
    t=uitable(f,'Position',[10,10,375,375],'Data',ndata,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[false true true],'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
%     set(t,'celleditcallback','global condition;global trialsincond;global t;temp = get(t,''Data'');cel=get(t,''UserData'');tcond = temp(cel(1),cel(2));[~,~,ind]=intersect(tcond,condition);temp{cel(1),2}=trialsincond{ind};set(t,''Data'',temp)');
    set(t,'DeleteFcn','global ndata;ndata = get(t,''Data'');');
    waitfor(t)%wait until user closes the table to continue
    
    %{
%     [selections,ok] = listdlg('ListString',Pheader,'PromptString','Select variables to add to adapParams:');
%     appendm = nan(length(strideplace),length(selections));%going to be the matrix that gets appended to adaptparams
%     if ok
%         %                 selections = Pheader(selections)
%     else
%         dbquit
%     end
    %}
    
    %get nexus data
    GRRz=getDataAsVector(expData.data{mdata{1,2}}.GRFData,'RFz');
    GRLz=getDataAsVector(expData.data{mdata{1,2}}.GRFData,'LFz');
    
    %TO DO, enable variable sampling frequency inputs, since some BF is
    %collected at 120 Hz
    %downsample from 1000 to 100Hz
    NexusRlowFreq=resample(GRRz,1,10);
    NexusLlowFreq=resample(GRLz,1,10);
    
    %Creating NaN matrix with the lenght of the data
    newData=nan((((Pdata(end,1)-Pdata(1,1)))+1),size(Pheader,2));
    newData2=nan((((Pdata(end,1)-Pdata(1,1)))+1),size(Pheader,2));
    
    %Making frames from Pyton start at 1
    Pdata(:,1)=Pdata(:,1)-Pdata(1,1)+1;
    Pdata2=unique(Pdata(:,1));%remove duplicate frames
    
    %finding unique colums
    for zz=1:length(Pdata2)
        [datarows(zz),~]=find(Pdata(:,1)==Pdata2(zz),1,'first');
    end
    Pdata=Pdata(datarows,:);
    clear datarows
    %Creating a linear interpolate matrix from Pyton data
    newData=interp1(Pdata(:,1),Pdata(:,1:end),[Pdata(1,1):Pdata(end,1)]);
    
    %Creating a Matrix with NaN in gaps from Pyton
    for i=1:length(Pdata)
        newData2(Pdata(i,1),1:end)=Pdata(i,:);
    end
    
    indc = strfind(Pheader,'Rfz');%figure out which column contains the Rfz data
    indc = find(not(cellfun('isempty',indc)));
    %synchronize with cross correlation
    [acor, lag]=xcorr(NexusRlowFreq,newData(:,indc));%use RFz from Pdata
    [~,I]=max((acor));
    timeDiff=lag(I);
    if timeDiff<0
        newData=newData(abs(timeDiff)+1:end,1:end);
        newData2=newData2(abs(timeDiff)+1:end,1:end);
    elseif timeDiff>0
        newData=[zeros([timeDiff,size(Pheader,2)]);newData];
        newData2=[zeros([timeDiff,size(Pheader,2)]);newData2];
        
    end
    
    figure(5)%display the synchronization
    plot(NexusRlowFreq,'b')
    hold on
    plot(newData2(:,indc), 'r')
    
    try
        [~,rhsc,~] = intersect(Pheader,'RHS');%find which column contains RHS as detected by Python
        [~,lhsc,~] = intersect(Pheader,'LHS');
        [~,rtoc,~] = intersect(Pheader,'RTO');
        [~,ltoc,~] = intersect(Pheader,'LTO');
        [~,rfz,~] = intersect(Pheader,'Rz');
        [~,lfz,~] = intersect(Pheader,'Lz');
    catch me
        disp('WARNING! One or more requested events was not located in the Python file');
    end
    
    Pdata(1,rhsc) = 0;
    Pdata(1,rtoc) = 0;
    Pdata(1,lhsc) = 0;
    Pdata(1,ltoc) = 0;
    
    %temporary one time fix for bad TO data
    ind = Pdata(:,rtoc)>0.5;
    ind = [0;diff(ind)>0]>0;
    Pdata(:,rtoc)=+ind;
    
    ind = Pdata(:,ltoc)>0.5;
    ind = [0;diff(ind)>0]>0;
    Pdata(:,ltoc)=+ind;
    
    %Finding HS from Nexus at 100HZ and Interpolated Pyton data, interpolate
    %data is used to make sure that we dont take in consideration extras HS.
    %check Gait events
    [LHSnexus,RHSnexus,LTOnexus,RTOnexus]= getEventsFromForces(NexusLlowFreq,NexusRlowFreq,100);
    [LHSpyton,RHSpyton,LTOpyton,RTOpyton]= getEventsFromForces(newData(:,lhsc),newData(:,rhsc),100);
    
    %localication of HS==1);
    locLHSpyton=find(LHSpyton==1);
    locRHSpyton=find(RHSpyton==1);
    locRTOpyton = find(RTOpyton==1);
    locLTOpyton = find(LTOpyton==1);
    
    %one time only, recalculate TO for stance time data with incorrectly
    %saved data
%     tempRz = newData2(:,2);
%     tempLz = newData2(:,3);
%     RTOpyton = zeros(length(tempRz),1);
%     for s=1:length(tempRz)-1
%         
%        if tempRz(s+1)>-30 && tempRz(s)<=-30
%            RTOpyton(s) = 1;
%        else
%            RTOpyton(s) = 0;
%        end
%         
%     end
    
    
    locRHSnexus=find(RHSnexus==1);
    locLHSnexus=find(LHSnexus==1);
    locRTOnexus = find(RTOnexus==1);
    locLTOnexus = find(LTOnexus==1);
    
    try
        locRindex=find(newData2(:,rhsc)==1);
        locLindex=find(newData2(:,lhsc)==1);
        locR2index=find(newData2(:,rtoc)==1);
        locL2index=find(newData2(:,ltoc)==1);
    catch me
        disp('WARNING! One or more requested events was not located in the Python file');
    end
    
    if length(locRindex)<length(locRHSpyton)
        warning('Not all the HS where detected!')
    end
    
    %Delete extras HS deteted by Python
    if length(locRHSpyton)~=length(locRindex)
        disp(['Mismatch in RHS detected, fixing...']);
        while length(locRHSpyton)~=length(locRindex)
            diffLengthR=length(locRindex)-length(locRHSpyton);
            FrameDiffR=locRindex(1:end-diffLengthR)-locRHSpyton;
            IsBadR=find(FrameDiffR<=-10);
            if isempty(IsBadR)
                break
            else
                locRindex(IsBadR(1))=[];
            end
        end
    end
    
    if length(locLHSpyton)~=length(locLindex)
        disp(['Mismatch in LHS detected, fixing...']);
        while length(locLHSpyton)~=length(locLindex)
            diffLength=length(locLindex)-length(locLHSpyton);
            FrameDiff=locLindex(1:end-diffLength)-locLHSpyton;
            IsBad=find(FrameDiff<=-10);
            if isempty(IsBad)
                break
            else
                locLindex(IsBad(1))=[];
            end
        end
    end
    
    %Delete extras TO deteted by Python
    if length(locRTOpyton)~=length(locR2index)
        disp(['Mismatch in RTO detected, fixing...']);
        while length(locRTOpyton)~=length(locR2index)
            diffLengthR=length(locR2index)-length(locRTOpyton);
            FrameDiffR=locR2index(1:end-diffLengthR)-locRTOpyton;
            IsBadR=find(FrameDiffR<=-10);
            if isempty(IsBadR)
                break
            else
                locR2index(IsBadR(1))=[];
            end
        end
    end
    
    if length(locLTOpyton)~=length(locL2index)
        disp(['Mismatch in LTO detected, fixing...']);
        while length(locLTOpyton)~=length(locL2index)
            diffLengthL=length(locL2index)-length(locLTOpyton);
            FrameDiffL=locL2index(1:end-diffLengthL)-locLTOpyton;
            IsBadL=find(FrameDiffL<=-10);
            if isempty(IsBadL)
                break
            else
                locL2index(IsBadL(1))=[];
            end
        end
    end
    
    %Fix missing HS in Python
    if length(locRHSnexus)<length(locRindex)
        FrameDiffR=[];
        IsBadR=[];
        while length(locRHSnexus)~=length(locRindex)
            diffLengthR=length(locRindex)-length(locRHSnexus);
            FrameDiffR=-locRindex(1:end-diffLengthR)+locRHSnexus;
            IsBadR=find(abs(FrameDiffR)>10);
            if isempty(IsBadR)
                break
            else
                locRindex(IsBadR(1))=[];
            end
        end
    end
    
    if length(locLHSnexus)<length(locLindex)
        FrameDiff=[];
        IsBad=[];
        while length(locLindex)~=length(locLHSnexus)
            diffLength=length(locLindex)-length(locLHSnexus);
            FrameDiff=-locLindex(1:end-diffLength)+locLHSnexus;
            IsBad=find(abs(FrameDiff)>10);
            if isempty(IsBad)
                break
            else
                locLindex(IsBad(1))=[];
            end
        end
    end
    
    %Fix missing TO in Python
    if length(locRTOnexus)<length(locR2index)
        FrameDiffR=[];
        IsBadR=[];
        while length(locRTOnexus)~=length(locR2index)
            diffLengthR=length(locR2index)-length(locRTOnexus);
            FrameDiffR=-locR2index(1:end-diffLengthR)+locRTOnexus;
            IsBadR=find(abs(FrameDiffR)>10);
            if isempty(IsBadR)
                break
            else
                locR2index(IsBadR(1))=[];
            end
        end
    end
    
    if length(locLTOnexus)<length(locL2index)
        FrameDiff=[];
        IsBad=[];
        while length(locL2index)~=length(locLTOnexus)
            diffLength=length(locL2index)-length(locLTOnexus);
            FrameDiff=-locL2index(1:end-diffLength)+locLTOnexus;
            IsBad=find(abs(FrameDiff)>10);
            if isempty(IsBad)
                break
            else
                locL2index(IsBad(1))=[];
            end
        end
    end
    
    
    
    
    
    
    if length(locRHSnexus)>length(locRindex)
        warning(['Gaps affected RHS detection  ' condition{p} ])
        
        while length(locRHSnexus)>length(locRindex)
            diffLengthR=-length(locRindex)+length(locRHSnexus);
            FrameDiffR=locRHSnexus(1:end-diffLengthR)-locRindex;
            
            IsBadR=find(FrameDiffR<=-10);
            if isempty(IsBadR)
                break
            else
                locfakeR=[locRindex(1:IsBadR-1);locRHSnexus(IsBadR(1));locRindex(IsBadR:end)];
                locRindex=locfakeR;
            end
        end
    end
    if length(locLHSnexus)>length(locLindex)
        warning(['Gaps affected LHS detection  ' condition{p}])
        
        while length(locLHSnexus)>length(locLindex)
            diffLengthL=-length(locLindex)+length(locLHSnexus);
            FrameDiffL=locLHSnexus(1:end-diffLengthL)-locLindex;
            IsBadL=find(FrameDiffL<=-10);
            if isempty(IsBadL)
                break
            else
                locfakeL=[locLindex(1:IsBadL-1);locLHSnexus(IsBadL(1));locLindex(IsBadL:end)];
                locLindex=locfakeL;
            end
        end
        
    end
    
    for i=1:length(locLindex)-1
        locLindex2(i,1)=locLindex(i+1);
    end
    
    GoodEvents=expData.data{mdata{1,2}}.adaptParams.Data(:,2);%which events are labeled as good?
    %{
    %         BadEvents=expData.data{mdata{z,2}}.adaptParams.Data(:,1);%which events are labeled as bad?
    %         locRindex=locRindex((GoodEvents)==1,1);
    %         locLindex=locLindex((GoodEvents)==1,1);
    %         locLindex2=locLindex2((GoodEvents)==1,1);
    
    %         GoodRHS=newData2(locRindex,rhsc);
    %         GoodLHS=newData2(locLindex,lhsc);
    %         GoodLHS2=newData2(locLindex2,lhsc);
    %}
    
    selections = strfind(ndata(:,2),'YES');%find which column contains RHS as detected by Python
    selections(cellfun('isempty',selections))={0};
    selections = find(cell2mat(selections));
    
    appendm = nan(length(strideplace),length(selections));
    %make vectors of variable to splice into adapData
    for d = 1:length(selections)
        if ismember('R',Pheader{selections(d)})==1
            event = ndata(selections(d),3);
            if strcmp(event,'HS')
                disp(['aligning ',Pheader{selections(d)}, ' with Heel Strikes']);
                eval([Pheader{selections(d)} ' = newData2(locRindex,' num2str(selections(d)) ');']);
            else
                disp(['aligning ',Pheader{selections(d)}, ' with Toe Offs']);
%                 eval([Pheader{selections(d)} ' = newData2(locR2index,' num2str(selections(d)) ');']);
                eval([Pheader{selections(d)} ' = newData2(locR2index-1,' num2str(selections(d)) ');']);
            end
        elseif ismember('L',Pheader{selections(d)})==1
            event = ndata(selections(d),3);
            if strcmp(event,'HS')
                disp(['aligning ',Pheader{selections(d)}, ' with Heel Strikes']);
                eval([Pheader{selections(d)} ' = newData2(locLindex,' num2str(selections(d)) ');']);
            else
                disp(['aligning ',Pheader{selections(d)}, ' with Toe Offs']);
%                 eval([Pheader{selections(d)} ' = newData2(locL2index,' num2str(selections(d)) ');']);
                eval([Pheader{selections(d)} ' = newData2(locL2index-1,' num2str(selections(d)) ');']);
            end
        else
            disp('Can''t tell whether current variable belongs to which leg...')
            disp(Pheader{selections(d)});
        end
    end
    
    
    for d = 1:length(selections)
        indx = find(strideplace==mdata{1,2});
        eval(['appendm(indx,d) = ' Pheader{selections(d)} '(1:length(indx));']);%insert data
    end
    

    %finally, append to
    pData=adaptData.data;
    labels=Pheader(selections);
    [aux,idx]=pData.isaLabel(labels);
    if all(aux)
        adaptData.data.Data(:,idx)=appendm;
    else
        this=parameterSeries([adaptData.data.Data,appendm],[adaptData.data.labels;Pheader(selections)'],1:length(adaptData.data.Data),cell(length(adaptData.data.labels)+length(selections)),adaptData.data.trialTypes);
        %this=paramData([adaptData.data.Data,StepsR,StepsL,Steps,Stepsnexus],[adaptData.data.labels; 'TargetHitR'; 'TargetHitL' ;'TargetHit'; 'TargetNexus'],adaptData.data.indsInTrial,adaptData.data.trialTypes);
        adaptData=adaptationData(rawExpData.metaData,rawExpData.subData,this);
    end
    
    waitbar(1,WB,'Synchronizing Finished');
    pause(0.5);
    close(WB)
    %now save the adap params
    saveloc=[];
    save([saveloc LTfilename 'params.mat'],'adaptData');
   
end


















