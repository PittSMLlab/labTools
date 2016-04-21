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
                
                if isnumeric(day)
                    this.day = day;
                else
                    cprintf('err','WARNING: input for day must be a number\n');
                    this.day='';
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
                    cprintf('err','WARNING: input weight is not class labDate\n');
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
            %compute step length error for each trial, uses instance
            %defined target values and the default tolerance of 0.0375 m
            %
            %auto-saves the results
            
            global rhits
            global lhits
            
            if isempty(this.triallist)
                cprintf('err','WARNING: no trial information available to analyze');
            else
                filename = this.triallist(:,1);
                
                if iscell(filename)%if more than one file is selected for analysis
                    
                    rhits = {0};
                    lhits = {0};
                    rlqr = {0};
                    llqr = {0};
                    color = {};
                    WB = waitbar(0,'Processing Trials...');
                    for z = 1:length(filename)
                        tempname = filename{z};
                        waitbar((z-1)/length(filename),WB,['Processing Trial ' num2str(z)]);
                        %                        if strcmp(tempname(end-5:end-4),'V3') || strcmp(tempname(end-14:end-13),'V7')
                        %                            color{z} = 'blue';
                        %                        elseif strcmp(tempname(end-10:end-4),'rev12V1')
                        %                            color{z} = 'yellow';
                        %                        else
                        %                            color{z} = 'red';
                        %                        end
                        
                        %                        markerFaceColors={'r','b',[1,.8,0],'g','y','w','c','m','k'};
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
                        %                        keyboard
                        
                        
                        %check to see if data is already processed, it will
                        %save time...
                        if length(this.data)<z
                            disp('Parsing data...');
                            [header,data] = JSONtxt2cell(filename{z});
                            
                            this.data{z} = data;
                            this.dataheader = header;
                            
                        else
                            data = cell2mat(this.data(z));
                            header = this.dataheader;
                        end
                        [~,n] = size(data);
                        %                        keyboard
                        data2 = unique(data,'rows','stable');%remove duplicate frames
                        data2(:,1) = data2(:,1)-data2(1,1)+1;%set frame # to start at 1
                        
                        %check for monotonicity
                        checkers = find(diff(data2(:,1))<1);
                        while ~isempty(checkers)
                            for y=1:length(checkers)
                                data2(checkers(y),:)=[];
                            end
                            checkers = find(diff(data2(:,1))<1);
                        end
                        %                        keyboard
                        for zz = 1:n
                            data3(data2(:,1),zz) = data2(:,zz);
                        end
                        frame = data3(:,1);
                        frame2 = 1:1:data2(end,1);
                        %                        keyboard
                        Rz2 = interp1(data2(:,1),data2(:,2),frame2,'linear');
                        Lz2 = interp1(data2(:,1),data2(:,3),frame2,'linear');
                        Rgamma2 = interp1(data2(:,1),data2(:,10),frame2,'linear');
                        Lgamma2 = interp1(data2(:,1),data2(:,11),frame2,'linear');
                        target = interp1(data2(:,1),data2(:,14),frame2,'linear');
                        
                        %detect HS
                        for zz = 1:length(Rz2)-1
                            if Rz2(zz) > -10 && Rz2(zz+1) <= -10
                                RHS(zz) = 1;
                            else
                                RHS(zz) = 0;
                            end
                        end
                        [~,trhs] = findpeaks(RHS,'MinPeakDistance',100);
                        RHS = zeros(length(RHS),1);
                        RHS(trhs) = 1;
                        for zz = 1:length(Lz2)-1
                            if Lz2(zz) > -10 && Lz2(zz+1) <= -10
                                LHS(zz) = 1;
                            else
                                LHS(zz) = 0;
                            end
                        end
                        [~,tlhs] = findpeaks(LHS,'MinPeakDistance',100);
                        LHS = zeros(length(LHS),1);
                        LHS(tlhs) = 1;
                        %                        keyboard
                        %%!!!!!!!!!!!!!!!!!!!!!!!%%!!!!!!!!!!!!!!!!!%%%!!!!!!!!!!!!!!!!
                        %calculate errors
                        %                        tamp = abs(Rgamma2(find(RHS)))'-this.Rtmtarget;
                        %                        tamp2 = abs(Lgamma2(find(LHS)))'-this.Ltmtarget;
                        tamp = Rgamma2(find(RHS))-target(find(RHS)-1);
                        tamp2 = Lgamma2(find(LHS))-target(find(LHS)-1);
                        tamp3 = target(find(RHS));
                        tamp4 = target(find(LHS));
                        
                        %delete 5 strides at each transistion
                        K = find(diff(tamp3));
                        K2 = find(diff(tamp4));
                        for y = 1:length(K)
                            tamp(K(y):K(y)+5)=100;
                            tamp3(K(y):K(y)+5)=100;
                        end
                        for y = 1:length(K2)
                            tamp2(K2(y):K2(y)+5)=100;
                            tamp4(K2(y):K2(y)+5)=100;
                        end
                        tamp(tamp==100)=[];
                        tamp2(tamp2==100)=[];
                        tamp3(tamp3==100)=[];
                        tamp4(tamp4==100)=[];
                        
                        rhits{z} = tamp;
                        lhits{z} = tamp2;
                        rts{z} = tamp3;
                        lts{z} = tamp4;
                        
                        %                        rlqr{z} = iqr(rhits{z});
                        %                        llqr{z} = iqr(lhits{z});
                        clear RHS LHS tamp tamp2
                    end
                    
                    this.saveit();
                    
                    waitbar(1,WB,'Processing complete...');
                    pause(0.5);
                    close(WB);
                    clear z
                    
                    %load triallist to look for categories
                    tlist = this.triallist;
                    
                    train = find(strcmp(tlist(:,4),'Familiarization'));%logicals of where training trials are
                    base = find(strcmp(tlist(:,4),'Base Map'));
                    adapt = find(strcmp(tlist(:,4),'Base Clamp'));
                    wash = find(strcmp(tlist(:,4),'Post Clamp'));
                    wash2 = find(strcmp(tlist(:,4),'Post Map'));
