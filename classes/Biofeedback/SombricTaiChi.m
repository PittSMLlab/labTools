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
            
            if nargin ~= 10
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
            
%             if this.fastleg == 'r'
%                 colors = {[14/255,201/255,52/255],[201/255,242/255,209/255],[2/255,184/255,245/255],[181/255,217/255,230/255],[35/255,21/255,232/255],[190/255,21/255,232/255],[232/255,21/255,24/255],[232/255,214/255,21/255]};
%             elseif this.fastleg == 'l'
% %                 colors = {[14/255,201/255,52/255],[201/255,242/255,209/255],[2/255,184/255,245/255],[181/255,217/255,230/255],[35/255,21/255,232/255],[190/255,21/255,232/255],[232/255,21/255,24/255],[232/255,214/255,21/255]};
%                 colors = {[2/255,184/255,245/255],[181/255,217/255,230/255],[14/255,201/255,52/255],[201/255,242/255,209/255],[35/255,21/255,232/255],[190/255,21/255,232/255],[232/255,21/255,24/255],[232/255,214/255,21/255]};
%             end
            
            [Xlat,Ysag]=this.getHits();
            [m,n]=size(Ysag);
            sage=cell(m,n);
            late=cell(m,n);
            h=0;
            h2 = 0;
            h3=0;
            h4=0;
%             keyboard
            for z=1:length(Ysag)
                
                if strcmp(this.triallist{z,4},'Rleg Train')
                    colors{z} = [189/255,15/255,18/255];%red
                elseif strcmp(this.triallist{z,4},'Lleg Train')
                    colors{z} = [189/255,15/255,18/255];%red
                elseif strcmp(this.triallist{z,4},'Base Rleg Map')
                    colors{z} = [48/255,32/255,158/255];%blue
                elseif strcmp(this.triallist{z,4},'Base Lleg Map')
                    colors{z} = [48/255,32/255,158/255];%blue
                elseif strcmp(this.triallist{z,4},'Pre Rleg Train')
                    colors{z} = [25/255,235/255,74/255];%green
                elseif strcmp(this.triallist{z,4},'Pre Lleg Train')
                    colors{z} = [25/255,235/255,74/255];%green
                elseif strcmp(this.triallist{z,4},'Post Rleg Map')
                    colors{z} = [9/255,109/255,143/255];%bluegrey
                elseif strcmp(this.triallist{z,4},'Post Lleg Map')
                    colors{z} = [9/255,109/255,143/255];%bluegrey
                end
                
                if ismember('R',this.triallist{z,4})
                    
                    temps = Ysag{z};
                    templ = Xlat{z};
                    temps = temps-this.Rtarget;
                    templ = templ-this.Rtarget;
                    
                    temps(abs(temps)>0.1)=[];
                    templ(abs(templ)>0.1)=[];
                    
                    sage{z} = temps;
                    late{z} = templ;
                    
                elseif ismember('L',this.triallist{z,4})
                    temps = Ysag{z};
                    templ = Xlat{z};
                    Xlat{z} = -1*templ;
                    temps = temps-this.Ltarget;
                    templ = -1*templ-this.Ltarget;
%                     keyboard
                    temps(abs(temps)>0.1)=[];
                    templ(abs(templ)>0.1)=[];
                    
                    sage{z} = temps;
                    late{z} = templ;
                    
                else
                    disp('no errors computed');
                    temps = 1000;
                    templ = 1000;
                end
%                 keyboard
                
                figure(2) %Saggital errors
                subplot(2,1,1)
                hold on
                scatter(h+[1:length(temps)],temps,'MarkerFaceColor',colors{z},'MarkerEdgeColor',colors{z});
                title('Saggital Target Errors');
                h = h+length(temps);
                plot([h h],[-1 1],'k');
                
                
                subplot(2,1,2)
                hold on
                scatter(h2+[1:length(templ)],templ,'MarkerFaceColor',colors{z},'MarkerEdgeColor',colors{z});
                title('Lateral Target Errors');
                h2 = h2+length(templ);
                plot([h2 h2],[-1 1],'k');
