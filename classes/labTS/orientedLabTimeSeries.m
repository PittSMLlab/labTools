classdef orientedLabTimeSeries  < labTimeSeries
    
    %%
    properties(SetAccess=private)
        orientation %orientationInfo object
    end
    %properties(Dependent)
    %    labelPrefixes
    %    labelSuffixes
    %end

    
    %%
    methods
        
        %Constructor:
        function this=orientedLabTimeSeries(data,t0,Ts,labels,orientation) %Necessarily uniformly sampled
            if nargin<1
                data=[];
                t0=0;
                Ts=[];
                labels={};
                orientation=orientationInfo();
            end
                if ~orientedLabTimeSeries.checkLabelSanity(labels)
                    error('orientedLabTimeSeries:Constructor','Provided labels do not pass the sanity check. See issued warnings.')
                end
                this@labTimeSeries(data,t0,Ts,labels);
                if isa(orientation,'orientationInfo')
                    this.orientation=orientation;
                else
                    ME=MException('orientedLabTimeSeries:Constructor','Orientation parameter is not an OrientationInfo object.');
                    throw(ME)
                end
        end
        
        %-------------------
        
        %Other I/O functions:
        function [newTS,auxLabel]=getDataAsTS(this,label)
            [newTS,auxLabel]=getDataAsTS@labTimeSeries(this,label);
        end

        function [data,label]=getOrientedData(this,label)
            %Returns data as a 3D tensor, where the last dim contains the componentes x,y,z
            %[data,label]=getOrientedData(this,label)
            %INPUT:
            %this = orientedLabTS object
            %label = cell array of strings, each containing the prefix of a
            %marker present in this TS (e.g.: label={'LHIP','RHIP'}, not
            %{'LHIPx','RHIPx'}. If any of the provided labels do not exist 
            %AS A PREFIX, NaNs are returned in the corresponding matrix components.
            %OUTPUT:
            %data= matrix of dimensions TxNx3, where N is the length of label 
            %(# of requested markers), T is the number of available time
            %samples. Each slice data(:,i,:) contains 3D position of marker
            %i at all time samples.
            %label=Currently returns the same label given as input. 
            
            T=size(this.Data,1);
            if nargin<2 || isempty(label)
                label=this.getLabelPrefix; %All of them
            end
            data=nan(T,length(label)*3);
            extendedLabels=this.addLabelSuffix(label);
            if ~orientedLabTimeSeries.checkLabelSanity(this.labels)
               error('Labels in this object do not pass the sanity check.') 
            end
            [bool,~]=this.isaLabel(extendedLabels);
            [data(:,bool),~]=this.getDataAsVector(extendedLabels(bool));
            data=permute(reshape(data,T,3,round(length(extendedLabels)/3)),[1,3,2]);
        end
        
        function newThis=getDataAsOTS(this,label)
            [data,label]=getOrientedData(this,label);
            data=permute(data,[1,3,2]);
            newThis=orientedLabTimeSeries(data(:,:),this.Time(1),this.sampPeriod,orientedLabTimeSeries.addLabelSuffix(label),this.orientation);
        end
        
        function [diffMatrix,labels,labels2,Time]=computeDifferenceMatrix(this,t0,t1,labels,labels2)
           %Computes the difference vector between two markers, for the time interval [t0,t1] 
           %If labels is specified, only those markers are used
           %If labels2 is specified, distance to those markers only is
           %specified
           [data,label]=getOrientedData(this,this.getLabelPrefix);
           [T,N,M]=size(data); %M=3
           
           %Inefficient way: compute the difference matrix for all times
           %and markers, and then reduce it
           diffMatrix=nan(T,N,M,N);
           for i=1:N
               diffMatrix(:,:,:,i)= bsxfun(@minus,data,data(:,i,:));
           end
           diffMatrix=permute(diffMatrix,[1,2,4,3]);
           if nargin<2 || isempty(t0)
              t0=this.Time(1); 
           end
           if nargin<3 || isempty(t1)
               t1=this.Time(end)+eps;
           end
           if nargin<4 || isempty(labels)
               labels=this.getLabelPrefix;
           end
           if nargin<5 || isempty(labels2)
               labels2=this.getLabelPrefix;
           end
           %Reduce it:
           timeIdxs=find(this.Time<t1 & this.Time>=t0);
           [~,labelIdxs]=isaLabelPrefix(this,labels);
           [~,label2Idxs]=isaLabelPrefix(this,labels2);
           diffMatrix=diffMatrix(timeIdxs,labelIdxs,label2Idxs,:);
           Time=this.Time(timeIdxs);
           
        end
        
        function [distMatrix,labels,labels2,Time]=computeDistanceMatrix(this,t0,t1,labels,labels2)
           if nargin<2 || isempty(t0)
              t0=[]; 
           end
           if nargin<3 || isempty(t1)
               t1=[];
           end
           if nargin<4 || isempty(labels)
               labels=[];
           end
           if nargin<5 || isempty(labels2)
               labels2=[];
           end
            [diffMatrix,labels,labels2,Time]=computeDifferenceMatrix(this,t0,t1,labels,labels2);
            distMatrix=sqrt(sum(diffMatrix.^2,4));
        end

        %-------------------
        
        function labelPref=getLabelPrefix(this)
            aux=cellfun(@(x) x(1:end-1),this.labels,'UniformOutput',false);
            labelPref=aux(1:3:end);
        end
        
        function [boolFlag,labelIdx]=isaLabelPrefix(this,label)
             if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            else
                error('labTimeSeries:isaLabel','label input argument has to be a string or a cell array containing strings.')
            end
            
            N=length(auxLabel);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                %Alternative efficient formulation:
                boolFlag(j)=any(strcmp(auxLabel{j},this.getLabelPrefix));
                if boolFlag(j)
                    labelIdx(j)=find(strcmp(auxLabel{j},this.getLabelPrefix));
                end
            end
        end
        
        %-------------------
        function plot3(this)
           h=figure;
           [data,labelPref]=getOrientedData(this);
           hold on
           
           for i=1:length(labelPref)
               plot3(data(:,i,1),data(:,i,2),data(:,i,3))
           end
           hold off
           axis equal
           legend(labelPref)
        end
        
        %-------------------
        %Modifier functions:
        
        function newThis=resampleN(this,newN) %Same as resample function, but directly fixing the number of samples instead of TS
            auxThis=this.resampleN@labTimeSeries(newN);
            newThis=orientedLabTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.orientation);
        end
        
        function newThis=split(this,t0,t1)
           auxThis=this.split@labTimeSeries(t0,t1);
           newThis=orientedLabTimeSeries(auxThis.Data,t0,auxThis.sampPeriod,auxThis.labels,this.orientation);
        end
        
        function newThis=translate(this,vector)
            %Check: vector is 1x3 or Tx3
            [M,N]=size(vector);
            if N~=3 || (M~=1 && M~=length(this.Time))
                error('orientedLabTS:translate','Translation vector has to be size 3 on second dim, and singleton or of length(time) in the first.')
            end
            [data,~]=getOrientedData(this);
            vector=reshape(vector,M,1,3);
            newData=permute(bsxfun(@plus,data,vector),[1,3,2]);
            newThis=orientedLabTimeSeries(newData(:,:),this.Time(1),this.sampPeriod,this.labels,this.orientation);
            %newThis.UserData.translation=; %ToDo: store the translation
            %info in some structure so that it can be backtracked
        end
        
        function newThis=rotate(this, matrix)
            [data,label]=getOrientedData(this);
            M=size(matrix,1);
            matrix=reshape(matrix,M,1,3,3);
            newData=permute(sum(bsxfun(@times,data,matrix),3),[1,4,2,3]);
            newThis=orientedLabTimeSeries(newData(:,:),this.Time(1),this.sampPeriod,this.labels,this.orientation);
            %newThis.UserData.rotation=; %ToDo: store the rotation
            %info in some structure so that it can be backtracked
        end
        
        function newThis=alignRotate(this,newX,newZ)
            %newX and newZ need to be 1x3 or Nx3 where N=size(this.Data,1)
            %Check:
            N=size(this.Data,1);
            if (size(newX,1)~=1 && size(newX,1)~=N) || size(newX,2)~=3
                error('orientedLabTS:alignRotate','newX has to be 1x3 or Nx3.')
            end    
            if size(newZ,1)~=1 && size(newZ,1)~=N || size(newZ,2)~=3
                error('orientedLabTS:alignRotate','newZ has to be 1x3 or Nx3.')
            end    
            
            %In case of one being 1x3 and the other Nx3, making them both
            %Nx3
            %FIXME: Align z to newZ, and x to newX projected in a direction
            %orthogonal to newZ (or check that newX is orthogonal to newZ
            %to start with)
            if size(newX,1)~=size(newZ,1)
                if size(newX,1)==1
                    newX=repmat(newX,N,1);
                else
                    newZ=repmat(newZ,N,1);
                end
            end
            
           newX=bsxfun(@rdivide,newX,sqrt(sum(newX.^2,2)));
           newZ=bsxfun(@rdivide,newZ,sqrt(sum(newZ.^2,2)));
           %Find rotation matrix
           newY=-cross(newX,newZ); %orthogonal to the other two
           newY=bsxfun(@rdivide,newY,sqrt(sum(newY.^2,2)));
           matrix1=permute(newX,[1,3,2]);
           matrix2=permute(newY,[1,3,2]);
           matrix3=permute(newZ,[1,3,2]);
           matrix=cat(2,matrix1,matrix2);
           matrix=cat(2,matrix,matrix3);
           for i=1:size(matrix,1)
               if ~any(isnan(matrix(i,:,:)))
                matrix(i,1:3,1:3)=inv(squeeze(matrix(i,:,:)));
               else
                   matrix(i,1:3,1:3)=nan;
               end
           end
           %Rotate
           newThis=rotate(this, matrix);
        end
        
        function newThis=referenceToMarker(this,marker)
            %Check: marker needs to be a suffix of this object.
            [data,~]=getOrientedData(this,marker);
            newThis=translate(this,squeeze(-1*data));
        end
        
        function newThis=derivate(this)
            auxThis=this.derivate@labTimeSeries;
            newThis=orientedLabTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.orientation);
        end
        
    end
    methods (Static)
        function extendedLabels=addLabelSuffix(labels)
            if ischar(labels)
                labels={labels};
            end
            extendedLabels=cell(length(labels)*3,1);
            extendedLabels(1:3:end)=strcat(labels,'x');
            extendedLabels(2:3:end)=strcat(labels,'y');
            extendedLabels(3:3:end)=strcat(labels,'z');
        end 
        function labelSane=checkLabelSanity(labels)
            labelSane=true;
            %Check: labels is a multiple of 3
            if mod(length(labels),3)~=0
                warning('Label length is not a multiple of 3, therefore they can''t correspond to 3D oriented data.')
                labelSane=false;
                return
            end
            %Check: all labels end in 'x','y' or 'z'
            aux2=cellfun(@(x) x(end),labels,'UniformOutput',false); %Should be 'x', 'y', 'z'
            if any(~strcmp(aux2(1:3:end),'x')) || any(~strcmp(aux2(2:3:end),'y')) || any(~strcmp(aux2(3:3:end),'z'))
               warning('Labels do not end in ''x'', ''y'', or ''z'' or in that order, as expected.') 
               labelSane=false;
               return
            end
            %Check: and labels have the same prefix in groups of 3
            aux=cellfun(@(x) x(1:end-1),labels,'UniformOutput',false);
            labelsx=aux(1:3:end);
            labelsy=aux(2:3:end);
            labelsz=aux(3:3:end);
            if any(~strcmp(labelsx,labelsy)) || any(~strcmp(labelsx,labelsz))
                labelSane=false;
                return
            end
        end
    end

end

