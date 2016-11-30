classdef BiofeedbackSL_c3d
    %Class BiofeedbackMD houses metadata and methods to process step length
    %biofeedback trials
    %
    %Properties:
    %
    %   subjectcode = '' string containing subject code, e.g. 'SLP001'
    %   date=''  Date of the experiment, lab date object
    %   day='' string that indicates day1 or day2 testing
    %   sex = '' string designates subject sex e.g. 'f'
    %   dob='' lab date object with date of birth
    %   dominantleg='' string designate dominant leg, e.g. 'r'
    %   dominanthand = '' string designate dominant hand e.g. 'r'
    %   height=[];  cm
    %   weight=[];  kg
    %   age=[];  years
    % 
    %   triallist={};  cell array of trial #'s, filenames, and type of
    %   trial. construct instance with blank cell, can input data using a
    %   method instead of copying and pasting into inputs
    % 
    %   Rtmtarget=[]; right leg step length target as determined by treadmill baseline
    % 
    %   Ltmtarget=[]; left leg step length target as determined by treadmill baseline
    % 
    %   OGsteplength=[]; step length target as determined by over-ground walking
    % 
    %	OGspeed=[]; average speed of subject during the OG trial to determine OG steplength
    % 
    %Methods:       
    % 
    %   AnalyzePerformance(flag) -- computes step length errors for each
    %                               biofeedback trial, 
    %
    %   editTriallist() -- select filenames, edit trial #'s and type and
    %                      category, input num is the # of trials, or rows in the list
    %
    %   saveit() -- saves the instance with filename equal to the ID
    %
    %   comparedays() -- makes bar plots comparing day1 and day2

    
    properties
        subjectcode = ''
        date=''
        day=''
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
        OGsteplength=[];
        OGspeed=[];
        datalocation=pwd;
        data={};
        dataheader={};
        
        
    end
    
    methods
        %constuctor
        function this=BiofeedbackSL_c3d(ID,date,day,sex,dob,dleg,dhand,fastleg,height,weight,age,triallist,Rtarget,Ltarget,OGsteplength,OGspeed)
        
            if nargin ~= 16
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
                    
                if isnumeric(OGsteplength)
                    this.OGsteplength = OGsteplength;
                else
                    cprintf('err','WARNING: OG step length target is not numeric type.\n');
                    this.OGsteplength = [];
                end
                
                if isnumeric(OGspeed)
                    this.OGspeed = OGspeed;
                else
                    cprintf('err','WARNING: OG speed is not numeric type.\n');
                    this.OGspeed = [];
                end
                
            end

            
            
        end
        
        function []=AnalyzePerformance(this)
            %compute step length error for each trial, uses instance
            %defined target values and the default tolerance of 0.0375 m
            %
            %auto-saves the results

            global RX
            global LX
            
            if isempty(this.triallist)
                cprintf('err','WARNING: no trial information available to analyze');
            else
               filename = this.triallist(:,1);

               if iscell(filename)%if more than one file is selected for analysis

                   RX = {0};
                   LX = {0};
                   rlqr = {0};
                   llqr = {0};
                   WB = waitbar(0,'Processing Trials...');
                   for z = 1:length(filename)
                       tempname = filename{z};
                       waitbar((z-1)/length(filename),WB,['Processing Trial ' num2str(z)]);
                       if strcmp(this.triallist(z,3),'train')
                           color{z} = 'blue';
                       else
                           color{z} = 'red';
                       end
                       
                       %check to see if data is already processed, it will
                       %save time...
                       if length(this.data)<z
                           disp('Parsing data...');
                           H = btkReadAcquisition(tempname);
                           [analogs, ~] = btkGetAnalogs(H);
                           [markers, markerinfo] = btkGetMarkers(H);
                           btkCloseAcquisition(H);
                           
                           if markerinfo.frequency == 120
                               step = 1/1080;
                               step2 = 1/120;
                           else
                               step = 1/1000;
                               step2 = 1/100;
                           end
                           
                           Rfz = analogs.Force_Fz2;
                           Lfz = analogs.Force_Fz1;
                           
                           Xq = 0:step:length(Rfz)*step;
                           Xq(end) = [];
                           try
                           RHIP = markers.RHIP;
                           LHIP = markers.LHIP;
                           catch
                               RHIP = markers.RGT;
                               LHIP = markers.LGT;
                               
                           end
                           RANK = markers.RANK;
                           LANK = markers.LANK;
                           
                           X = 0:step2:length(RHIP)*step2;
                           X(end) = [];
                           
                           RHIP = interp1(X,RHIP,Xq);
                           LHIP = interp1(X,LHIP,Xq);
                           RANK = interp1(X,RANK,Xq);
                           LANK = interp1(X,LANK,Xq);
