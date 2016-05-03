classdef SombricTaiChi
    %SombricTaiChi class is for processing 
    %   Detailed explanation goes here
    
    properties
        subjectcode='';
        sex='';
        dominantleg='';
        dominanthand='';
        fastleg=''
        height=[];
        weight=[];
        triallist={};
        Rtarget=[];
        Ltarget=[];
        datalocation=pwd;
        data={};
        dataheader={};
        
    end
    
    methods
        
        function this=SombricTaiChi(ID,sex,dleg,dhand,fastleg,height,weight,triallist,Rtarget,Ltarget)
            
            if nargin ~= 11
                %                 disp('Error, incorrect # of input arguments provided');
                cprintf('err','Error: incorrect # of input arguments provided\n');
            else
            end
            
            if ischar(ID)
                this.subjectcode=ID;
            else
                this.subjectcode='';
                cprintf('err','WARNING: invalid subject ID input, must be a string\n');
            end
            
            if ischar(sex)
                this.sex = sex;
            else
                cprintf('err','WARNING: input for subject gender must be a string\n');
                this.sex='';
            end
            
            if ischar(dleg)
                this.dominantleg=dleg;
            else
                cprintf('err','WARNING: incorrect format for dominant leg input, must be a string\n');
                this.dominantleg='';
            end
            
            if ischar(dhand)
                this.dominanthand=dhand;
            else
                cprintf('err','WARNING: incorrect format for dominant hand input, must be a string\n');
                this.dominanthand='';
            end
            
            if ischar(fastleg)
                this.fastleg=fastleg;
            else
                cprintf('err','WARNING: incorrect format for fast leg, must be a string\n');
                this.fastleg='';
            end
            
            if isnumeric(height)
                this.height = height;
            else
                cprintf('err','WARNING: input height is not numeric\n');
                this.height=[];
            end
            
            if isnumeric(weight)
                this.weight = weight;
            else
                cprintf('err','WARNING: input weight is not numeric\n');
                this.weight=[];
            end
            
            if iscell(triallist)
                this.triallist=triallist;
            else
                cprintf('err','WARNING: triallist input is not a cell format.\n');
                this.triallist={};
            end
            
            if isnumeric(Rtarget)
                this.Rtarget = Rtarget;
            else
                cprintf('err','WARNING: Right step length target is not numeric type.\n');
                this.Rtarget = [];
            end
            
            if isnumeric(Ltarget)
                this.Ltarget = Ltarget;
            else
                cprintf('err','WARNING: Left step length target is not numeric type.\n');
                this.Ltarget = [];
            end
                
        end
        
        
        function []=AnalyzePerformance(this)
            
            
            
        end
        
        function []=editTriallist(this)
            global t
            global ID
            ID = this.subjectcode;
            
            if isempty(this.triallist)%if triallist is empty, start from scratch
                [filenames,~] = uigetfiles('*.*','Select filenames');
                this.data = cell(length(filenames),1);
                if iscell(filenames)
                    f = figure;
                    data = cell(length(filenames),4);
                    data(:,1)=filenames;
                    
                    for z=1:length(filenames)%autodetect if a trial was a train for evaluation
                        tname = filenames{z};
                        if strcmp(tname(end-5:end-4),'V1')
                            data{z,3} = 'train';
                        else
                            data{z,3} = 'eval';
                        end
                    end
                    %                     keyboard
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
                    if strcmp(filenames(end-5:end-4),'V3')
                        data(1,3) = 'train';
                    else
                        data(1,3) = 'eval';
                    end
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                end
                
            else %if triallist is already populated, just edit what is already there
                [filenames,~] = uigetfiles('*.*','Select filenames');
                this.data = cell(length(filenames),1);
                if iscell(filenames)
                    f = figure;
                    data = cell(length(filenames),4);
                    data(:,1)=filenames;
                    data(:,2:4) = this.triallist(:,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
                    data(1,2:4) = this.triallist(1,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                end
                
            end
            
        end
        
        function []=saveit(this)%save instance as the "subjectcode_SLBF"
            
            if isempty(this.subjectcode)
                cprintf('err','WARNING: save failed, no valid ID present');
            else
                savename = [this.subjectcode '_PerceptionBF_day.mat'];
                eval([this.subjectcode '=this;']);
                save(savename,this.subjectcode);
            end
        end
        
        function [X,Y]=getHits(this)
            
            filename = this.triallist(:,1);
            WB = waitbar(0,'Processing Trials...');
            
            if iscell(filename)
                
                tempname = filename{z};
                waitbar((z-1)/length(filename),WB,['Processing Trial ' num2str(z)]);
                
                if strcmp(this.triallist{z,4},'Rleg Train')
                    color{z} = [189/255,15/255,18/255];%red
                elseif strcmp(this.triallist{z,4},'Lleg Train')
                    color{z} = [189/255,15/255,18/255];%red
                elseif strcmp(this.triallist{z,4},'Base Rleg Map')
                    color{z} = [48/255,32/255,158/255];%blue
                elseif strcmp(this.triallist{z,4},'Base Lleg Map')
                    color{z} = [48/255,32/255,158/255];%blue
                elseif strcmp(this.triallist{z,4},'Post Rleg Map')
                    color{z} = [9/255,109/255,143/255];%bluegrey
                elseif strcmp(this.triallist{z,4},'Post Lleg Map')
                    color{z} = [9/255,109/255,143/255];%bluegrey
                end
                
                %check to see if data is already processed, it will
                %save time...
                if length(this.data)<z
                    disp('Parsing data...');
                    fn = filename{z};
                    keyboard
                    if strcmp(fn(end-3:end),'c3d')
                    end
                    
                    f = fopen(filename{z});
                    g = fgetl(f);
                    fclose(f);
                    
                    if strcmp(g(1),'[')
                        [header,data] = JSONtxt2cell(filename{z});
                        this.data{z} = data;
                        this.dataheader = header;
                    else
                        S = importdata(filename{z},',',1);
                        data = S.data;
                        this.data{z} = S.data;
                        this.dataheader = S.textdata;
                    end
                else
                    data = cell2mat(this.data(z));
                    header = this.dataheader;
                end
                
                data2 = unique(data,'rows','stable');%remove duplicate frames
                data2(:,1) = data2(:,1)-data2(1,1)+1;%set frame # to start at 1
                
                %check for monotonicity
                checkers = find(diff(data2(:,1))<1);
                while ~isempty(checkers)
                    disp('WARNING repeated frames present in data, removing...');
                    for y=1:length(checkers)
                        data2(checkers(y),:)=[];
                    end
                    checkers = find(diff(data2(:,1))<1);
                end
                
                Rz2 = data2(:,2);
                Lz2 = data2(:,3);
                Rx = data2(:,6);
                Ry = data2(:,7);
                Lx = data2(:,8);
                Ly = data2(:,9);
                phase = data2(:,10);
                
                
            else
                
            end
        
        
    end
    
end