%                 plot([0 h2],[0.01 0.01],'--k');
%                 plot([0 h2],[-0.01 -0.01],'--k');
% %                 grid on
%                 ylim([-0.1 0.1]);
%                 ylabel('Step Error (m)');
                
                figure(3)
                subplot(2,1,1)
                hold on
                scatter(h3+[1:length(Ysag{z})],Ysag{z},'MarkerFaceColor',colors{z},'MarkerEdgeColor',colors{z});
                title('Saggital Landing Positions')
                h3 = h3+length(Ysag{z});
                plot([h3 h3],[-1 1],'k');
                if ismember('L',this.triallist{z,4})
                    plot([h3-length(Ysag{z}) h3],[this.Ltarget this.Ltarget],'k');
                    plot([h3-length(Ysag{z}) h3],[this.Ltarget+0.01 this.Ltarget+0.01],'--k');
                    plot([h3-length(Ysag{z}) h3],[this.Ltarget-0.01 this.Ltarget-0.01],'--k');
                elseif ismember('R',this.triallist{z,4})
                    plot([h3-length(Ysag{z}) h3],[this.Rtarget this.Rtarget],'k');
                    plot([h3-length(Ysag{z}) h3],[this.Rtarget+0.01 this.Rtarget+0.01],'--k');
                    plot([h3-length(Ysag{z}) h3],[this.Rtarget-0.01 this.Rtarget-0.01],'--k');
                end

                
                subplot(2,1,2)
                hold on
                scatter(h4+[1:length(Xlat{z})],Xlat{z},'MarkerFaceColor',colors{z},'MarkerEdgeColor',colors{z});
                title('Lateral Landing Positions')
                h4 = h4+length(Xlat{z});
                plot([h4 h4],[-1 1],'k');
                if ismember('L',this.triallist{z,4})
                    plot([h4-length(Xlat{z}) h4],[this.Ltarget this.Ltarget],'k');
                    plot([h4-length(Xlat{z}) h4],[this.Ltarget+0.01 this.Ltarget+0.01],'--k');
                    plot([h4-length(Xlat{z}) h4],[this.Ltarget-0.01 this.Ltarget-0.01],'--k');
                elseif ismember('R',this.triallist{z,4})
                    plot([h4-length(Xlat{z}) h4],[this.Rtarget this.Rtarget],'k');
                    plot([h4-length(Xlat{z}) h4],[this.Rtarget+0.01 this.Rtarget+0.01],'--k');
                    plot([h4-length(Xlat{z}) h4],[this.Rtarget-0.01 this.Rtarget-0.01],'--k');
                end

                
                
                
            end
            
            figure(2) %Saggital errors
            subplot(2,1,1)
            ylim([-0.1 0.1]);
            ylabel('Step Error (m)');
%             legend('Training','Map','Base Map','Pre train','Post Map');
            plot([0 h],[0 0],'k');
            plot([0 h],[0.01 0.01],'--k');
            plot([0 h],[-0.01 -0.01],'--k');
            subplot(2,1,2)
            plot([0 h2],[0 0],'k');
            plot([0 h2],[0.01 0.01],'--k');
            plot([0 h2],[-0.01 -0.01],'--k');
            ylim([-0.1 0.1]);
            ylabel('Step Error (m)');
            
            figure(3)
            subplot(2,1,1)
            ylim([0.1 0.4]);
            ylabel('Step Position (m)');
            
            subplot(2,1,2)
            ylim([0.1 0.4]);
            ylabel('Step Position (m)');
            
