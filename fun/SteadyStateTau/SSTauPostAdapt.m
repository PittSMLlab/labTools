

%%
function results = SSTauPostAdapt(adaptDataList,params,groups,plotFlag)

% define number of points to use for calculating values
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; %OG and Washout
% 
% if nargin<3 || isempty(groups)
%     groups=fields(SMatrix);  %default        
% end
% ngroups=length(groups);

if isa(adaptDataList,'cell')
    if ~isa(adaptDataList{1},'cell')
        adaptDataList={adaptDataList};
    end
elseif isa(adaptDataList,'char') || isa(adaptDataList,'adaptationData')
    adaptDataList={{adaptDataList}};
end
ngroups=length(adaptDataList);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

results.SSpersub= [];
results.Strides2SS= [];


%   steadystate_sub = cell(6,1);
%   Strides2SS_sub = cell(6,1);

 steadystate_all = cell(6,1);
  Strides2SS_all = cell(6,1);
for group=1:ngroups
    
    OGbase=[];
    TMbase=[];
    steadystate=[];    
    ogafter=[];
    washout=[];
    washout2=[];
            %~~~~~~~~~~~
    Strides2SS=[];
    %~~~~~~~~~~~
  


    for subject=1:length(adaptDataList{group})
        % load subject
        adaptData=adaptDataList{group}{subject};      
        
        % remove baseline bias
        adaptData=adaptData.removeBadStrides;
        adaptData=adaptData.removeBias;        
          

        if isempty(cellfun(@(x) strcmp(x, 'Post 1'), adaptData.metaData.conditionName))==0
            % compute TM steady state before OG walking (mean of first steadyNumPts of last steadyNumPts+5 strides)
        adapt2Data=adaptData.getParamInCond(params,'Post 1');
        steadystate=[steadystate; nanmean(adapt2Data((end-5)-steadyNumPts+1:(end-5),:))];
        
        end
       
        steadystate_all{group} = steadystate;
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        %Compute the %Forgetting, added 07/2015 CJ
        idxNET = find(strcmp(params, 'netContributionnorm2'));
        idxVELO = find(strcmp(params, 'velocityContributionNorm2'));
        idxGOOD = find(strcmp(params, 'good'));

    %Compute the Strides2SS, added 07/2015 CJS

    if isempty(idxNET)==0
        Strides2SS=[Strides2SS; CalcStrides2SS_PostAdapt(adapt2Data,steadystate(subject,:), params, plotFlag, adaptData.subData.ID)];
         
    else
        Strides2SS=[Strides2SS; NaN.*ones(1, length(params))];
    end
     Strides2SS_all{group} =  Strides2SS;

    if isempty(idxGOOD)==0
        Strides2SS=steadystate;
    end

   
    end
results.SSpersub  =  steadystate_all;
results.Strides2SS =  Strides2SS_all;
  
end