%                            keyboard
                           data = [Rfz Lfz RHIP LHIP RANK LANK];
%                            keyboard
                           
                       else
                           data = cell2mat(this.data(z));
                           header = this.dataheader;
                       end
                       
                       Rfz = data(:,1);
                       Lfz = data(:,2);
                       RHIP = data(:,4);
                       LHIP = data(:,7);
                       RANK = data(:,10);
                       LANK = data(:,13);
                       %detect HS
                       for zz = 1:length(Rfz)-1
                           if Rfz(zz) > -20 && Rfz(zz+1) <= -20 && Rfz(zz-5) == 0
                               RHS(zz) = 1;
                           else
                               RHS(zz) = 0;
                           end
                       end
                       [~,trhs] = findpeaks(RHS,'MinPeakDistance',1000);
                       RHS = zeros(length(RHS),1);
                       RHS(trhs) = 1;
                       for zz = 1:length(Lfz)-1
                           if Lfz(zz) > -20 && Lfz(zz+1) <= -20 && Lfz(zz-5) == 0
                               LHS(zz) = 1;
                           else
                               LHS(zz) = 0;
                           end
                       end
                       [~,tlhs] = findpeaks(LHS,'MinPeakDistance',1000);
                       LHS = zeros(length(LHS),1);
                       LHS(tlhs) = 1;
                       
                       HIP = (RHIP+LHIP)./2;
%                        keyboard
                       %%!!!!!!!!!!!!!!!!!!!!!!!%%!!!!!!!!!!!!!!!!!%%%!!!!!!!!!!!!!!!!
                       %calculate errors
                       temp1 = HIP(find(RHS))-RANK(find(RHS));%Ralpha
                       temp2 = HIP(find(LHS))-LANK(find(LHS));%Lalpha
                       temp1(temp1<0)=[];
                       temp2(temp2<0)=[];
                       
                       temp3 = LANK(find(RHS))-HIP(find(RHS));% RX
                       temp4 = RANK(find(LHS))-HIP(find(LHS));% LX
                       temp3(temp3<0)=[];
                       temp4(temp4<0)=[];
                       
                       Ralpha{z} = temp1/1000;
                       Lalpha{z} = temp2/1000;
                       RX{z} = temp3/1000;
                       LX{z} = temp4/1000;
                       
                       
                        clear RHS LHS temp1 temp2 temp3 temp4
                   end
                   
                   this.saveit();
                   
                   waitbar(1,WB,'Processing complete...');
                   pause(0.5);
                   close(WB);
                   clear z
                   
                   %load triallist to look for categories
                   tlist = this.triallist;
                   
                   train = find(strcmp(tlist(:,4),'training'));%logicals of where training trials are
                   base = find(strcmp(tlist(:,4),'baseline'));
                   adapt = find(strcmp(tlist(:,4),'adaptation'));
                   wash = find(strcmp(tlist(:,4),'washout'));
                   
                   figure(2)
                   if this.fastleg == 'r'
                       subplot(2,1,1)
                       grid on
                   else
                       subplot(2,1,2)
                       grid on
                   end
                   hold on
                   fill([0 length(cell2mat(RX(train)')) length(cell2mat(RX(train)')) 0],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   fill([length(cell2mat(RX(train)'))+length(cell2mat(RX(base)')) length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)')) length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)')) length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   %add baseline walking bars
                   for b=1:2:length(base)
                       fill([length(cell2mat(RX(train)'))+length(cell2mat(RX(base(1:b))'))-0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base(1:b))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base(1:b))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base(1:b))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(RX(train)'))+length(cell2mat(RX(base(1:b))')),0.125,'Base');
                   end
                   %add adaptation walking bars
                   for a=1:2:length(adapt)
                       fill([length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt(1:a))'))-0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt(1:a))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt(1:a))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt(1:a))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt(1:a))')),0.125,'Split');
                   end
                   %add washout walking bars
                   for w=1:2:length(wash)
                       fill([length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)'))+length(cell2mat(RX(wash(1:w))'))-0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)'))+length(cell2mat(RX(wash(1:w))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)'))+length(cell2mat(RX(wash(1:w))'))+0.15 length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)'))+length(cell2mat(RX(wash(1:w))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(RX(train)'))+length(cell2mat(RX(base)'))+length(cell2mat(RX(adapt)'))+length(cell2mat(RX(wash(1:w))')),0.125,'Wash');
                   end
                   h = 0;
                   for z = 1:length(filename)
                       figure(2)
                       if this.fastleg == 'r'
                           subplot(2,1,1)
                       else
                           subplot(2,1,2)
                       end
                       hold on
                       scatter([1:length(RX{z})]+h,RX{z},75,color{z},'fill');
