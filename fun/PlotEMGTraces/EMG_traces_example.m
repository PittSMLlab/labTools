%%Traces from example subject to show how data is summarized
%% Load data
% load('/Volumes/Users/Dulce/R01_Nimbus2021/VROG_Devon/VrG_Devon.mat')
% subID = 'CTR_01';
% scriptDir = fileparts(matlab.desktop.editor.getActiveFilename); 
% load([scriptDir '/data/' subID])

%% Set muscle to plot

% muscle={ 'GLU','HIP','BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF','SOL', 'LG', 'MG','TA', 'PER'};
muscle={ 'TFL', 'GLU','HIP', 'SEMB', 'SEMT','BF', 'VM', 'VL', 'RF','SOL', 'LG', 'MG','TA', 'PER'};
normalize = 1;  % 1 to normalize data
normCond = {'TM mid 1'};

%%
%% Baseline condtions 
conds={'TM mid 1'};
late=[1 1 1];
strides=[40 40 40];
IgnoreStridesEarly=[1 1 1] ; 

% fh=figure(1)
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% Baseline condtions 
conds={'TM mid 1','TM fast','TM slow'};
late=[1 1 1];
strides=[40 40 40];
IgnoreStridesEarly=[1 1 1] ;
% fh=figure(1)
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%%
conds={'TM mid 1','Adaptation','Adaptation','Post 1'};
late=[1 0 1 0];
strides=[40 40 40 30];
IgnoreStridesEarly=[1 50 1 1];
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% 
conds={'TM mid 1','Adaptation','Adaptation','Adaptation','Adaptation','Adaptation','Adaptation'};
late=[0 0  0 0 0 0 1 ];
strides=[40 40 40 40 40 40 40];
IgnoreStridesEarly=[1 50 100 200 300 400 1];
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly); 


%% 
conds={'TM mid 1','Adaptation','Adaptation'};
late=[1 0  1 ];
strides=[40  40 40];
IgnoreStridesEarly=[1 1 400 ];
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly); 
%% Baseline condtions 
conds={'TM mid 1','OG base','Post 1','Post 2'};
late=1*ones(1,length(conds));
strides=40*ones(1,length(conds)); 

IgnoreStridesEarly=0*ones(1,length(conds));
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% Late condition 
conds={'TM mid 1','OG base','TM fast',...
    'Adaptation',...
    'Post 1','Post 2'};
late=1*ones(1,length(conds));
strides=40*ones(1,length(conds));
IgnoreStridesEarly=zeros(1,length(conds));

fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);


%% Early conditions 
conds={'Pos short',...
    'Neg Short','Adaptation',...
    'Post 1','Post 2'};
late=0*ones(1,length(conds));
strides=30*ones(1,length(conds));
IgnoreStridesEarly=50*ones(1,length(conds));

fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% Early conditions 
conds={'Pos short',...
    'Neg Short','Adaptation',...
        };
late=0*ones(1,length(conds));
strides=10*ones(1,length(conds));
IgnoreStridesEarly=50*ones(1,length(conds));

fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% Late condition 
conds={'Adaptation',...
    'Multiple Pos Shorts Splits'};
late=1*ones(1,length(conds));
strides=40*ones(1,length(conds));
IgnoreStridesEarly=zeros(1,length(conds));

fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%%

conds={'Pos short',...
   'Pos Short Ramp','Adaptation',...
        };
late=[0 1 0];
strides=[10 40 10];
IgnoreStridesEarly=[50 0 50];

fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);



%%
conds={'TM mid 1','Pos Short','Neg Short'};
late=[1 1 0];
strides=[40 40 40];
IgnoreStridesEarly=[1 1 50] ; 

% fh=figure(1)
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);



%% save figures
% if late
%     if baseOnly
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_BaseLate.png']);
%     else
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_Late.png']);
%     end
% else
%     saveas(fh, [scriptDir '/EMGTraces/' subID '_Early.png']);
% end