%             keyboard
            
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
                    data1 = cell(length(filenames),4);
                    data1(:,1)=filenames;
                    
                    for z=1:length(filenames)%autodetect if a trial was a train for evaluation
                        tname = filenames{z};
                        if strcmp(tname(end-5:end-4),'V1')
                            data1{z,3} = 'train';
                        else
                            data1{z,3} = 'eval';
                        end
                    end
                    %                     keyboard
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Pre Rleg Train','Pre Lleg Train','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data1,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data1 = cell(1,4);
                    data1(1,1) = filenames;
                    if strcmp(filenames(end-5:end-4),'V3')
                        data1(1,3) = 'train';
                    else
                        data1(1,3) = 'eval';
                    end
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Pre Rleg Train','Pre Lleg Train','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data1,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                end
                
            else %if triallist is already populated, just edit what is already there
                [filenames,~] = uigetfiles('*.*','Select filenames');
                this.data = cell(length(filenames),1);
                if iscell(filenames)
                    f = figure;
                    data1 = cell(length(filenames),4);
                    data1(:,1)=filenames;
                    data1(:,2:4) = this.triallist(:,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Pre Rleg Train','Pre Lleg Train','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data1,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data1 = cell(1,4);
                    data1(1,1) = filenames;
                    data1(1,2:4) = this.triallist(1,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'Rleg Train','Lleg Train','Base Rleg Map','Base Lleg Map','Pre Rleg Train','Pre Lleg Train','Post Rleg Map','Post Lleg Map'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data1,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
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
        
        function [Xlat,Ysag]=getHits(this) %X and Y do not inidicate which leg is being tested
            
            filename = this.triallist(:,1);
            WB = waitbar(0,'Processing Trials...');
            
            if iscell(filename)
                for z=1:length(filename)
%                     tempname = filename{z};
                    waitbar((z-1)/length(filename),WB,['Processing Trial ' num2str(z)]);
                    
%                     if strcmp(this.triallist{z,4},'Rleg Train')
%                         color{z} = [189/255,15/255,18/255];%red
%                     elseif strcmp(this.triallist{z,4},'Lleg Train')
%                         color{z} = [189/255,15/255,18/255];%red
%                     elseif strcmp(this.triallist{z,4},'Base Rleg Map')
%                         color{z} = [48/255,32/255,158/255];%blue
%                     elseif strcmp(this.triallist{z,4},'Base Lleg Map')
%                         color{z} = [48/255,32/255,158/255];%blue
%                     elseif strcmp(this.triallist{z,4},'Pre Rleg Train')
%                         color{z} = [25/255,235/255,74/255];%green
%                     elseif strcmp(this.triallist{z,4},'Pre Lleg Train')
%                         color{z} = [25/255,235/255,74/255];%green
%                     elseif strcmp(this.triallist{z,4},'Post Rleg Map')
%                         color{z} = [9/255,109/255,143/255];%bluegrey
%                     elseif strcmp(this.triallist{z,4},'Post Lleg Map')
%                         color{z} = [9/255,109/255,143/255];%bluegrey
%                     end
                    
                    %check to see if data is already processed, it will
                    %save time...
                    if length(this.data)<z
                        disp('Parsing data...');
                        %                     keyboard
                        fn = filename{z};
                        if strcmp(fn(end-3:end),'c3d')
                            disp('method undeveloped for processing c3d');
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
                    
%                     Rz2 = data2(:,2);
%                     Lz2 = data2(:,3);
                    %                 keyboard
                    if ismember('R',this.triallist{z,4})
                        X = data2(:,6);
                        Y = data2(:,8);
%                         RHS = data2(:,4);
                        phase = data2(:,10);
%                         target = data2(:,11);
                        
                        RHS = zeros(length(X),1);%not real HS, just when to sample
                        for n = 1:length(X)-1
                            if (phase(n)==2) && (phase(n+1)==0)
                                RHS(n) = 1;
                            end
                        end
                        RHS = find(RHS);
                        
%                         %cleanup HS
%                         for zz=2:length(RHS)
%                             if RHS(zz)==1 && RHS(zz-1)==0
%                                 RHS2(zz)=1;
%                             else
%                                 RHS2(zz)=0;
%                             end
%                         end
%                         RHS = find(RHS2);
%                         clear RHS2
% keyboard
                        for zz=1:length(RHS)
                            if abs(Y(RHS(zz)))>0.1 %&& abs(X(RHS(zz)))<=0.1
                                tempx(zz) = X(RHS(zz));
                                tempy(zz) = Y(RHS(zz));
                                temp2x(zz) = 5000;
                                temp2y(zz) = 5000;
                            elseif abs(X(RHS(zz)))>0.1 %&& abs(Y(RHS(zz)))<=0.1
                                tempx(zz) = 5000;
                                tempy(zz) = 5000;
                                temp2x(zz) = X(RHS(zz));
                                temp2y(zz) = Y(RHS(zz));
                            else
                                tempx(zz)=5000;
                                tempy(zz)=5000;
                                temp2x(zz)=5000;
                                temp2y(zz)=5000;
                            end
                        end
                        tempx(tempx==5000)=[];
                        tempy(tempy==5000)=[];
                        temp2x(temp2x==5000)=[];
                        temp2y(temp2y==5000)=[];
                        Xsag{z}=tempx;
                        Xlat{z}=temp2x;
                        Ysag{z}=tempy;
                        Ylat{z}=temp2y;
                        
                    elseif ismember('L',this.triallist{z,4})
                        X = data2(:,7);
                        Y = data2(:,9);
%                         LHS = data2(:,5);
                        phase = data2(:,10);
                        
                        LHS = zeros(length(X),1);%not real HS, just when to sample
                        for n = 1:length(X)-1
                            if (phase(n)==2) && (phase(n+1)==0)
                                LHS(n) = 1;
                            end
                        end
                        LHS = find(LHS);
                        
%                         for zz=2:length(LHS)
%                             if LHS(zz)==1 && LHS(zz-1)==0
%                                 LHS2(zz)=1;
%                             else
%                                 LHS2(zz)=0;
%                             end
%                         end
%                         LHS = find(LHS2);
%                         clear LHS2
                        
                        for zz=1:length(LHS)
                            if abs(Y(LHS(zz)))>0.1 %&& abs(X(LHS(zz)))<=0.1
                                tempx(zz) = X(LHS(zz));
                                tempy(zz) = Y(LHS(zz));
                                temp2x(zz) = 5000;
                                temp2y(zz) = 5000;
                            elseif abs(X(LHS(zz)))>0.1 %&& abs(Y(LHS(zz)))<=0.1
                                tempx(zz) = 5000;
                                tempy(zz) = 5000;
                                temp2x(zz) = X(LHS(zz));
                                temp2y(zz) = Y(LHS(zz));
                            else
                                tempx(zz)=5000;
                                tempy(zz)=5000;
                                temp2x(zz)=5000;
                                temp2y(zz)=5000;
                            end
                        end
                        tempx(tempx==5000)=[];
                        tempy(tempy==5000)=[];
                        temp2x(temp2x==5000)=[];
                        temp2y(temp2y==5000)=[];
                        Xsag{z}=tempx;
                        Xlat{z}=temp2x;
                        Ysag{z}=tempy;
                        Ylat{z}=temp2y;
                    end

                end
                close(WB);
%                 keyboard
            else
                
            end
        
        
    end
    
    end
end

