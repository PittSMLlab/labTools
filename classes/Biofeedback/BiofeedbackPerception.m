classdef BiofeedbackPerception
    %Class BiofeedbackMD houses metadata and methods to process step length
    %biofeedback trials
    %
    %Properties:
    %
    %           subjectcode = '' string containing subject code, e.g. 'SLP001'
    %
    %           date='' Date of the experiment, lab date object
    %           labDate(dd,mm,yyyy)
    %
    %           sex = '' string designates subject sex e.g. 'f'
    %
    %           dob='' lab date object with date of birth labDate(dd,mm,yyyy)
    %
    %           dominantleg='' string designate dominant leg, e.g. 'r'
    %
    %           dominanthand = '' string designate dominant hand e.g. 'r'
    %
    %           fastleg = '' string designates which leg was fast
    %
    %           height=[];  cm
    %           weight=[];  kg
    %           age=[];  years
    %
    %           triallist={};  cell array of trial #'s, filenames, and type of
    %               trial. Construct instance with blank cell, can input data using a
    %               method instead of copying and pasting into inputs
    %
    %           Rtmtarget=[]; right leg step length target as determined by treadmill baseline
    %
    %           Ltmtarget=[]; left leg step length target as determined by treadmill baseline
    %
    %
    %     Methods:
    %
    %       AnalyzePerformance(flag) -- computes step length errors for each
    %                                   biofeedback trial,
    %
    %       editTriallist() -- select filenames, edit trial #'s and type and
    %                          category, input num is the # of trials, or rows in the list
    %
    %   saveit() -- saves the instance with filename equal to the ID
    %
    %   comparedays() -- makes bar plots comparing day1 and day2
    
    
    properties
        subjectcode = ''
        date=''
        sex = ''
        dob=''
        dominantleg=''
        dominanthand = ''
        fastleg = ''
        height=[];
        weight=[];
        age=[];
        triallist={};
        Rtmtarget=[];
        Ltmtarget=[];
        datalocation=pwd;
        data={};
        dataheader={};
        
        
    end
    
    methods
        %constuctor
        function this=BiofeedbackPerception(ID,date,sex,dob,dleg,dhand,fastleg,height,weight,age,triallist,Rtarget,Ltarget)
            
            if nargin ~= 13
                %                 disp('Error, incorrect # of input arguments provided');
                cprintf('err','Error: incorrect # of input arguments provided\n');
            else
                
                if ischar(ID)
                    this.subjectcode=ID;
                else
                    this.subjectcode='';
                    cprintf('err','WARNING: invalid subject ID input, must be a string\n');
                end
                
                if isa(date,'labDate')
                    this.date = date;
                else
                    cprintf('err','WARNING: incorrect experiment date format provided, must be class labDate\n');
                    this.date='';
                end
                
                if ischar(sex)
                    this.sex = sex;
                else
                    cprintf('err','WARNING: input for sex must be a string\n');
                    this.sex='';
                end
                
                if isa(dob,'labDate')
                    this.dob=dob;
                else
                    cprintf('err','WARNING: date of birth is not the correct format\n');
                    this.dob=[];
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
                
                if isa(age,'labDate')
                    this.age = age;
                else
                    cprintf('err','WARNING: input age is not class labDate\n');
                    this.age=[];
                end
                
                if iscell(triallist)
                    this.triallist=triallist;
                else
                    cprintf('err','WARNING: triallist input is not a cell format.\n');
                    this.triallist={};
                end
                
                if isnumeric(Rtarget)
                    this.Rtmtarget = Rtarget;
                else
                    cprintf('err','WARNING: Right step length target is not numeric type.\n');
                    this.Rtmtarget = [];
                end
                
                if isnumeric(Ltarget)
                    this.Ltmtarget = Ltarget;
                else
                    cprintf('err','WARNING: Left step length target is not numeric type.\n');
                    this.Ltmtarget = [];
                end
            end
        end
        
        function []=AnalyzePerformance(this)
            
            global rhits
            global lhits
            
            if isempty(this.triallist)
                cprintf('err','WARNING: no trial information available to analyze');
            else
                
                filename = this.triallist(:,1);
                
                if iscell(filename)%if more than one file is selected for analysis
                    
                    [rhits, lhits, rts, lts, color,rv,lv]=this.getHits();
                    [rhits, lhits, rts, lts, rv, lv]=this.removeTransitions(rhits, lhits, rts, lts, rv,lv);
                    clear z
                    %load triallist to look for categories
                    tlist = this.triallist;
                    
                    train = find(strcmp(tlist(:,4),'Familiarization'));%logicals of where training trials are
                    base = find(strcmp(tlist(:,4),'Base Map'));
                    adapt = find(strcmp(tlist(:,4),'Base Clamp'));
                    wash = find(strcmp(tlist(:,4),'Post Clamp'));
                    wash2 = find(strcmp(tlist(:,4),'Post Map'));
                    
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    this.PlotErrorTimecourse(rhits, lhits, rts, lts, rv,lv)
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %organize the data
                    PossibleTarget=sort(unique(rts{1}));
                    
                    for z = 1:length(filename)
                        
                        for t=1:length(rts{z})
                            if rts{z}(t)==PossibleTarget(3)
                                RDATA(t)=3;
                            elseif rts{z}(t)==PossibleTarget(1)
                                RDATA(t)=1;
                            elseif rts{z}(t)==PossibleTarget(2)
                                RDATA(t)=2;
                            else
                                break
                            end
                        end
                        
                        for t=1:length(lts{z})
                            if lts{z}(t)==PossibleTarget(3)
                                LDATA(t)=3;
                            elseif lts{z}(t)==PossibleTarget(1)
                                LDATA(t)=1;
                            elseif lts{z}(t)==PossibleTarget(2)
                                LDATA(t)=2;
                            else
                                break
                            end
                        end
                        
                        t=1;
                        r=1;
                        RR{z}=[0, 0, 0];
                        
                        %new, removing outliers
                        badR=[find(rhits{z}>=0.255); find(rhits{z}<=-0.255)];
                        rhits{z}(badR)=NaN;
                        badL=[find(lhits{z}>=0.255); find(lhits{z}<=-0.255)];
                        lhits{z}(badR)=NaN;
                        while t<length(rts{z})
                            %                             if strcmp(this.triallist{z,4},'Post Clamp')
                            %                                 RR{z}(r, RDATA(t))=mean(rhits{z}(t+1:t+3));%(find(RDATA(t:end)~=RDATA(t),1, 'first')+t-2))); %BLAH
                            %                             else
                            RR{z}(r, RDATA(t))=nanmean(rhits{z}(t:(find(RDATA(t:end)~=RDATA(t),1, 'first')+t-2))); %BLAH
                            %                             end
                            if isnan(RR{z}(r, RDATA(t)))
                                RR{z}(r, RDATA(t))=nanmean(rhits{z}(t:end));
                            end
                            t=find(RDATA(t:end)~=RDATA(t),1, 'first')+t-1;
                            if isempty(t)
                                t=length(rts{z});
                            end
                            if  RR{z}(r, RDATA(t))~=0;
                                r=r+1;
                            end
                        end
                        t=1;
                        r=1;
                        LL{z}=[0, 0, 0];
                        while t<length(lts{z})
                            %                             if strcmp(this.triallist{z,4},'Post Clamp')
                            %                                 LL{z}(r, LDATA(t))=mean(lhits{z}(t+1:t+3));%(find(LDATA(t:end)~=LDATA(t),1, 'first')+t-2)));%BLAH
                            %                             else
                            LL{z}(r, LDATA(t))=nanmean(lhits{z}(t:(find(LDATA(t:end)~=LDATA(t),1, 'first')+t-2)));%BLAH
                            %                             end
                            if isnan(LL{z}(r, LDATA(t)))
                                LL{z}(r, LDATA(t))=nanmean(lhits{z}(t:end));
                            end
                            t=find(LDATA(t:end)~=LDATA(t),1, 'first')+t-1;
                            if isempty(t)
                                t=length(lts{z});
                            end
                            if  LL{z}(r,LDATA(t))~=0;
                                r=r+1;
                            end
                        end
                        clear RDATA LDATA
                    end
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %DDR{1}=RR{wash}-RR{adapt};%Tit4tat:base subtraction
                    %DDR{1}=RR{wash}-repmat(RR{adapt}(end, :), size(RR{wash}, 1), 1);% Use the Baseline SS
                    DDR{1}=RR{wash}-repmat([mean(RR{adapt}(:, 1)) RR{adapt}(end, 2) mean(RR{adapt}(:, 3))], size(RR{wash}, 1), 1);DDR{1}(1:end-1, 2)=0;% Use the whole Baseline, mean
                    %DDR{1}=RR{wash}-repmat([median(RR{adapt}(:, 1)) RR{adapt}(end, 2) median(RR{adapt}(:, 3))], size(RR{wash}, 1), 1);DDR{1}(1:end-1, 2)=0;% Use the whole Baseline, median
                    DDR{2}=nanmean(RR{wash2}-RR{base});
                    
                    %DDL{1}=LL{wash}-LL{adapt};%Tit4tat:base subtraction
                    %DDL{1}=LL{wash}-repmat(LL{adapt}(end, :), size(LL{wash}, 1), 1);% Use the Baseline SS
                    DDL{1}=LL{wash}-repmat([mean(LL{adapt}(:, 1)) LL{adapt}(end, 2) mean(LL{adapt}(:, 3))], size(LL{wash}, 1), 1);DDL{1}(1:end-1, 2)=0;% Use the whole Baseline, mean
                    %DDL{1}=LL{wash}-repmat([median(LL{adapt}(:, 1)) LL{adapt}(end, 2) median(LL{adapt}(:, 3))], size(LL{wash}, 1), 1);DDL{1}(1:end-1, 2)=0;% Use the whole Baseline, median
                    DDL{2}=nanmean(LL{wash2}-LL{base});
                    % % %                     end
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    PlotMap(this, rhits, lhits,  RR, LL, DDR, DDL)
                    
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    PlotEC(this, rhits, lhits,  RR, LL, DDR, DDL)
                    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                end
            end
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
                        if strcmp(tname(end-5:end-4),'V3')
                            data{z,3} = 'train';
                        else
                            data{z,3} = 'eval';
                        end
                    end
                    %                     keyboard
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Familiarization','Base Map','Base Clamp','Post Clamp','Post Map'}};
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
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
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
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
                    data(1,2:4) = this.triallist(1,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
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
        
        function [dataCol]=getDataCol(this, dataname)
            for z=1:length(this.triallist)
                col=find(cellfun(@(x) strcmp(x, dataname), this.dataheader));
                if isempty(col)
                    cprintf('err','WARNING: no data with requested name found');
                    break
                end
                dataCol{z}=this.data{1, z}(:, col);
            end
        end
        
        function [rhits, lhits, rts, lts, color,rv,lv]=getHits(this)
            
            filename = this.triallist(:,1);
            
            if iscell(filename)%if more than one file is selected for analysis
                disp(['processing multiple trials']);
                rhits = {0};
                lhits = {0};
                rlqr = {0};
                llqr = {0};
                color = {};
                WB = waitbar(0,'Processing Trials...');
                for z = 1:length(filename)
                    tempname = filename{z};
                    waitbar((z-1)/length(filename),WB,['Processing Trial ' num2str(z)]);
                    
                    if strcmp(this.triallist{z,4},'Familiarization')
                        color{z} = [189/255,15/255,18/255];%red
                    elseif strcmp(this.triallist{z,4},'Base Map')
                        color{z} = [48/255,32/255,158/255];%blue
                    elseif strcmp(this.triallist{z,4},'Base Clamp')
                        color{z} = [1,.8,0];%
                    elseif strcmp(this.triallist{z,4},'Post Clamp')
                        color{z} = [91/255,122/255,5/255];%green
                    elseif strcmp(this.triallist{z,4},'Post Map')
                        color{z} = [9/255,109/255,143/255];%bluegrey
                    end
                    
                    %check to see if data is already processed, it will
                    %save time...
                    if length(this.data)<z
                        disp('Parsing data...');
                        
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
                        %                         disp('WARNING repeated frames present in data, removing...');
                        for y=1:length(checkers)
                            data2(checkers(y),:)=[];
                        end
                        checkers = find(diff(data2(:,1))<1);
                    end
                    
                    Rz2 = data2(:,2);
                    Lz2 = data2(:,3);
                    Rgamma2 = data2(:,10);
                    Lgamma2 = data2(:,11);
                    target = data2(:,14);
                    if strcmp(this.triallist{z,4},'Familiarization')
                        visible = data2(:,15);
                    end
                    
%                     %detect HS
%                     for zz = 1:length(Rz2)-1
%                         if Rz2(zz) > -30 && Rz2(zz+1) <= -30
%                             RHS(zz) = 1;
%                         else
%                             RHS(zz) = 0;
%                         end
%                     end
%                     [~,trhs] = findpeaks(RHS,'MinPeakDistance',75);
%                     RHS = zeros(length(RHS),1);
%                     RHS(trhs) = 1;
%                     for zz = 1:length(Lz2)-1
%                         if Lz2(zz) > -30 && Lz2(zz+1) <= -30
%                             LHS(zz) = 1;
%                         else
%                             LHS(zz) = 0;
%                         end
%                     end
%                     [~,tlhs] = findpeaks(LHS,'MinPeakDistance',75);
%                     LHS = zeros(length(LHS),1);
%                     LHS(tlhs) = 1;

                    %Labtools method of detecting events
                    [LHS,RHS,~,~]=getEventsFromForces(Lz2,Rz2,100);
                    
                    
                    
                    % keyboard
                    %%!!!!!!!!!!!!!!!!!!!!!!!%%!!!!!!!!!!!!!!!!!%%%!!!!!!!!!!!!!!!!
                    %calculate errors
                    %                     if strcmp(this.triallist{z,4},'Base Clamp') || strcmp(this.triallist{z,4},'Post Clamp')
                    %                         vamp = this.Rtmtarget-target(find(RHS)-1);
                    %                         vamp2 = this.Ltmtarget-target(find(LHS)-1);
                    %                         tamp = abs(Rgamma2(find(RHS)))-this.Rtmtarget-vamp;
                    %                         tamp2 = abs(Lgamma2(find(LHS)))-this.Ltmtarget-vamp2;
                    %                     else
                    tamp = Rgamma2(find(RHS))-target(find(RHS)-1);
                    tamp2 = Lgamma2(find(LHS))-target(find(LHS)-1);
                    %                     end
                    
                    tamp3 = target(find(RHS));
                    tamp4 = target(find(LHS));
                    if strcmp(this.triallist{z,4},'Familiarization')
                        tamp5 = visible(find(RHS));
                        tamp6 = visible(find(LHS));%this might be unnesescary since visible changes on RHS events only
                    else
                        tamp5 = zeros(length(tamp),1);
                        tamp6 = zeros(length(tamp),1);
                    end
                    
                    % % % %                     %delete 5 strides at each transistion
                    % % % %                     K = find(diff(tamp3));
                    % % % %                     K2 = find(diff(tamp4));
                    % % % %                     for y = 1:length(K)
                    % % % %                         tamp(K(y):K(y)+5)=100;
                    % % % %                         tamp3(K(y):K(y)+5)=100;
                    % % % %                         tamp5(K(y):K(y)+5)=100;
                    % % % %                     end
                    % % % %                     for y = 1:length(K2)
                    % % % %                         tamp2(K2(y):K2(y)+5)=100;
                    % % % %                         tamp4(K2(y):K2(y)+5)=100;
                    % % % %                         tamp6(K2(y):K2(y)+5)=100;
                    % % % %                     end
                    % % % %                     tamp(tamp==100)=[];
                    % % % %                     tamp2(tamp2==100)=[];
                    % % % %                     tamp3(tamp3==100)=[];
                    % % % %                     tamp4(tamp4==100)=[];
                    % % % %                     tamp5(tamp5==100)=[];
                    % % % %                     tamp6(tamp6==100)=[];
                    % % % %
                    rhits{z} = tamp;
                    lhits{z} = tamp2;
                    rts{z} = tamp3;
                    lts{z} = tamp4;
                    rv{z} = tamp5;
                    lv{z} = tamp6;
                    
                    clear RHS LHS tamp tamp2
                end
            end
            close(WB)
            this.saveit();
        end
        
        function [rhits, lhits, rts, lts, rv,lv]=removeTransitions(this, tamp, tamp2, tamp3, tamp4, tamp5, tamp6)
            
            for z = 1:length(tamp)
                %delete 5 strides at each transistion
                K = find(diff(tamp3{z}));
                K2 = find(diff(tamp4{z}));
                for y = 1:length(K)
                    tamp{z}(K(y):K(y)+5)=100;
                    tamp3{z}(K(y):K(y)+5)=100;
                    tamp5{z}(K(y):K(y)+5)=100;
                end
                for y = 1:length(K2)
                    tamp2{z}(K2(y):K2(y)+5)=100;
                    tamp4{z}(K2(y):K2(y)+5)=100;
                    tamp6{z}(K2(y):K2(y)+5)=100;
                end
                tamp{z}(tamp{z}==100)=[];
                tamp2{z}(tamp2{z}==100)=[];
                tamp3{z}(tamp3{z}==100)=[];
                tamp4{z}(tamp4{z}==100)=[];
                tamp5{z}(tamp5{z}==100)=[];
                tamp6{z}(tamp6{z}==100)=[];
                
                rhits{z} = tamp{z};
                lhits{z} = tamp2{z};
                rts{z} = tamp3{z};
                lts{z} = tamp4{z};
                rv{z} = tamp5{z};
                lv{z} = tamp6{z};
                
                
            end
        end
        
        function []=PlotErrorTimecourse(this, rhits, lhits, rts, lts, rv,lv)
            tlist = this.triallist;
            filename = this.triallist(:,1);
            train = find(strcmp(tlist(:,4),'Familiarization'));%logicals of where training trials are
            base = find(strcmp(tlist(:,4),'Base Map'));
            adapt = find(strcmp(tlist(:,4),'Base Clamp'));
            wash = find(strcmp(tlist(:,4),'Post Clamp'));
            wash2 = find(strcmp(tlist(:,4),'Post Map'));
            
            %check for more than one file in a condition
            if length(train)>1
                rtrain = 0;
                ltrain = 0;
                for c = 1:length(train)
                    rtrain = rtrain+length(cell2mat(rhits(train(c))));
                    ltrain = ltrain+length(cell2mat(lhits(train(c))));
                end
            else
                rtrain = length(cell2mat(rhits(train)));
                ltrain = length(cell2mat(lhits(train)));
            end
            
            if length(base)>1
                rbase = 0;
                lbase = 0;
                for c = 1:length(base)
                    rbase = rbase+length(cell2mat(rhits(base(c))));
                    lbase = lbase+length(cell2mat(lhits(base(c))));
                end
            else
                rbase = length(cell2mat(rhits(base)));
                lbase = length(cell2mat(lhits(base)));
            end
            
            if length(adapt)>1
                radapt = 0;
                ladapt = 0;
                for c = 1:length(adapt)
                    radapt = radapt+length(cell2mat(rhits(adapt(c))));
                    ladapt = ladapt+length(cell2mat(lhits(adapt(c))));
                end
            else
                radapt = length(cell2mat(rhits(adapt)));
                ladapt = length(cell2mat(lhits(adapt)));
            end
            
            if length(wash)>1
                rwash = 0;
                lwash = 0;
                for c = 1:length(wash)
                    rwash = rwash+length(cell2mat(rhits(wash(c))));
                    lwash = lwash+length(cell2mat(lhits(wash(c))));
                end
            else
                rwash = length(cell2mat(rhits(wash)));
                lwash = length(cell2mat(lhits(wash)));
            end
            
            figure(2)
            if this.fastleg == 'r'
                subplot(2,1,1)
            else
                subplot(2,1,2)
            end
            hold on
            
            fill([0 rtrain rtrain 0],[0.255 0.255 -0.255 -0.255],[150 150 150]./256)
            fill([rtrain rtrain+rbase  rtrain+rbase  rtrain],[0.255 0.255 -0.255 -0.255],[256 256 256]./256);
            fill([rtrain+rbase rtrain+rbase+radapt rtrain+rbase+radapt rtrain+rbase],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
            fill([rtrain+rbase+radapt  rtrain+rbase+radapt+rwash   rtrain+rbase+radapt+rwash  rtrain+rbase+radapt],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
            
            h = 0;
            for z = 1:length(filename)
                figure(2)
                if this.fastleg == 'r'
                    subplot(2,1,1)
                else
                    subplot(2,1,2)
                end
                hold on
                
                if strcmp(this.triallist{z,4},'Familiarization')
                    
                    temp = rv{z};
                    temp2 = rts{z};
                    groupies = temp+temp2;
                    g=gscatter([1:length(rhits{z})]+h,rhits{z},groupies,['b', 'k', 'r','b', 'k', 'r'],['s','o','d','s','o','d']);
                    colorfull=['w','w', 'w', 'b', 'k' ,'r' ];
                    colorout=['b','k', 'r', 'k', 'k' ,'k' ];
                    for y = 1:length(g)
                        set(g(y),'MarkerFaceColor',colorfull(y));
                        set(g(y),'MarkerEdgeColor',colorout(y));
                    end
                else
                    g=gscatter([1:length(rhits{z})]+h,rhits{z},rts{z},['b', 'k' ,'r'],['s','o','d']);
                    if  strcmp(this.triallist{z,4},'Base Clamp') || strcmp(this.triallist{z,4},'Post Clamp')
                        colorCODE=['b', 'k' ,'r'];
                        for y = 1:length(g)
                            set(g(y),'MarkerFaceColor',colorCODE(y));
                            set(g(y),'MarkerEdgeColor','k');
                        end
                    end
                end
                h = h+length(rhits{z});
            end
            plot([0 h+length(rhits{z})],[0.02 0.02],'k');%tolerance lines
            plot([0 h+length(rhits{z})],[-0.02 -0.02],'k');
            figure(2)
            if this.fastleg == 'r'
                subplot(2,1,1)
                title([this.subjectcode ' Step Length Error Fast Leg']);
            else
                subplot(2,1,2)
                title([this.subjectcode ' Step Length Error Slow Leg']);
            end
            ylim([-0.25 0.25]);
            xlim([0 h+10]);
            %                    title([this.subjectcode ' Step Length Error Fast Leg']);
            xlabel('step #');
            ylabel('Error (m)');
            legend('Familiarization', 'Spatial Map', 'Error Clamp','Error Clamp',  ...
                'Short No Vision', 'Mid No Vision', 'Long No Vision',...
                'Short Vision', 'Mid Vision', 'Long Vision')
            
            figure(2)
            if this.fastleg == 'l'
                subplot(2,1,1)
            else
                subplot(2,1,2)
            end
            hold on
            fill([0 ltrain ltrain 0],[0.255 0.255 -0.255 -0.255],[150 150 150]./256);
            fill([ltrain+lbase ltrain+lbase+ladapt ltrain+lbase+ladapt ltrain+lbase],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
            fill([ltrain+lbase+ladapt  ltrain+lbase+ladapt+lwash   ltrain+lbase+ladapt+lwash   ltrain+lbase+ladapt  ],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
            
            h = 0;
            for z = 1:length(filename)
                figure(2)
                if this.fastleg == 'l'
                    subplot(2,1,1)
                else
                    subplot(2,1,2)
                end
                if strcmp(this.triallist{z,4},'Familiarization')
                    
                    temp = rv{z};
                    temp2 = rts{z};
                    groupies = temp+temp2;
                    g=gscatter([1:length(rhits{z})]+h,rhits{z},groupies,['b', 'k', 'r','b', 'k', 'r'],['s','o','d','s','o','d']);
                    colorfull=['w','w', 'w', 'b', 'k' ,'r' ];
                    colorout=['b','k', 'r', 'k', 'k' ,'k' ];
                    for y = 1:length(g)
                        set(g(y),'MarkerFaceColor',colorfull(y));
                        set(g(y),'MarkerEdgeColor',colorout(y));
                    end
                else
                    g = gscatter([1:length(lhits{z})]+h,lhits{z},lts{z},['b', 'k' ,'r'],['s','o','d']);
                    if strcmp(this.triallist{z,4},'Familiarization') || strcmp(this.triallist{z,4},'Base Clamp') || strcmp(this.triallist{z,4},'Post Clamp')
                        colorCODE=['b', 'k' ,'r'];
                        for y = 1:length(g)
                            set(g(y),'MarkerFaceColor',colorCODE(y));
                            set(g(y),'MarkerEdgeColor','k');
                        end
                    end
                end
                
                plot([h h+length(lhits{z})],[0.02 0.02],'k');%tolerance lines
                plot([h h+length(lhits{z})],[-0.02 -0.02],'k');
                h = h+length(lhits{z});
            end
            figure(2)
            if this.fastleg == 'l'
                subplot(2,1,1)
                title([this.subjectcode ' Step Length Error Fast Leg']);
            else
                subplot(2,1,2)
                title([this.subjectcode ' Step Length Error Slow Leg']);
            end
            ylim([-0.25 0.25]);
            xlim([0 h+10]);
            %                    title([this.subjectcode ' Step Length Error Slow Leg']);
            xlabel('step #');
            ylabel('Error (m)');
        end
        
        function []=PlotMap(this,rhits, lhits,  RR, LL, DDR, DDL)
            tlist = this.triallist;
            filename = this.triallist(:,1);
            train = find(strcmp(tlist(:,4),'Familiarization'));%logicals of where training trials are
            base = find(strcmp(tlist(:,4),'Base Map'));
            adapt = find(strcmp(tlist(:,4),'Base Clamp'));
            wash = find(strcmp(tlist(:,4),'Post Clamp'));
            wash2 = find(strcmp(tlist(:,4),'Post Map'));
            h=0;
            
            %check for more than one file in a condition
            if length(train)>1
                rtrain = 0;
                ltrain = 0;
                for c = 1:length(train)
                    rtrain = rtrain+length(cell2mat(rhits(train(c))));
                    ltrain = ltrain+length(cell2mat(lhits(train(c))));
                end
            else
                rtrain = length(cell2mat(rhits(train)));
                ltrain = length(cell2mat(lhits(train)));
            end
            
            if length(base)>1
                rbase = 0;
                lbase = 0;
                for c = 1:length(base)
                    rbase = rbase+length(cell2mat(rhits(base(c))));
                    lbase = lbase+length(cell2mat(lhits(base(c))));
                end
            else
                rbase = length(cell2mat(rhits(base)));
                lbase = length(cell2mat(lhits(base)));
            end
            
            if length(adapt)>1
                radapt = 0;
                ladapt = 0;
                for c = 1:length(adapt)
                    radapt = radapt+length(cell2mat(rhits(adapt(c))));
                    ladapt = ladapt+length(cell2mat(lhits(adapt(c))));
                end
            else
                radapt = length(cell2mat(rhits(adapt)));
                ladapt = length(cell2mat(lhits(adapt)));
            end
            
            if length(wash)>1
                rwash = 0;
                lwash = 0;
                for c = 1:length(wash)
                    rwash = rwash+length(cell2mat(rhits(wash(c))));
                    lwash = lwash+length(cell2mat(lhits(wash(c))));
                end
            else
                rwash = length(cell2mat(rhits(wash)));
                lwash = length(cell2mat(lhits(wash)));
            end
            for z = base %2%1:length(filename)
                figure(4)
                if this.fastleg == 'r'
                    subplot(2,3,1)
                else
                    subplot(2,3,4)
                end
                hold on
                bar(RR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg: Baseline Map Test'])
                ylabel('Error (m)')
                legend({'Short', 'Medium', 'Long'})
                xlabel('Set')
                ylim([-0.255 0.255])
            end
            
            for z = base %for z = 2%1:length(filename)
                figure(4)
                if this.fastleg == 'l'
                    subplot(2,3,1)
                else
                    subplot(2,3,4)
                end
                hold on
                bar(LL{z})
                xlabel('Set')
                title([this.subjectcode ' SlowLeg: Baseline Map Test'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
            end
            
            for z = wash2 %%for z = 5%1:length(filename)
                figure(4)
                if this.fastleg == 'r'
                    subplot(2,3,2)
                else
                    subplot(2,3,5)
                end
                hold on
                bar(RR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg: Post-Adaptation Map Test'])
                ylabel('Error (m)')
                xlabel('Set')
                ylim([-0.255 0.255])
            end
            
            for z = wash2 %for z = 5%1:length(filename)
                figure(4)
                if this.fastleg == 'l'
                    subplot(2,3,2)
                else
                    subplot(2,3,5)
                end
                hold on
                bar(LL{z})
                xlabel('Set')
                title([this.subjectcode ' SlowLeg: Post Adaptation Map Test'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
            end
            
            for z = 2 %for z = 2%1:length(filename)
                figure(4)
                if this.fastleg == 'r'
                    subplot(2,3,3)
                else
                    subplot(2,3,6)
                end
                hold on
                
                bar(DDR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg Map Test (Washtout-Baseline)'])
                ylabel('Error (m)')
                %legend({'Short', 'Medium', 'Long'})
                %xlabel('Set')
                set(gca, 'XTickLabel',{'Short', 'Medium', 'Long'}, 'XTick',1:3)
                ylim([-0.255 0.255])
            end
            
            for z = 2 % %for z = 2%1:length(filename)
                figure(4)
                if this.fastleg == 'l'
                    subplot(2,3,3)
                else
                    subplot(2,3,6)
                end
                hold on
                bar(DDL{z})
                %xlabel('Set')
                set(gca, 'XTickLabel',{'Short', 'Medium', 'Long'}, 'XTick',1:3)
                title([this.subjectcode ' SlowLeg Map Test (Washtout-Baseline)'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
            end
            
        end
        
        function []=PlotEC(this,rhits, lhits,  RR, LL, DDR, DDL)
            tlist = this.triallist;
            filename = this.triallist(:,1);
            train = find(strcmp(tlist(:,4),'Familiarization'));%logicals of where training trials are
            base = find(strcmp(tlist(:,4),'Base Map'));
            adapt = find(strcmp(tlist(:,4),'Base Clamp'));
            wash = find(strcmp(tlist(:,4),'Post Clamp'));
            wash2 = find(strcmp(tlist(:,4),'Post Map'));
            h=0;
            
            %check for more than one file in a condition
            if length(train)>1
                rtrain = 0;
                ltrain = 0;
                for c = 1:length(train)
                    rtrain = rtrain+length(cell2mat(rhits(train(c))));
                    ltrain = ltrain+length(cell2mat(lhits(train(c))));
                end
            else
                rtrain = length(cell2mat(rhits(train)));
                ltrain = length(cell2mat(lhits(train)));
            end
            
            if length(base)>1
                rbase = 0;
                lbase = 0;
                for c = 1:length(base)
                    rbase = rbase+length(cell2mat(rhits(base(c))));
                    lbase = lbase+length(cell2mat(lhits(base(c))));
                end
            else
                rbase = length(cell2mat(rhits(base)));
                lbase = length(cell2mat(lhits(base)));
            end
            
            if length(adapt)>1
                radapt = 0;
                ladapt = 0;
                for c = 1:length(adapt)
                    radapt = radapt+length(cell2mat(rhits(adapt(c))));
                    ladapt = ladapt+length(cell2mat(lhits(adapt(c))));
                end
            else
                radapt = length(cell2mat(rhits(adapt)));
                ladapt = length(cell2mat(lhits(adapt)));
            end
            
            if length(wash)>1
                rwash = 0;
                lwash = 0;
                for c = 1:length(wash)
                    rwash = rwash+length(cell2mat(rhits(wash(c))));
                    lwash = lwash+length(cell2mat(lhits(wash(c))));
                end
            else
                rwash = length(cell2mat(rhits(wash)));
                lwash = length(cell2mat(lhits(wash)));
            end
            h=0;
            for z = adapt(1) % for z = 3%1:length(filename)
                figure(5)
                if this.fastleg == 'r'
                    subplot(2,3,1)
                else
                    subplot(2,3,4)
                end
                hold on
                bar(RR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg: Baseline Error Clamp'])
                ylabel('Error (m)')
                legend({'Short', 'Medium', 'Long'})
                xlabel('Set')
                ylim([-0.255 0.255])
                line([0 6.3 ], [mean(RR{adapt}(:, 1)) mean(RR{adapt}(:, 1))])
                line([0 6.3 ], [mean(RR{adapt}(:, 3)) mean(RR{adapt}(:, 3))])
            end
            
            for z = adapt(1) %for z = 3%1:length(filename)
                figure(5)
                if this.fastleg == 'l'
                    subplot(2,3,1)
                else
                    subplot(2,3,4)
                end
                hold on
                bar(LL{z})
                xlabel('Set')
                title([this.subjectcode ' SlowLeg: Baseline Error Clamp'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
                line([0 6.3 ], [mean(LL{adapt}(:, 1)) mean(LL{adapt}(:, 1))])
                line([0 6.3 ], [mean(LL{adapt}(:, 3)) mean(LL{adapt}(:, 3))])
            end
            
            for z = wash(1) %for z = 4%1:length(filename)
                figure(5)
                if this.fastleg == 'r'
                    subplot(2,3,2)
                else
                    subplot(2,3,5)
                end
                hold on
                bar(RR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg: Post-Adaptation Error Clamp'])
                ylabel('Error (m)')
                xlabel('Set')
                ylim([-0.255 0.255])
                
            end
            
            for z = wash(1) %for z = 4%1:length(filename)
                figure(5)
                if this.fastleg == 'l'
                    subplot(2,3,2)
                else
                    subplot(2,3,5)
                end
                hold on
                bar(LL{z})
                xlabel('Set')
                title([this.subjectcode ' SlowLeg: Post Adaptation Error Clamp'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
            end
            
            for z = 1%for z = 1%1:length(filename)
                figure(5)
                if this.fastleg == 'r'
                    subplot(2,3,3)
                else
                    subplot(2,3,6)
                end
                hold on
                %bar(RR{z})
                bar(DDR{z})
                h = h+length(rhits{z});
                title([this.subjectcode ' Fastleg Error Clamp (Washtout-Baseline)'])
                ylabel('Error (m)')
                %legend({'Short', 'Medium', 'Long'})
                
                xlabel('Set')
                ylim([-0.255 0.255])
            end
            
            for z = 1 %for z = 1%1:length(filename)
                figure(5)
                if this.fastleg == 'l'
                    subplot(2,3,3)
                else
                    subplot(2,3,6)
                end
                hold on
                bar(DDL{z})
                xlabel('Set')
                
                title([this.subjectcode ' SlowLeg Error Clamp (Washtout-Baseline)'])
                ylabel('Error (m)')
                h = h+length(lhits{z});
                ylim([-0.255 0.255])
            end
        end
        
    end
end