%                     keyboard
                    figure(2)
                    if this.fastleg == 'r'
                        subplot(2,1,1)
                    else
                        subplot(2,1,2)
                    end
                    hold on
                    %                    keyboard
                    fill([0 length(cell2mat(rhits(train))) length(cell2mat(rhits(train))) 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    fill([length(cell2mat(rhits(train)))+length(cell2mat(rhits(base))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    fill([length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash)))+length(cell2mat(rhits(wash2))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash)))+length(cell2mat(rhits(wash2))) length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash)))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    
%                     add baseline walking bars
%                     for b=1:2:length(base)
%                         fill([length(cell2mat(rhits(train)))+length(cell2mat(rhits(base(1:b))))-0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base(1:b))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base(1:b))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base(1:b))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(rhits(train)))+length(cell2mat(rhits(base(1:b)))),0.125,'Base');
%                     end
%                     
%                     add adaptation walking bars
%                     for a=1:2:length(adapt)
%                         fill([length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt(1:a))))-0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt(1:a))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt(1:a))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt(1:a))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt(1:a)))),0.125,'Split');
%                     end
%                     
%                     add washout walking bars
%                     for w=1:2:length(wash)
%                         fill([length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash(1:w))))-0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash(1:w))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash(1:w))))+0.5 length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash(1:w))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(rhits(train)))+length(cell2mat(rhits(base)))+length(cell2mat(rhits(adapt)))+length(cell2mat(rhits(wash(1:w)))),0.125,'Wash');
%                     end
                    
                    
                    h = 0;
                    for z = 1:length(filename)
                        figure(2)
                        if this.fastleg == 'r'
                            subplot(2,1,1)
                        else
                            subplot(2,1,2)
                        end
                        hold on