%                        plot([h h+length(RX{z})],[0.0375 0.0375],'k');%tolerance lines
%                        plot([h h+length(RX{z})],[-0.0375 -0.0375],'k');
%                        plot([h h+length(RX{z})],[nanmean(RX{z})+rlqr{z}/2 nanmean(RX{z})+rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
%                        plot([h h+length(RX{z})],[nanmean(RX{z})-rlqr{z}/2 nanmean(RX{z})-rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(RX{z});
                   end
                   figure(2)
                   if this.fastleg == 'r'
                       subplot(2,1,1)
                       title([this.subjectcode ' X Fast Leg']);
                   else
                       subplot(2,1,2)
                       title([this.subjectcode ' X Slow Leg']);
                   end
                   ylim([0 0.49]);
                   xlim([0 h+10]);
%                    title([this.subjectcode ' Step Length Error Fast Leg']);
                   xlabel('step #');
                   ylabel('X (m)');
                   figure(2)
                   if this.fastleg == 'l'
                       subplot(2,1,1)
                   else
                       subplot(2,1,2)
                   end
                   hold on
                   fill([0 length(cell2mat(LX(train)')) length(cell2mat(LX(train)')) 0],[0.5 0.5 0 0],[230 230 230]./256);
                   fill([length(cell2mat(LX(train)'))+length(cell2mat(LX(base)')) length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)')) length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)')) length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   %add baseline walking bars
                   for b=1:2:length(base)
                       fill([length(cell2mat(LX(train)'))+length(cell2mat(LX(base(1:b))'))-0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base(1:b))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base(1:b))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base(1:b))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(LX(train)'))+length(cell2mat(LX(base(1:b))')),0.125,'Base');
                   end
                   %add adaptation walking bars
                   for a=1:2:length(adapt)
                       fill([length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt(1:a))'))-0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt(1:a))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt(1:a))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt(1:a))'))-0.15],[0.5 0.5 -0.5 -0.5],[20 20 20]./256);
                       text(length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt(1:a))')),0.125,'Split');
                   end
                   %add washout walking bars
                   for w=1:2:length(wash)
                       fill([length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)'))+length(cell2mat(LX(wash(1:w))'))-0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)'))+length(cell2mat(LX(wash(1:w))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)'))+length(cell2mat(LX(wash(1:w))'))+0.15 length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)'))+length(cell2mat(LX(wash(1:w))'))-0.15],[0.5 0.5 -0.5 -0.5],[20 20 20]./256);
                       text(length(cell2mat(LX(train)'))+length(cell2mat(LX(base)'))+length(cell2mat(LX(adapt)'))+length(cell2mat(LX(wash(1:w))')),0.125,'Wash');
                   end
                   h = 0;
                   for z = 1:length(filename)
                       figure(2)
                       if this.fastleg == 'l'
                           subplot(2,1,1)
                       else
                           subplot(2,1,2)
                       end
                       scatter([1:length(LX{z})]+h,LX{z},75,color{z},'fill');
%                        plot([h h+length(LX{z})],[0.0375 0.0375],'k');%tolerance lines
%                        plot([h h+length(LX{z})],[-0.0375 -0.0375],'k');
%                        plot([h h+length(LX{z})],[nanmean(LX{z})+llqr{z}/2 nanmean(LX{z})+llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
%                        plot([h h+length(LX{z})],[nanmean(LX{z})-llqr{z}/2 nanmean(LX{z})-llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(LX{z});
                   end
                   figure(2)
                   if this.fastleg == 'l'
                       subplot(2,1,1)
                       title([this.subjectcode ' X Fast Leg']);
                   else
                       subplot(2,1,2)
                       title([this.subjectcode ' X Slow Leg']);
                   end
                   ylim([0 0.49]);
                   xlim([0 h+10]);
                   xlabel('step #');
                   ylabel('X (m)');
                   grid on
                   
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   
                   figure(3)
                   if this.fastleg == 'r'
                       subplot(2,1,1)
                       grid on
                   else
                       subplot(2,1,2)
                       grid on
                   end
                   hold on
                   fill([0 length(cell2mat(Ralpha(train)')) length(cell2mat(Ralpha(train)')) 0],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   fill([length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)')) length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)')) length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)')) length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   %add baseline walking bars
                   for b=1:2:length(base)
                       fill([length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base(1:b))'))-0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base(1:b))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base(1:b))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base(1:b))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base(1:b))')),0.125,'Base');
                   end
                   %add adaptation walking bars
                   for a=1:2:length(adapt)
                       fill([length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt(1:a))'))-0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt(1:a))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt(1:a))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt(1:a))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt(1:a))')),0.125,'Split');
                   end
                   %add washout walking bars
                   for w=1:2:length(wash)
                       fill([length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)'))+length(cell2mat(Ralpha(wash(1:w))'))-0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)'))+length(cell2mat(Ralpha(wash(1:w))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)'))+length(cell2mat(Ralpha(wash(1:w))'))+0.15 length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)'))+length(cell2mat(Ralpha(wash(1:w))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(Ralpha(train)'))+length(cell2mat(Ralpha(base)'))+length(cell2mat(Ralpha(adapt)'))+length(cell2mat(Ralpha(wash(1:w))')),0.125,'Wash');
                   end
                   h = 0;
                   for z = 1:length(filename)
                       figure(3)
                       if this.fastleg == 'r'
                           subplot(2,1,1)
                       else
                           subplot(2,1,2)
                       end
                       hold on
                       scatter([1:length(Ralpha{z})]+h,Ralpha{z},75,color{z},'fill');
