
classdef parameterSeries < labTimeSeries
    %parameterSeries  Extends labTimeSeries to hold adaptation parameters
    %
    %parameterSeries properties:
    %   hiddenTime
    %   bad
    %   stridesTrial
    %   stridesInitTime
    %   description
    %
    %parameterSeries methods:
    %   idk
    %

    properties
        hiddenTime
        trialTypes %Shuqi: 12/01/2021, to support split 1 condition into multiple
    end
    properties(Dependent)
       bad
       stridesTrial
       stridesInitTime
       description
%        trialTypes %Shuqi: 12/01/2021, to support split 1 condition into multiple
    end
    properties(Hidden)
       description_={};
       trialTypes_={};
       fixedParams=5;
    end

    methods
        function this=parameterSeries(data,labels,times,description,types)
            this@labTimeSeries(data,1,1,labels);
            this.hiddenTime=times;
            if length(description)==length(labels)
                this.description_=description; %Needs to be cell-array of same length as labels
            else
                error('paramtereSeries:constructor','Description input needs to be same length as labels')
            end
            if nargin>4
                this.trialTypes_=types;
            end
        end

        function this=setTrialTypes(this,types)
            this.trialTypes_=types;
        end


        %% Getters for dependent variables (this could be made more efficient by fixing the indexes for these parameters ( which is something that already happens in practice) and doing direct indexing to data,
        function vals=get.bad(this)
            if this.isaParameter('bad')
                vals=this.getDataAsVector('bad');
            elseif this.isaParameter('good')
                vals=this.getDataAsVector('good');
                vals=~vals;
            else
                %This should never be the case. Setting all values as good.
                vals=false(size(this.Data,1),1);
            end
        end
        function vals=get.stridesTrial(this)
            vals=this.getDataAsVector('trial');
        end
        function vals=get.stridesInitTime(this)
            vals=this.getDataAsVector('initTime');
        end
        function vals=get.description(this)
%            if isfield(this,'description_')
              vals=this.description_;
%            else
%               vals=cell(size(this.labels));
%            end
        end
        function vals=get.trialTypes(this)
%             if isfield(this,'trialTypes_')
               vals=this.trialTypes_;
%             else
%                 disp('trying to access trialTypes')
%                vals={};
%             end
        end

        %% I/O
        function [bool,idx]=isaParameter(this,labels) %Another name for isaLabel, backwards compatib
            [bool,idx]=this.isaLabel(labels);
        end

        function inds=indsInTrial(this,t)
            if nargin<2 || isempty(t)
                inds=[];
            else
                inds=cell(length(t),1);
                for ii=1:length(t)
                    inds{ii,1}=find(this.stridesTrial==t(ii));
                end
            end
        end

        function [data,auxLabel]=getParameter(this,label) %Backwards compat
            [data,~,auxLabel]=this.getDataAsVector(label);
        end

        function newThis=incorporateDependentParameters(this,labels)
           ff=load('DependParamRecipes.mat','fieldList');
           fTable=ff.fieldList;
           newThis=this;
           if isa(labels,'char')
               labels={labels};
           end
           [bool,idxs] = compareLists(fTable(:,1),labels);
           acceptedLabels=labels(bool);
           acceptedDesc=fTable(idxs(bool),4);
           acceptedHandles=fTable(idxs(bool),2);
           acceptedParams=fTable(idxs(bool),3);
           if any(~bool)
               warning(strcat('Did not find recipes for some of the labels provided: ', labels(~bool)))
           end
           for i=1:length(acceptedLabels)
               newThis=addNewParameter(newThis,acceptedLabels{i},eval(acceptedHandles{i}),acceptedParams{i},acceptedDesc{i});
           end
        end


        %% Modifiers
        function newThis=cat(this,other)
            if size(this.Data,1)==size(other.Data,1)
                if isempty(this.description)
                    thisDescription=cell(size(this.labels));
                else
                  thisDescription=this.description(:);
                end
                if isempty(other.description)
                    otherDescription=cell(size(other.labels));
                  else
                    otherDescription=other.description(:);
                end
                newThis=parameterSeries([this.Data other.Data],[this.labels(:); other.labels(:)],this.hiddenTime,[thisDescription; otherDescription],this.trialTypes);
                %this.Data=[this.Data other.Data];
                %this.labels=[this.labels; other.labels];
                %this.description=[this.description; other.description];
            else
                error('parameterSeries:cat','Cannot concatenate series with different number of strides');
            end
        end

        function newThis=addStrides(this,other)
            %TODO: Check that the labels are actually the same
            if ~isempty(other.Data)
                aux=other.getDataAsVector(this.labels);
                if size(this.Data,2)==size(other.Data,2)
                    newThis=parameterSeries([this.Data; aux],this.labels(:),[this.hiddenTime; other.hiddenTime],this.description(:));
                else
                    warning('parameterSeries:addStrides','Concatenating parameterSeries with different number of parameters. Merging parameter lists & filling NaNs for missing parameters. You (yes, YOU, the current user) SHOULD FIX THIS. Ask Pablo for guidance.');
                    [bool2,~] = compareLists(this.labels,other.labels); %Labels present in other but NOT in this
                    [bool1,~] = compareLists(other.labels,this.labels); %Labels present in this but NOT in other
                    if any(~bool2)
                        newThis=this.appendData(nan(size(this.Data,1),sum(~bool2)),other.labels(~bool2),other.description(~bool2)); %Expanding this
                    else newThis=this;%digna added this, review
                    end
                    if any(~bool1)
                        newOther=other.appendData(nan(size(other.Data,1),sum(~bool1)),this.labels(~bool1),this.description(~bool1)); %Expanding other
                    else newOther=other;%Digna added this, review
                    end
                    newThis=addStrides(newThis,newOther);
                end
            else
                newThis=this; %Empty second arg., adding nothing.
            end
        end

        function newThis=addNewParameter(this,newParamLabel,funHandle,inputParameterLabels,newParamDescription)
           %This function allows to compute new parameters from other existing parameters and have them added to the data.
           %This is useful when trying out new parameters without having to
           %recompute all existing parameters.
           %INPUT:
           %newPAramLAbel: string with the name of the new parameter
           %funHandle: a function handle with N input variables, whose
           %result will be used to compute the new parameter
           %inputParameterLabels: the parameters that will replace each of
           %the variables in the funHandle
           %EXAMPLE:
           %I want to define a new normalized version of the contributions,
           %that divides contributions by avg. step time and avg. step
           %velocity, so that the velocity contribution is now a
           %measure of belt-speed ratio. In order to do that, I will take
           %the velocityContributionAlt (which already exists and is
           %velocityContribution divided by strideTime, so it is just half
           %the difference of velocities) and then divide it by velocity sum.
           %Velocity sum can be computed by dividing stepTimeContribution
           %by stepTimeDifference (there are other possibilities to compute
           %the same thing. The final equation will look like this:
           %newVelocityContribution = velocityContributionAlt./(2*stepTimeContribution/stepTimeDiff)
           %This can be implemented as:
           %newThis = this.addNewParameter('newVelocityContribution',@(x,y,z)x./(2*y./z),{'velocityContributionAlt','stepTimeContribution','stepTimeDiff'},'velocityContribution normalized to strideTime times average velocity');

           [newData]=this.computeNewParameter(newParamLabel,funHandle,inputParameterLabels);
           newThis=appendData(this,newData,{newParamLabel},{newParamDescription}) ;
        end

        function newThis=getDataAsPS(this,labels,strides,skipFixedParams)
            if nargin<2 || isempty(labels)
                labels=this.labels;
            end
            if nargin<4 || isempty(skipFixedParams) || skipFixedParams~=1
                extendedLabels=[this.labels(1:this.fixedParams) ;labels(:)];
            else
                extendedLabels=labels(:);
            end
            [~,inds]=unique(extendedLabels); %To avoid repeating bad, trial, initTime
            extendedLabels=extendedLabels(sort(inds)); %To avoid the re-sorting 'unique' does
            [bool,idx]=this.isaLabel(extendedLabels);
            idx=idx(bool);
            if nargin<3 || isempty(strides)
               strides=1:size(this.Data,1);
            end
            newThis=parameterSeries(this.Data(strides,idx),this.labels(idx),this.hiddenTime(strides),this.description(idx));
        end

        function newThis=appendData(this,newData,newLabels,newDesc) %For back compat
            if nargin<4 || isempty(newDesc)
                newDesc=cell(size(newLabels));
            end
            other=parameterSeries(newData,newLabels,this.hiddenTime,newDesc,this.trialTypes);
            newThis=cat(this,other);
        end

        function this=replaceParams(this,other)
           %Replaces existing parameters in this, with parameter data in other

          [bool,idx]=this.isaLabel(other.labels); %Finding parameters that already existed
          this.Data(:,idx(bool))=other.Data(:,bool); %Replacing data
          this.description_(idx(bool))=other.description(bool); %Replacing descriptions (is this necessary?)
          %catting data for parameters that DIDN'T exist
          if any(~bool)
              warning('Asked to replace parameters, but found parameters that didn''t exist. Appending.')
             this=this.cat(other.getDataAsPS(other.labels(~bool),[],1));
          end
        end

        function newThis=markBadWhenMissingAny(this,labels)
            newThis=this;
            aux=this.getDataAsVector(labels);
            [~,bi]=this.isaLabel('bad');
            newThis.Data(:,bi)=this.bad | any(isnan(aux),2);
            [~,bg]=this.isaLabel('good');
            newThis.Data(:,bg)=~this.bad;
        end

        function newThis=markBadWhenMissingAll(this,labels)
            newThis=this;
            aux=this.getDataAsVector(labels);
            [~,bi]=this.isaLabel('bad');
            newThis.Data(:,bi)=this.bad | all(isnan(aux),2);
            [~,bg]=this.isaLabel('good');
            newThis.Data(:,bg)=~this.bad;
        end

        function newThis=substituteNaNs(this,method)
            if nargin<2 || isempty(method)
                method='linear';
            end
            newThis=this.substituteNaNs@labTimeSeries(method);
            newThis.Data(:,1:this.fixedParams)=this.Data(:,1:this.fixedParams);

        end

        function this=markBadStridesAsNan(this)
                inds=this.bad;
                this.Data(inds==1,this.fixedParams+1:end)=NaN;
        end

        function this=normalizeToBaseline(this,labels,rangeValues)
            warning('parameterSeries:normalizeToBaseline','Deprecated, use linearStretch')
            this=linearStretch(this,labels,rangeValues);
        end

        function newThis=linearStretch(this,labels,rangeValues)
           %This normalization transforms the values of the parameters given in labels
           %such that rangeValues(1) maps to 0 and rangeValues(2) maps to 1
           %It creates NEW parameters with the same name, and the 'Norm' prefix.
           %This will generate collisions if run multiple times for the
           %same parameters
           %See also: adaptationData.normalizeToBaselineEpoch
            if numel(rangeValues)~=2
                error('rangeValues has to be a 2 element vector')
            end
%             [boolFlag,labelIdx]=isaLabel(this,labels);
%             for i=1:length(labels)
%                 if boolFlag(i)
%                     oldDesc=this.description(labelIdx(i));
%                     newDesc=['Normalized (range=' num2str(rangeValues(1)) ',' num2str(rangeValues(2)) ') ' oldDesc];
%                     funHandle=@(x) (x-rangeValues(1))/diff(rangeValues);
%                     this=addNewParameter(this,strcat('Norm',labels{i}),funHandle,labels(i),newDesc);
%                 end
%
%             end
            %More efficient:
            N=length(labels);
            newDesc=repmat({['Normalized to range=[' num2str(rangeValues(1)) ',' num2str(rangeValues(2)) ']']},N,1);
            newL=cell(N,1);
            nD=zeros(size(this.Data,1),N);
            for i=1:N
                funHandle=@(x) (x-rangeValues(1))/diff(rangeValues);
                newL{i}=strcat('Norm',labels{i});
                nD(:,i)=this.computeNewParameter(newL{i},funHandle,labels(i));
            end
            newThis=appendData(this,nD,newL,newDesc);
        end

%         function newThis=EMGnormAllData(this,labels,rangeValues)
%             %This get the stride by stide norm
%             %It creates NEW parameters with the same name, and the 'Norm' prefix.
%             %This will generate collisions if run multiple times for the
%             %same parameters
%             %See also: adaptationData.normalizeToBaselineEpoch
%             if isempty(rangeValues)
% %                 error('rangeValues has to be a 2 element vector')
%                 rangeValues=0;
%             end
%
%             %More efficient:
%             N=length(labels);
%             newDesc=repmat({['Normalized to range=[' num2str(rangeValues(1))  ']']},N,1);
%             newL=cell(N,1);
%             nD=zeros(size(this.Data,1),N);
%
% %             for i=1:N
%                 %                 funHandle=@(x) (x-rangeValues(1))/diff(rangeValues);
%
% %                 funHandle=@(x) vecnorm(x'-rangeValues);
% %                 newL=strcat('NormEMG',labels);
% %                 nD(:,:)=this.computeNewParameter(newL{1},funHandle,labels(1));
% %             end
%             newThis=appendData(this,nD,newL,newDesc);
%         end


        %% Other functions that need redefining:
        function [F]=fourierTransform(this)
            %error('parameterSeries:fourierTransform','You cannot do that!')
            F=fourierTransform@labTimeSeries(this);
            F.TimeInfo.Units='strides^{-1}';
        end

        function newThis=resample(this) %the newTS is respected as much as possible, but forcing it to be a divisor of the total time range
            error('parameterSeries:resample','You cannot do that!')
            newThis=[];
        end

        function newThis=resampleN(this) %Same as resample function, but directly fixing the number of samples instead of TS
            error('parameterSeries:resampleN','You cannot do that!')
            newThis=[];
        end

        %% Display
        function [h,h1]=plotAlt(this,h,labels,plotHandles,color)
            if nargin<5
                color=[];
            end
            if nargin<4
                plotHandles=[];
            end
            if nargin<3
                labels=[];
            end
            if nargin<2
                h=[];
            end
            [h,h1]=this.plot(h,labels,plotHandles,[],color,1);
            ll=findobj(h,'Type','Line');
            set(ll,'LineStyle','None','Marker','.')
            linkaxes(h1,'x')
        end

        %% Stats
        function [p,postHocMatrix] = anova(this,params,groupIdxs,dispOpt)
            %Function to perform one-way anova among several groups of
            %strides, and a post-hoc analysis to
            if nargin<4 || isempty(dispOpt)
                dispOpt='off';
            end
            strides=cell2mat(groupIdxs);
            Ngroups=length(groupIdxs);
            for i=1:Ngroups
                groupID{i}=i*ones(size(groupIdxs{i}));
            end
            groupID=cell2mat(groupID);
           if isa(params,'char')
               params={params};
           end
           Nparams=length(params);
           aux=this.getDataAsPS([],strides);
           postHocMatrix=cell(Nparams,1);
           for i=1:Nparams
               postHocMatrix{i}=nan(Ngroups);
               relevantData=aux.getDataAsVector(params(i));
               [p(i),ANOVATAB,STATS] = anova1(relevantData,groupID,dispOpt);
               [c,MEANS,H,GNAMES] = multcompare(STATS); %Default post-hoc is tukey-kramer
               postHocMatrix{i}(sub2ind(Ngroups*[1,1],c(:,1),c(:,2)))=c(:,6);
           end
        end
    end

end