%                         scatter([1:length(rhits{z})]+h,rhits{z},75,color{z},'fill','MarkerEdgeColor','k');
                        gscatter([1:length(rhits{z})]+h,rhits{z},rts{z},color{z},['s','o','d']);
                        g = gscatter([1:length(rhits{z})]+h,rhits{z},rts{z},color{z},['s','o','d']);
                        for y = 1:length(g)
                            set(g(y),'MarkerFaceColor',color{z});
                            set(g(y),'MarkerEdgeColor','k');
                        end
                        plot([h h+length(rhits{z})],[0.02 0.02],'k');%tolerance lines
                        plot([h h+length(rhits{z})],[-0.02 -0.02],'k');
                        %                        plot([h h+length(rhits{z})],[nanmean(rhits{z})+rlqr{z}/2 nanmean(rhits{z})+rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                        %                        plot([h h+length(rhits{z})],[nanmean(rhits{z})-rlqr{z}/2 nanmean(rhits{z})-rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                        h = h+length(rhits{z});
                    end
                    figure(2)
                    if this.fastleg == 'r'
                        subplot(2,1,1)
                        title([this.subjectcode ' Step Length Error Fast Leg']);
                    else
                        subplot(2,1,2)
                        title([this.subjectcode ' Step Length Error Slow Leg']);
                    end
                    ylim([-0.15 0.15]);
                    xlim([0 h+10]);
                    %                    title([this.subjectcode ' Step Length Error Fast Leg']);
                    xlabel('step #');
                    ylabel('Error (m)');
                    
                    figure(2)
                    if this.fastleg == 'l'
                        subplot(2,1,1)
                    else
                        subplot(2,1,2)
                    end
                    hold on
                    fill([0 length(cell2mat(lhits(train))) length(cell2mat(lhits(train))) 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    fill([length(cell2mat(lhits(train)))+length(cell2mat(lhits(base))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    fill([length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash)))+length(cell2mat(lhits(wash2))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash)))+length(cell2mat(lhits(wash2))) length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash)))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    
%                     %add baseline walking bars
%                     for b=1:2:length(base)
%                         fill([length(cell2mat(lhits(train)))+length(cell2mat(lhits(base(1:b))))-0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base(1:b))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base(1:b))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base(1:b))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(lhits(train)))+length(cell2mat(lhits(base(1:b)))),0.125,'Base');
%                     end
%                     
%                     %add adaptation walking bars
%                     for a=1:2:length(adapt)
%                         fill([length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt(1:a))))-0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt(1:a))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt(1:a))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt(1:a))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt(1:a)))),0.125,'Split');
%                     end
%                     
%                     %add washout walking bars
%                     for w=1:2:length(wash)
%                         fill([length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash(1:w))))-0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash(1:w))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash(1:w))))+0.5 length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash(1:w))))-0.5],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
%                         text(length(cell2mat(lhits(train)))+length(cell2mat(lhits(base)))+length(cell2mat(lhits(adapt)))+length(cell2mat(lhits(wash(1:w)))),0.125,'Wash');
%                     end
                    
                    h = 0;
                    for z = 1:length(filename)
                        figure(2)
                        if this.fastleg == 'l'
                            subplot(2,1,1)
                        else
                            subplot(2,1,2)
                        end