%                        plot([h h+length(Ralpha{z})],[0.0375 0.0375],'k');%tolerance lines
%                        plot([h h+length(Ralpha{z})],[-0.0375 -0.0375],'k');
%                        plot([h h+length(Ralpha{z})],[nanmean(Ralpha{z})+rlqr{z}/2 nanmean(Ralpha{z})+rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
%                        plot([h h+length(Ralpha{z})],[nanmean(Ralpha{z})-rlqr{z}/2 nanmean(Ralpha{z})-rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(Ralpha{z});
                   end
                   figure(3)
                   if this.fastleg == 'r'
                       subplot(2,1,1)
                       title([this.subjectcode ' Alpha Fast Leg']);
                   else
                       subplot(2,1,2)
                       title([this.subjectcode ' Alpha Slow Leg']);
                   end
                   ylim([0 0.49]);
                   xlim([0 h+10]);
%                    title([this.subjectcode ' Step Length Error Fast Leg']);
                   xlabel('step #');
                   ylabel('Alpha (m)');
                   figure(3)
                   if this.fastleg == 'l'
                       subplot(2,1,1)
                   else
                       subplot(2,1,2)
                   end
                   hold on
                   fill([0 length(cell2mat(Lalpha(train)')) length(cell2mat(Lalpha(train)')) 0],[0.5 0.5 0 0],[230 230 230]./256);
                   fill([length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)')) length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)')) length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)')) length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))],[0.5 0.5 -0.5 -0.5],[230 230 230]./256);
                   %add baseline walking bars
                   for b=1:2:length(base)
                       fill([length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base(1:b))'))-0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base(1:b))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base(1:b))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base(1:b))'))-0.15],[0.5 0.5 0 0],[20 20 20]./256);
                       text(length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base(1:b))')),0.125,'Base');
                   end
                   %add adaptation walking bars
                   for a=1:2:length(adapt)
                       fill([length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt(1:a))'))-0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt(1:a))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt(1:a))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt(1:a))'))-0.15],[0.5 0.5 -0.5 -0.5],[20 20 20]./256);
                       text(length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt(1:a))')),0.125,'Split');
                   end
                   %add washout walking bars
                   for w=1:2:length(wash)
                       fill([length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)'))+length(cell2mat(Lalpha(wash(1:w))'))-0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)'))+length(cell2mat(Lalpha(wash(1:w))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)'))+length(cell2mat(Lalpha(wash(1:w))'))+0.15 length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)'))+length(cell2mat(Lalpha(wash(1:w))'))-0.15],[0.5 0.5 -0.5 -0.5],[20 20 20]./256);
                       text(length(cell2mat(Lalpha(train)'))+length(cell2mat(Lalpha(base)'))+length(cell2mat(Lalpha(adapt)'))+length(cell2mat(Lalpha(wash(1:w))')),0.125,'Wash');
                   end
                   h = 0;
                   for z = 1:length(filename)
                       figure(3)
                       if this.fastleg == 'l'
                           subplot(2,1,1)
                       else
                           subplot(2,1,2)
                       end
                       scatter([1:length(Lalpha{z})]+h,Lalpha{z},75,color{z},'fill');
%                        plot([h h+length(Lalpha{z})],[0.0375 0.0375],'k');%tolerance lines
%                        plot([h h+length(Lalpha{z})],[-0.0375 -0.0375],'k');
%                        plot([h h+length(Lalpha{z})],[nanmean(Lalpha{z})+llqr{z}/2 nanmean(Lalpha{z})+llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
%                        plot([h h+length(Lalpha{z})],[nanmean(Lalpha{z})-llqr{z}/2 nanmean(Lalpha{z})-llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(Lalpha{z});
                   end
                   figure(3)
                   if this.fastleg == 'l'
                       subplot(2,1,1)
                       title([this.subjectcode ' Alpha Fast Leg']);
                   else
                       subplot(2,1,2)
                       title([this.subjectcode ' Alpha Slow Leg']);
                   end
                   ylim([0 0.49]);
                   xlim([0 h+10]);
                   xlabel('step #');
                   ylabel('Alpha (m)');
                   grid on
                   
%                    for z=1:length(RX)
%                        temp = RX{z};
%                        temp(abs(temp) > 0.1) = [];
%                        meanRX1(z) = mean(temp);
%                        stdRX1(z) = std(temp);
%                        rscore(z) = length(temp(abs(temp)<0.0375))/length(temp);
%                    end
%                    for z=1:length(LX)
%                        temp = LX{z};
%                        temp(abs(temp) > 0.1) = [];
%                        meanLX1(z) = mean(temp);
%                        stdLX1(z) = std(temp);
%                        lscore(z) = length(temp(abs(temp)<0.0375))/length(temp);
%                    end
%                    
                   
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
                    %                     for z=1:length(filenames)%autodetect if a trial was a train for evaluation
%                         tname = filenames{z};
%                         if strcmp(tname(end-5:end-4),'V3')
%                             data{z,3} = 'train';
%                         else
%                             data{z,3} = 'eval';
%                         end
%                     end

                    
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
%                     if strcmp(filenames(end-5:end-4),'V3')
%                         data(1,3) = 'train';
%                     else
%                         data(1,3) = 'eval';
%                     end
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
        
%         function []=comparedays(this,flag)
            
        end
            
  
    
end

