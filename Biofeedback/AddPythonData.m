%Script to process a python biofeedback data file and add the columns of
%data onto the end of the subject's adaptData instance
% 
%  No inputs required, inputs are asked for during the execution. However,
%  it is required that Nexus processing has already been done prior to
%  calling this function. otherwise it will not be able to find the
%  labtools objects to update.
%
%  No output is returned, however a message is displayed which indicated
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
    set(t,'celleditcallback','global condition;global trialsincond;global t;temp = get(t,''Data'');cel=get(t,''UserData'');tcond = temp(cel(1),cel(2));[~,~,ind]=intersect(tcond,condition);temp{cel(1),2}=trialsincond{ind};set(t,''Data'',temp)');
    set(t,'DeleteFcn','global mdata;mdata = get(t,''Data'');');
    waitfor(t)%wait until user closes the table to continue
    

    WB = waitbar(0,['Processing Trial ' num2str(1)]);
    
    strideplace = adaptData.data.stridesTrial;%where to insert data from Python trials
%     appendm = nan(length(strideplace),1);
    %proceed to synchronize trials
    for z=1:length(filenames)
        
        waitbar((z-1)/length(filenames),WB,['Loading Trial ' num2str(z)]);
        %load python file
        [Pheader,Pdata] = JSONtxt2cell([path{z} filenames{z}]);
        
        
        %in the end we can only patch in data to good strides, so give the
        %user a chance to select which variables to patch in
        %use listdlg
        if z==1
            [selections,ok] = listdlg('ListString',Pheader,'PromptString','Select variables to add to adapParams:');
            appendm = nan(length(strideplace),length(selections));%going to be the matrix that gets appended to adaptparams
            if ok
%                 selections = Pheader(selections)
            else
                dbquit
            end
        end
        
        waitbar((z-1)/length(filenames),WB,['Synchronizing Trial ' num2str(z)]);
        %get nexus data
        GRRz=getDataAsVector(expData.data{mdata{z,2}}.GRFData,'RFz');
        GRLz=getDataAsVector(expData.data{mdata{z,2}}.GRFData,'LFz');
        
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
        
        %synchronize with cross correlation
        [acor, lag]=xcorr(NexusRlowFreq,newData(:,2));%use RFz from Pdata
        [~,I]=max((acor));
        timeDiff=lag(I);
        if timeDiff<0
            newData=newData(abs(timeDiff)+1:end,1:end);
            newData2=newData2(abs(timeDiff)+1:end,1:end);
        elseif timeDiff>0
            newData=[zeros([timeDiff,size(Pheader,2)]);newData];
            newData2=[zeros([timeDiff,size(Pheader,2)]);newData2];
            
        end
        
        %Finding HS from Nexus at 100HZ and Interpolated Pyton data, interpolate
        %data is used to make sure that we dont take in consideration extras HS.
        %check Gait events
        [LHSnexus,RHSnexus,LTOnexus,RTOnexus]= getEventsFromForces(NexusLlowFreq,NexusRlowFreq,100);
        [LHSpyton,RHSpyton,LTOpyton,RTOpyton]= getEventsFromForces(newData(:,3),newData(:,2),100);
        
        %localication of HS==1);
        locLHSpyton=find(LHSpyton==1);
        locRHSpyton=find(RHSpyton==1);
        locRHSnexus=find(RHSnexus==1);
        locLHSnexus=find(LHSnexus==1);
        
        [~,rhsc,~] = intersect(Pheader,'RHS');%find which column contains RHS as detected by Python
        [~,lhsc,~] = intersect(Pheader,'LHS');
        locRindex=find(newData2(:,rhsc)==1);
        locLindex=find(newData2(:,lhsc)==1);
        
        if length(locRindex)<length(locRHSpyton)
            warning('Not all the HS where detected!')
        end
        
        %Delete extras HS deteted by Python
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
        
        GoodEvents=expData.data{mdata{z,2}}.adaptParams.Data(:,2);%which events are labeled as good?
%         BadEvents=expData.data{mdata{z,2}}.adaptParams.Data(:,1);%which events are labeled as bad?
%         locRindex=locRindex((GoodEvents)==1,1);
%         locLindex=locLindex((GoodEvents)==1,1);
%         locLindex2=locLindex2((GoodEvents)==1,1);
       
%         GoodRHS=newData2(locRindex,rhsc);
%         GoodLHS=newData2(locLindex,lhsc);
%         GoodLHS2=newData2(locLindex2,lhsc);
        
        %make vectors of variable to splice into adapData
        for d = 1:length(selections)
            if ismember('R',Pheader{selections(d)})==1
                eval([Pheader{selections(d)} ' = newData2(locRindex,' num2str(selections(d)) ');']);
            elseif ismember('L',Pheader{selections(d)})==1
                eval([Pheader{selections(d)} ' = newData2(locLindex,' num2str(selections(d)) ');']);
            else
                disp('Can''t tell whether current variable belongs to which leg...')
                disp(Pheader{selections(d)});
            end
        end
        

        for d = 1:length(selections)
            indx = find(strideplace==mdata{z,2});
            eval(['appendm(indx,d) = ' Pheader{selections(d)} '(1:length(indx));']);%insert data
        end
        
        
        
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
    
    
else
   
end


















