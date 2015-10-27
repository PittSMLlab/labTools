%Script to process a python biofeedback data file and add the columns of
%data onto the end of the subject's adaptData instance
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
clear
clc
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
    
    %proceed to synchronize trials
    for z=1:1%length(filenames)
        
        waitbar((z-1)/length(filenames),WB,['Processing Trial ' num2str(z)]);
        %load python file
        [Pheader,Pdata] = JSONtxt2cell([path{z} filenames{z}]);
        
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
        
    end
    close(WB)
else
   
end


















