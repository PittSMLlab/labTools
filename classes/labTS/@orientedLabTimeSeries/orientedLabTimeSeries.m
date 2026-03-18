classdef orientedLabTimeSeries < labTimeSeries
    %orientedLabTimeSeries  Time series for 3D oriented/vector data
    %
    %   orientedLabTimeSeries extends labTimeSeries for data with spatial
    %   orientation (e.g., marker positions, forces). Each variable has
    %   three components (x, y, z) and the class maintains orientation
    %   information for coordinate transformations.
    %
    %orientedLabTimeSeries properties:
    %   orientation - orientationInfo object defining coordinate system
    %   (inherits all properties from labTimeSeries)
    %
    %orientedLabTimeSeries methods:
    %   orientedLabTimeSeries - constructor
    %   getDataAsTS - returns labTimeSeries (override)
    %   getOrientedData - returns data as 3D tensor
    %   getDataAsOTS - returns subset as orientedLabTimeSeries
    %   getLabelPrefix - returns label prefixes without x/y/z
    %   isaLabelPrefix - checks if prefix exists
    %   computeDifferenceMatrix - computes inter-marker differences
    %   computeDifferenceOTS - difference matrix as OTS
    %   computeDistanceMatrix - computes inter-marker distances
    %   vectorNorm - computes 2-norm of vectors
    %   buildNaiveDistancesModel - builds statistical marker model
    %   getVirtualOTS - computes virtual markers from model
    %   findOutliers - detects outliers using model
    %   fixBadLabels - detects and fixes label swaps
    %   fillGaps - fills missing marker data
    %   removeOutliers - removes outlier data points
    %   assessMissing - assesses missing data
    %   translate - translates data by vector
    %   rotate - rotates data by matrix
    %   flipAxis - flips specified axis
    %   alignRotate - aligns to new coordinate system
    %   referenceToMarker - references data to marker position
    %   threshold - thresholds by vector magnitude
    %   thresholdByChannel - thresholds by channel (override)
    %   cat - concatenates (override)
    %   resample - resamples (override)
    %   resampleN - resamples to N samples (override)
    %   split - splits timeseries (override)
    %   derivate - differentiates (override)
    %   derivative - numerical derivative (override)
    %   lowPassFilter - applies low-pass filter (override)
    %   highPassFilter - applies high-pass filter (override)
    %   substituteNaNs - fills NaN values (override)
    %   plus - adds two OTS (override)
    %   times - multiplies by constant (override)
    %   plot3 - plots 3D trajectories
    %   animate2 - creates animation with balloon model
    %   animate - creates animation (alternate version)
    %
    %See also: labTimeSeries, orientationInfo, naiveDistances

    %% Properties
    properties (SetAccess = private)
        orientation % orientationInfo object
    end

    % properties (Dependent)
    %     labelPrefixes
    %     labelSuffixes
    % end

    %% Constructor
    methods
        function this = orientedLabTimeSeries(data, t0, Ts, labels, ...
                orientation)
            %orientedLabTimeSeries  Constructor for orientedLabTimeSeries
            %class
            %
            %   this = orientedLabTimeSeries(data, t0, Ts, labels,
            %   orientation) creates oriented timeseries with specified
            %   data and orientation
            %
            %   Inputs:
            %       data - matrix of data values (samples x 3*channels),
            %              organized as [x1 y1 z1 x2 y2 z2 ...]
            %       t0 - initial time in seconds
            %       Ts - sampling period in seconds
            %       labels - cell array of labels ending in 'x', 'y', 'z'
            %       orientation - orientationInfo object defining
            %                     coordinate system
            %
            %   Outputs:
            %       this - orientedLabTimeSeries object
            %
            %   Note: Necessarily uniformly sampled. Labels must pass
            %         sanity check.
            %
            %   See also: labTimeSeries, orientationInfo

            if nargin < 1
                data = [];
                t0 = 0;
                Ts = [];
                labels = {};
                orientation = orientationInfo();
            end
            if ~orientedLabTimeSeries.checkLabelSanity(labels)
                error('orientedLabTimeSeries:Constructor', ...
                    ['Provided labels do not pass the sanity check. ' ...
                    'See issued warnings.']);
            end
            this@labTimeSeries(data, t0, Ts, labels);
            if isa(orientation, 'orientationInfo')
                this.orientation = orientation;
            else
                ME = MException('orientedLabTimeSeries:Constructor', ...
                    'Orientation parameter is not an OrientationInfo object.');
                throw(ME);
            end
        end
    end

    %% Data Access Methods
    methods
        [newTS, auxLabel] = getDataAsTS(this, label)

        [data, label] = getOrientedData(this, label)

        newThis = getDataAsOTS(this, label)

        labelPref = getLabelPrefix(this)

        [boolFlag, labelIdx] = isaLabelPrefix(this, label)
    end

    %% Distance and Difference Computation Methods
    methods
        [diffMatrix, labels, labels2, Time] = computeDifferenceMatrix( ...
            this, t0, t1, labels, labels2)

        diffOTS = computeDifferenceOTS(this, t0, t1, labels, labels2)

        [distMatrix, labels, labels2, Time] = computeDistanceMatrix(...
            this, t0, t1, labels, labels2)

        newThis = vectorNorm(this)
    end

    %% Model and Quality Methods
    methods
        model = buildNaiveDistancesModel(this)

        virtualOTS = getVirtualOTS(this, ww, meanDiff, stdDiff)

        [this, logL] = findOutliers(this, model, verbose)

        [this, m, permuteList, modelScore, badFlag, modelScore2] = ...
            fixBadLabels(this, permuteList)

        newThis = fillGaps(this, model)

        newThis = removeOutliers(this, model)

        [fh, ph, this] = assessMissing(this, labelPrefixes, fh, ph)
    end

    %% Spatial Transformation Methods
    methods
        function newThis = translate(this,vector)
            %translate OTS data by input vector (vector addition)

            %Check: vector is 1x3 or Tx3
            [M,N] = size(vector);
            if N ~= 3 || (M ~= 1 && M ~= numel(this.Time))
                error('orientedLabTS:translate',['Translation vector ' ...
                    'has to be size 3 on second dim, and singleton or ' ...
                    'of length(time) in the first.']);
            end
            data = getOrientedData(this);
            vector = reshape(vector,M,1,3);
            newData = permute(bsxfun(@plus,data,vector),[1 3 2]);
            newThis = orientedLabTimeSeries(newData(:,:),this.Time(1), ...
                this.sampPeriod,this.labels,this.orientation);
            %newThis.UserData.translation=; %ToDo: store the translation
            %info in some structure so that it can be backtracked
        end

        function newThis=rotate(this, matrix)
            %rotate OTS data using input rotation matrix
            %Since no check is done on the matrix, it really allows for any
            %arbitrary linear transformation of the data [including
            %contractions/expansions and inversions]

            [data,label]=getOrientedData(this);
            if ndims(matrix)==3
                M=size(matrix,1);
            else
                M=1;
            end
            matrix=reshape(matrix,M,1,3,3);
            newData=permute(sum(bsxfun(@times,data,matrix),3),[1,4,2,3]);
            newThis=orientedLabTimeSeries(newData(:,:),this.Time(1),this.sampPeriod,this.labels,this.orientation);
            %newThis.UserData.rotation=; %ToDo: store the rotation
            %info in some structure so that it can be backtracked
        end

        function newThis=flipAxis(this,axis)
            matrix=eye(3);
            if isa(axis,'char')
                axis=axis-'w'; %This converts 'x','y','z' to 1,2,3
            end
            matrix(axis,axis)=-1;
            newThis=this.rotate(matrix);
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
                    matrix(i,1:3,1:3)=inv(squeeze(matrix(i,:,:))); %Very expensive computation
                else
                    matrix(i,1:3,1:3)=nan;
                end
            end
            %Rotate
            newThis=rotate(this, matrix);
        end

        function newThis=referenceToMarker(this,marker)
            %align data relative to input marker, calls
            %orientedLabTimeSeries.translate()

            %Check: marker needs to be a suffix of this object.
            [data,~]=getOrientedData(this,marker);
            newThis=translate(this,squeeze(-1*data));
        end
    end

    %% Thresholding Methods
    methods
        newThis = threshold(this, th)

        newThis = thresholdByChannel(this, th, label, moreThanFlag)
    end

    %% Override Methods - Type Preservation
    methods
        newThis = cat(this, other)

        newThis = resample(this, newTs, newT0, hiddenFlag)

        newThis = resampleN(this, newN, method)

        newThis = split(this, t0, t1)

        newThis = derivate(this)

        newThis = derivative(this, diffOrder)

        newThis = lowPassFilter(this, fcut)

        newThis = highPassFilter(this, fcut)

        newThis = substituteNaNs(this, method)

        newThis = plus(this, other)

        newThis = times(this, constant)

        function this=renameLabels(this,originalPrefixes,newPrefixes)
            warning('You should not be renaming the labels. You have been warned. Also, in OTS you can only rename the prefixes.')
            if isempty(originalPrefixes)
                originalPrefixes=this.getLabelPrefix;
            end
            if size(newPrefixes)~=size(originalPrefixes)
                error('Inconsistent label sizes')
            end
            if ~isa(originalPrefixes,'cell')
                originalPrefixes={originalPrefixes};
                newPrefixes={newPrefixes};
            end
            for i=1:length(originalPrefixes)
                this=this.renameLabels@labTimeSeries(strcat(originalPrefixes{i},{'x','y','z'}),strcat(newPrefixes{i},{'x','y','z'}));
            end
        end
    end

    %% Visualization Methods
    methods
        function fh=plot3(this,fh)
            %plots all 3 components of all variables in OTS instance
            %
            %INPUTS:
            %fh, figure handle. If none passed in, a new one is created
            %OUTPUTS:
            %fh, figure handle to figure that shows 3D plot of each data
            %variable (e.g. marker data or GRFdata)

            if nargin<2 || isempty(fh)
                fh=figure;%return handle to a figure
            else
                figure(fh);
            end
            [data,labelPref]=getOrientedData(this);
            hold on

            for i=1:length(labelPref)
                plot3(data(:,i,1),data(:,i,2),data(:,i,3),'.')
                if ~isempty(this.Quality)
                    aux=this.Quality(:,i)==1;
                    plot3(data(aux,i,1),data(aux,i,2),data(aux,i,3),'rx')
                end
            end
            hold off
            axis equal
            legend(labelPref)
        end

        function mov=animate2(this,t0,t1,frameRate,writeFileFlag,filename,mode)
            %This function renders a movie of the 3-D position stored in the orientedLabData object.
            %It only makes sense for markerData type objects.

            if nargin<2 || isempty(t0) || isempty(t1)
                t0=this.Time(1);
                t1=this.Time(end);
            end
            if nargin<7 || isempty(mode)
                mode=2;
            end
            if nargin<5 || isempty(writeFileFlag)
                writeFileFlag=0;
            end
            if nargin<4 || isempty(frameRate)
                frameRate=25;
            end
            if nargin<6 || isempty(filename)
                filename=['anim_t=[' num2str(round(t0*10)/10) ',' num2str(round(t1*10)/10) '].avi'];
            end
            f=round(this.sampFreq/frameRate);
            frameRate=this.sampFreq/f;
            this=this.split(t0,t1); %Keeping the requested data only

            if writeFileFlag==1

                %mov = VideoWriter(filename,'Archival');
                mov = VideoWriter(filename,'Uncompressed AVI');
                mov.FrameRate=frameRate;
                %mov.Quality=100;
                open(mov)
            end

            list={'TOE','HEE','HEEL','ANK','SHANK','TIB','KNE','KNEE','THI','THIGH','HIP','GT','ASI','ASIS','PSI','PSIS'};
            [b,~]=this.isaLabelPrefix(strcat('L',list));
            list=list(b);
            ll=this.getOrientedData(unique(cellfun(@(x) x(1:end-1),this.getLabelsThatMatch('^L'),'UniformOutput',false)));
            ll=this.getOrientedData(strcat('L',list));
            rr=this.getOrientedData(unique(cellfun(@(x) x(1:end-1),this.getLabelsThatMatch('^R'),'UniformOutput',false)));
            rr=this.getOrientedData(strcat('R',list));
            dd=this.getOrientedData;
            fh=figure;
            h_axes=gca;
            %drawnow limitrate
            %u = uicontrol('Style','slider','Position',[10 50 20 340],'Min',1,'Max',size(ll,1),'Value',1);


            axis equal
            axis([min(min(dd(:,:,1)))-50 max(max(dd(:,:,1)))+50 min(min(dd(:,:,2)))-50 max(max(dd(:,:,2)))+50 min(min(dd(:,:,3)))-50 max(max(dd(:,:,3)))+900])
            view(90,0)
            hold on
            switch mode
                case 1
                    %Option 1: plain lines

                    L=animatedline(ll(1,:,1),ll(1,:,2),ll(1,:,3),'Marker','o','MarkerSize',10,'MarkerEdgeColor','r');
                    R=animatedline(rr(1,:,1),rr(1,:,2),rr(1,:,3),'Marker','o','MarkerSize',10,'MarkerEdgeColor','b');
                    %set(gca,'NextPlot','replacechildren')
                    for k = 1:f:size(ll,1)
                        %
                        %hold on
                        %axes(ax)
                        clearpoints(L)
                        addpoints(L,ll(k,:,1),ll(k,:,2),ll(k,:,3));
                        clearpoints(R)
                        addpoints(R,rr(k,:,1),rr(k,:,2),rr(k,:,3));
                        %hold off
                        u.Value=k;
                        M(k) = getframe(gcf);
                    end

                case 2
                    %set mannequin color
                    color = [0.2 0.2 0.2]; %gray
                    %Option 2: balloon cartoon (GTO style)
                    for k = 1:f:size(ll,1)
                        cla
                        for side = 1:2 %For each side
                            switch side
                                case 1
                                    s = rr; %Right side
                                    colorLegs=[0 160 198]/255;
                                case 2
                                    s = ll; %Left side
                                    colorLegs=[255 153 0]/255;
                            end
                            for seg = 1:3
                                switch seg
                                    case 1
                                        ind1=1; %Toe
                                        ind2=3; %Ank
                                        radius = [1 .5 .5];
                                    case 2
                                        ind1=3; %Ank
                                        ind2=5; %Knee
                                        radius = [1 .25 .25];
                                    case 3
                                        ind1=5; %Knee
                                        ind2=7; %hip
                                        radius = [1 .35 .35];
                                end
                                X = s(k,[ind1 ind2],1);
                                Y = s(k,[ind1 ind2],2);
                                Z = s(k,[ind1 ind2],3);
                                orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,radius,colorLegs)
                            end
                            %draw hip joints
                            X = s(k,7,1);
                            Y = s(k,7,2);
                            Z = s(k,7,3);
                            orientedLabTimeSeries.drawball(h_axes,X,Y,Z,50,color)
                            %draw shoulder joints: using hip data by default
                            X = s(k,7,1);
                            Y = s(k,7,2);
                            Z = s(k,7,3)+530;
                            orientedLabTimeSeries.drawball(h_axes,X,Y,Z,50,color)
                        end
                        %Draw pelvis
                        X = [rr(k,7,1) ll(k,7,1)];
                        Y = [rr(k,7,2) ll(k,7,2)];
                        Z = [rr(k,7,3) ll(k,7,3)];
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .4 .4],color)
                        %Draw shoulder
                        X = [rr(k,7,1) ll(k,7,1)];
                        Y = [rr(k,7,2) ll(k,7,2)];
                        Z = [rr(k,7,3) ll(k,7,3)]+530;
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .35 .35],color)
                        %Draw torso
                        X = .5*(rr(k,7,1)+ll(k,7,1))+[0 0];
                        Y = .5*(rr(k,7,2)+ll(k,7,2))+[0 0];
                        Z = .5*(rr(k,7,3)+ll(k,7,3))+[0 500]; %Fake torso height
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .4 .4],color)
                        %Draw head
                        X = .5*(rr(k,7,1)+ll(k,7,1))+[0 0];
                        Y = .5*(rr(k,7,2)+ll(k,7,2))+[0 0];
                        Z = .5*(rr(k,7,3)+ll(k,7,3))+500+[60 360]; %Fake head height
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .75 .75],color)

                        %Save frame
                        camlight headlight
                        set(findobj(gca,'type','surface'),...
                            'FaceLighting','gouraud',...
                            'AmbientStrength',.3,...
                            'DiffuseStrength',.8,...
                            'SpecularStrength',.8,...
                            'SpecularExponent',25,...
                            'BackFaceLighting','reverselit')
                        currFrame = getframe;
                        if writeFileFlag==1
                            writeVideo(mov,currFrame);
                        end
                    end
            end
            hold off
            if writeFileFlag==1
                close(mov)
            end
        end

        function mov=animate(this,t0,t1,frameRate,writeFileFlag,filename,mode)
            %This function renders a movie of the 3-D position stored in the orientedLabData object.
            %It only makes sense for markerData type objects.

            if nargin<2 || isempty(t0) || isempty(t1)
                t0=this.Time(1);
                t1=this.Time(end);
            end
            if nargin<7 || isempty(mode)
                mode=2;
            end
            if nargin<5 || isempty(writeFileFlag)
                writeFileFlag=0;
            end
            if nargin<4 || isempty(frameRate)
                frameRate=25;
            end
            if nargin<6 || isempty(filename)
                filename=['anim_t=[' num2str(round(t0*10)/10) ',' num2str(round(t1*10)/10) '].avi'];
            end
            f=round(this.sampFreq/frameRate);
            frameRate=this.sampFreq/f;
            this=this.split(t0,t1); %Keeping the requested data only

            if writeFileFlag==1

                %mov = VideoWriter(filename,'Archival');
                mov = VideoWriter(filename,'Uncompressed AVI');
                mov.FrameRate=frameRate;
                %mov.Quality=100;
                open(mov)
            end

            %             list={'TOE','HEE','HEEL','ANK','SHANK','TIB','KNE','KNEE','THI','THIGH','HIP','GT','ASI','ASIS','PSI','PSIS'};
            list={'ANK','HIP'};
            [b,~]=this.isaLabelPrefix(strcat('L',list));
            list=list(b);
            ll=this.getOrientedData(unique(cellfun(@(x) x(1:end-1),this.getLabelsThatMatch('^L'),'UniformOutput',false)));
            ll=this.getOrientedData(strcat('L',list));
            rr=this.getOrientedData(unique(cellfun(@(x) x(1:end-1),this.getLabelsThatMatch('^R'),'UniformOutput',false)));
            rr=this.getOrientedData(strcat('R',list));
            dd=this.getOrientedData;
            fh=figure;
            h_axes=gca;
            %drawnow limitrate
            %u = uicontrol('Style','slider','Position',[10 50 20 340],'Min',1,'Max',size(ll,1),'Value',1);


            axis equal
            axis([min(min(dd(:,:,1)))-50 max(max(dd(:,:,1)))+50 min(min(dd(:,:,2)))-50 max(max(dd(:,:,2)))+50 min(min(dd(:,:,3)))-50 max(max(dd(:,:,3)))+900])
            view(90,0)
            hold on
            switch mode
                case 1
                    %Option 1: plain lines

                    L=animatedline(ll(1,:,1),ll(1,:,2),ll(1,:,3),'Marker','o','MarkerSize',10,'MarkerEdgeColor','r');
                    R=animatedline(rr(1,:,1),rr(1,:,2),rr(1,:,3),'Marker','o','MarkerSize',10,'MarkerEdgeColor','b');
                    %set(gca,'NextPlot','replacechildren')
                    for k = 1:f:size(ll,1)
                        %
                        %hold on
                        %axes(ax)
                        clearpoints(L)
                        addpoints(L,ll(k,:,1),ll(k,:,2),ll(k,:,3));
                        clearpoints(R)
                        addpoints(R,rr(k,:,1),rr(k,:,2),rr(k,:,3));
                        %hold off
                        u.Value=k;
                        M(k) = getframe(gcf);
                    end

                case 2
                    %set mannequin color
                    color = [0.2 0.2 0.2]; %gray
                    %Option 2: balloon cartoon (GTO style)
                    for k = 1:f:size(ll,1)
                        cla
                        for side = 1:2 %For each side
                            switch side
                                case 1
                                    s = rr; %Right side
                                    colorLegs=[0 160 198]/255;
                                case 2
                                    s = ll; %Left side
                                    colorLegs=[255 153 0]/255;
                            end
                            for seg = 1%:3
                                switch seg
                                    case 1
                                        ind1=1; %Toe
                                        ind2=2; %Ank
                                        radius = [1 .5 .5];
                                    case 2
                                        ind1=3; %Ank
                                        ind2=5; %Knee
                                        radius = [1 .25 .25];
                                    case 3
                                        ind1=5; %Knee
                                        ind2=7; %hip
                                        radius = [1 .35 .35];
                                end
                                X = s(k,[ind1 ind2],1);
                                Y = s(k,[ind1 ind2],2);
                                Z = s(k,[ind1 ind2],3);
                                orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,radius,colorLegs)
                            end
                            %draw hip joints
                            X = s(k,7,1);
                            Y = s(k,7,2);
                            Z = s(k,7,3);
                            orientedLabTimeSeries.drawball(h_axes,X,Y,Z,50,color)
                            %draw shoulder joints: using hip data by default
                            X = s(k,7,1);
                            Y = s(k,7,2);
                            Z = s(k,7,3)+530;
                            orientedLabTimeSeries.drawball(h_axes,X,Y,Z,50,color)
                        end
                        %Draw pelvis
                        X = [rr(k,7,1) ll(k,7,1)];
                        Y = [rr(k,7,2) ll(k,7,2)];
                        Z = [rr(k,7,3) ll(k,7,3)];
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .4 .4],color)
                        %Draw shoulder
                        X = [rr(k,7,1) ll(k,7,1)];
                        Y = [rr(k,7,2) ll(k,7,2)];
                        Z = [rr(k,7,3) ll(k,7,3)]+530;
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .35 .35],color)
                        %Draw torso
                        X = .5*(rr(k,7,1)+ll(k,7,1))+[0 0];
                        Y = .5*(rr(k,7,2)+ll(k,7,2))+[0 0];
                        Z = .5*(rr(k,7,3)+ll(k,7,3))+[0 500]; %Fake torso height
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .4 .4],color)
                        %Draw head
                        X = .5*(rr(k,7,1)+ll(k,7,1))+[0 0];
                        Y = .5*(rr(k,7,2)+ll(k,7,2))+[0 0];
                        Z = .5*(rr(k,7,3)+ll(k,7,3))+500+[60 360]; %Fake head height
                        orientedLabTimeSeries.drawsegment(h_axes,X,Y,Z,[1 .75 .75],color)

                        %Save frame
                        camlight headlight
                        set(findobj(gca,'type','surface'),...
                            'FaceLighting','gouraud',...
                            'AmbientStrength',.3,...
                            'DiffuseStrength',.8,...
                            'SpecularStrength',.8,...
                            'SpecularExponent',25,...
                            'BackFaceLighting','reverselit')
                        currFrame = getframe;
                        if writeFileFlag==1
                            writeVideo(mov,currFrame);
                        end
                    end
            end
            hold off
            if writeFileFlag==1
                close(mov)
            end
        end
    end

    %% Static Methods
    methods (Static)
        function OTS=getOTSfromOrientedData(data,t0,Ts,labelPrefixes,orientation)
            labels=[strcat(labelPrefixes,'x');strcat(labelPrefixes,'y');strcat(labelPrefixes,'z')];
            data=permute(data,[1,3,2]);
            OTS=orientedLabTimeSeries(data(:,:),t0,Ts,labels(:),orientation);
        end

        function extendedLabels=addLabelSuffix(labels)
            %Add component suffix to each label
            %
            %example:
            %labels = {'RHIP','LHIP',...}
            %extendedLabels = addLabelSuffix(labels);
            %extendedLabels = {'RHIPx','RHIPy','RHIPz','LHIPx','LHIPy','LHIPz',...}

            if ischar(labels)
                labels={labels};
            end
            extendedLabels=cell(length(labels)*3,1);
            extendedLabels(1:3:end)=strcat(labels,'x');
            extendedLabels(2:3:end)=strcat(labels,'y');
            extendedLabels(3:3:end)=strcat(labels,'z');
        end

        function labelSane=checkLabelSanity(labels)
            %Check to make sure that labels are in expected or workable
            %format
            %
            %checks that there are multiples of 3 labels,i.e.
            %{'RHIPx','RHIPy','RHIPz',...}
            %
            %checks that x,y,z are labeled in that order
            %
            %also checks that each group of 3 labels have the same prefix

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

    %% Hidden Static Methods
    methods (Hidden, Static)
        % Auxiliar functions for this.animate()
        function drawsegment(h_axes,X1,Y1,Z1,a,color)
            %draw an ellipsoid aligned to line defined by 2 points
            %a defines relative length of the ellipsoid radii
            O = [X1(1) Y1(1) Z1(1)]; %vector origin
            V = [X1(2)-X1(1) Y1(2)-Y1(1) Z1(2)-Z1(1)]; %vector
            [theta,phi,r] = cart2sph(V(1),V(2),V(3)); %theta is angle with x-axis, phi is angle with z-axis, r is length of segment
            %build segment surface and rotate/translate
            [X,Y,Z] = ellipsoid(r/2,0,0,r/2,r/2*a(2)/a(1),r/2*a(3)/a(1)); %build segment surface about origin
            h = surf(X,Y,Z,'FaceColor',color,'EdgeColor','none');
            t = hgtransform('Parent',h_axes);
            set(h,'Parent',t)
            Ry = makehgtform('yrotate',-phi);
            Rz = makehgtform('zrotate',theta);
            Tx = makehgtform('translate',O);
            set(t,'Matrix',Tx*Rz*Ry)
        end

        function drawball(h_axes,X1,Y1,Z1,radius,color)
            %draw a ball centered at a defined point
            O = [X1 Y1 Z1]; %vector origin
            %build ball surface and translate
            [X,Y,Z] = sphere; %build segment surface about origin
            h = surf(X,Y,Z,'FaceColor',color,'EdgeColor','none');
            t = hgtransform('Parent',h_axes);
            set(h,'Parent',t)
            S = makehgtform('scale',radius);
            Tx = makehgtform('translate',O);
            set(t,'Matrix',Tx*S)
        end

        function drawcylinder(h_axes,X1,Y1,Z1,radius,color)
            %draw a cylinder centered around line defined by 2 points
            %radius defines the radii of the coned-cylinder
            O = [X1(1) Y1(1) Z1(1)]; %vector origin
            V = [X1(2)-X1(1) Y1(2)-Y1(1) Z1(2)-Z1(1)]; %vector
            %build surface and rotate/translate
            [theta,phi,r] = cart2sph(V(1),V(2),V(3)); %theta is angle with x-axis, phi is angle with z-axis, r is length of segment
            [X,Y,Z] = cylinder(radius); %build segment surface about origin
            h = surf(X,Y,Z,'FaceColor',color,'EdgeColor','none');
            t = hgtransform('Parent',h_axes);
            set(h,'Parent',t)
            Sz = makehgtform('scale',[1,1,r]);
            Ry1 = makehgtform('yrotate',pi/2);
            Ry2 = makehgtform('yrotate',-phi);
            Rz = makehgtform('zrotate',theta);
            Tx = makehgtform('translate',O);
            set(t,'Matrix',Tx*Rz*Ry2*Ry1*Sz)
        end
    end

end