%                         scatter([1:length(lhits{z})]+h,lhits{z},75,color{z},'fill','MarkerEdgeColor','k');
                        gscatter([1:length(lhits{z})]+h,lhits{z},lts{z},color{z},['s','o','d']);
                        g = gscatter([1:length(lhits{z})]+h,lhits{z},lts{z},color{z},['s','o','d']);
                        for y = 1:length(g)
                            set(g(y),'MarkerFaceColor',color{z});
                            set(g(y),'MarkerEdgeColor','k');
                        end
                        plot([h h+length(lhits{z})],[0.02 0.02],'k');%tolerance lines
                        plot([h h+length(lhits{z})],[-0.02 -0.02],'k');
                        %                        plot([h h+length(lhits{z})],[nanmean(lhits{z})+llqr{z}/2 nanmean(lhits{z})+llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                        %                        plot([h h+length(lhits{z})],[nanmean(lhits{z})-llqr{z}/2 nanmean(lhits{z})-llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                        h = h+length(lhits{z});
                        %         h = h+length(lhits{z});
                    end
                    figure(2)
                    if this.fastleg == 'l'
                        subplot(2,1,1)
                        title([this.subjectcode ' Step Length Error Fast Leg']);
                    else
                        subplot(2,1,2)
                        title([this.subjectcode ' Step Length Error Slow Leg']);
                    end
                    ylim([-0.15 0.15]);
                    xlim([0 h+10]);
                    %                    title([this.subjectcode ' Step Length Error Slow Leg']);
                    xlabel('step #');
                    ylabel('Error (m)');
                    
                    
                    %                     keyboard
                    %                         for z=1:length(rhits)
                    %                             temp = rhits{z};
                    %                             temp(abs(temp) > 0.1) = [];
                    %                             meanrhits1(z) = mean(temp);
                    %                             stdrhits1(z) = std(temp);
                    %                             %                        keyboard
                    %                             rscore(z) = length(temp(abs(temp)<0.0375))/length(temp);
                    %                             %                        meanrhits2(z) = mean(temp(end-2:end));
                    %                             %                        stdrhits2(z) = std(temp(end-2:end));
                    %                         end
                    %                         for z=1:length(lhits)
                    %                             temp = lhits{z};
                    %                             temp(abs(temp) > 0.1) = [];
                    %                             meanlhits1(z) = mean(temp);
                    %                             stdlhits1(z) = std(temp);
                    %                             lscore(z) = length(temp(abs(temp)<0.0375))/length(temp);
                    %                             %                        meanlhits2(z) = mean(temp(end-2:end));
                    %                             %                        stdlhits2(z) = std(temp(end-2:end));
                    %                         end
                    %
                    %                    figure(5)
                    %                    if this.fastleg == 'r'
                    %                        subplot(2,1,1)
                    %                    else
                    %                        subplot(2,1,2)
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,0.125,'Base');
                    %                    end
                    %
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,0.125,'Split');
                    %                    end
                    %
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,0.125,'Wash');
                    %                    end
                    %
                    %                    h = 1:1:length(meanrhits1);
                    % %                    h2 = 2:2:2*length(meanrhits2);
                    %                    errorbar(h,meanrhits1,stdrhits1,'k','LineWidth',1.5);
                    % %                    errorbar(h2,meanrhits2,stdrhits2,'k','LineWidth',1.5);
                    %                    plot([0 length(meanrhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                    %                    plot([0 length(meanrhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                    %                    %     plot([0 2*length(meanrhits1)+1],[nanmean(rhits{z})+rlqr{z} nanmean(rhits{z})+rlqr{z}]
                    %                    for z = 1:length(h)
                    %                        figure(5)
                    %                        if this.fastleg == 'r'
                    %                            subplot(2,1,1)
                    %                            title([this.subjectcode ' Fast Leg Errors']);
                    %                        else
                    %                            subplot(2,1,2)
                    %                            title([this.subjectcode ' Slow Leg Errors']);
                    %                        end
                    %                        bar(h(z),meanrhits1(z),0.5,'FaceColor',color{z});%color2(z,:));
                    %                    end
                    %                    ylim([-0.15 0.15]);
                    %                    xlim([0 length(meanrhits1)+0.5]);
                    % %                    title([this.subjectcode ' Fast Leg Errors']);
                    %                    ylabel('Error (m)');
                    %
                    %
                    %                    figure(5)
                    %                    if this.fastleg == 'l'
                    %                        subplot(2,1,1)
                    %                    else
                    %                        subplot(2,1,2)
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,0.125,'Base');
                    %                    end
                    %
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,0.125,'Split');
                    %                    end
                    %
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,0.125,'Wash');
                    %                    end
                    %
                    %                    h = 1:1:length(meanlhits1);
                    % %                    h2 = 2:2:2*length(meanlhits2);
                    %                    errorbar(h,meanlhits1,stdlhits1,'k','LineWidth',1.5);
                    % %                    errorbar(h2,meanlhits2,stdlhits2,'k','LineWidth',1.5);
                    %                    plot([0 length(meanlhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                    %                    plot([0 length(meanlhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                    %                    for z = 1:length(h)
                    %                        figure(5)
                    %                        if this.fastleg == 'l'
                    %                            subplot(2,1,1)
                    %                            title([this.subjectcode ' Fast Leg Errors'])
                    %                        else
                    %                            subplot(2,1,2)
                    %                            title([this.subjectcode ' Slow Leg Errors'])
                    %                        end
                    %                        bar(h(z),meanlhits1(z),0.5,'FaceColor',color{z});
                    %                    end
                    %                    ylim([-0.15 0.15]);
                    %                    xlim([0 length(meanrhits1)+0.5]);
                    % %                    title([this.subjectcode ' Slow Leg Errors'])
                    %                    ylabel('Error (m)');
                    %
                    %
                    %
                    %
                    %                    figure(6)%plot of mean squared errors
                    %                    if this.fastleg == 'r'
                    %                        subplot(2,1,1)
                    %                    else
                    %                        subplot(2,1,2)
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,max(meanrhits1.^2)+0.05*max(meanrhits1.^2),'Base');
                    %                    end
                    %
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,max(meanrhits1.^2)+0.1*max(meanrhits1.^2),'Split');
                    %                    end
                    %
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,max(meanrhits1.^2)+0.1*max(meanrhits1.^2),'Wash');
                    %                    end
                    %
                    %                    h = 1:1:length(meanrhits1);
                    %                    plot([0 length(meanrhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                    % %                    plot([0 length(meanrhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                    %                    %     plot([0 2*length(meanrhits1)+1],[nanmean(rhits{z})+rlqr{z} nanmean(rhits{z})+rlqr{z}]
                    %                    for z = 1:length(h)
                    %                        figure(6)
                    %                        if this.fastleg == 'r'
                    %                            subplot(2,1,1)
                    %                            title([this.subjectcode ' Fast Leg Errors']);
                    %                        else
                    %                            subplot(2,1,2)
                    %                            title([this.subjectcode ' Slow Leg Errors']);
                    %                        end
                    %                        bar(h(z),meanrhits1(z).^2,0.5,'FaceColor',color{z});%color2(z,:));
                    %                    end
                    %                    ylim([0 max(meanrhits1.^2)+0.1*max(meanrhits1.^2)]);
                    %                    xlim([0 length(meanrhits1)+0.5]);
                    %                    title([this.subjectcode ' Fast Leg Errors']);
                    %                    ylabel('Error (m)');
                    %
                    %                    figure(6)
                    %                    if this.fastleg == 'l'
                    %                        subplot(2,1,1)
                    %                    else
                    %                        subplot(2,1,2)
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                    %
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,max(meanlhits1.^2)+0.05*max(meanlhits1.^2),'Base');
                    %                    end
                    %
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,max(meanlhits1.^2)+0.05*max(meanlhits1.^2),'Split');
                    %                    end
                    %
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[0.1 0.1 -0.1 -0.1],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,max(meanlhits1.^2)+0.05*max(meanlhits1.^2),'Wash');
                    %                    end
                    %
                    %                    h = 1:1:length(meanlhits1);
                    %                    plot([0 length(meanlhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                    % %                    plot([0 length(meanlhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                    %                    for z = 1:length(h)
                    %                        figure(6)
                    %                        if this.fastleg == 'l'
                    %                            subplot(2,1,1)
                    %                            title([this.subjectcode ' Fast Leg Errors'])
                    %                        else
                    %                            subplot(2,1,2)
                    %                            title([this.subjectcode ' Slow Leg Errors'])
                    %                        end
                    %                        bar(h(z),meanlhits1(z).^2,0.5,'FaceColor',color{z});
                    %                    end
                    %                    ylim([0 max(meanlhits1.^2)+0.1*max(meanlhits1.^2)]);
                    %                    xlim([0 length(meanrhits1)+0.5]);
                    % %                    title([this.subjectcode ' Slow Leg Errors'])
                    %                    ylabel('Error (m)');
                    %
                    %
                    %                    figure(7)
                    %                    if this.fastleg == 'r'
                    %                        subplot(2,1,1)
                    %                        title([this.subjectcode ' Fast Leg Accuracy'])
                    %                    else
                    %                        subplot(2,1,2)
                    %                        title([this.subjectcode ' Slow Leg Accuracy'])
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[120 120 0 0],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[120 120 0 0],[230 230 230]./256);
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,105,'Base');
                    %                    end
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,105,'Split');
                    %                    end
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,105,'Wash');
                    %                    end
                    %                    plot([0 length(meanrhits1)+1],[80 80],'--k','LineWidth',2);%tolerance lines
                    %                    plot([0 length(meanrhits1)+1],[100 100],'k','LineWidth',1);%tolerance lines
                    %                    for z=1:length(rscore)
                    %                        bar(z,rscore(z)*100,0.5,'FaceColor',color{z});
                    %                    end
                    %                    ylim([0 110]);
                    %                    ylabel('Accuracy (%)')
                    % %                    title([this.subjectcode ' Fast Leg Accuracy'])
                    %
                    %                    if this.fastleg == 'l'
                    %                        subplot(2,1,1)
                    %                        title([this.subjectcode ' Fast Leg Accuracy'])
                    %                    else
                    %                        subplot(2,1,2)
                    %                        title([this.subjectcode ' Slow Leg Accuracy'])
                    %                    end
                    %                    hold on
                    %                    fill([0 length(train)+0.5 length(train)+0.5 0],[120 120 0 0],[230 230 230]./256);
                    %                    fill([length(train)+0.5+length(base) length(train)+length(base)+length(adapt)+0.5 length(train)+length(base)+length(adapt)+0.5 length(train)+0.5+length(base)],[120 120 0 0],[230 230 230]./256);
                    %                    %add baseline bars
                    %                    for b=1:2:length(base)
                    %                        fill([length(train)+length(base(1:b))+0.45 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.55 length(train)+length(base(1:b))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base(1:b))+0.45,105,'Base');
                    %                    end
                    %                    %add adaptation bars
                    %                    for a=1:2:length(adapt)
                    %                        fill([length(train)+length(base)+length(adapt(1:a))+0.45 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.55 length(train)+length(base)+length(adapt(1:a))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt(1:a))+0.45,105,'Split');
                    %                    end
                    %                    %add washout bars
                    %                    for w=1:2:length(wash)
                    %                        fill([length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.55 length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45],[100 100 0 0],[20 20 20]./256);
                    %                        text(length(train)+length(base)+length(adapt)+length(wash(1:w))+0.45,105,'Wash');
                    %                    end
                    %                    plot([0 length(meanlhits1)+1],[80 80],'--k','LineWidth',2);%tolerance lines
                    %                    plot([0 length(meanlhits1)+1],[100 100],'k','LineWidth',1);%tolerance lines
                    %                    for z=1:length(lscore)
                    %                        bar(z,lscore(z)*100,0.5,'FaceColor',color{z});
                    %                    end
                    %                    ylim([0 110]);
                    %                    ylabel('Accuracy (%)')
                    % %                    title([this.subjectcode ' Slow Leg Accuracy'])
                    
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
                savename = [this.subjectcode '_SLBF_day' num2str(this.day) '.mat'];
                eval([this.subjectcode '=this;']);
                save(savename,this.subjectcode);
            end
        end
        
    end
    
end

