classdef naiveDistances < markerModel
    %summary stats: pair-wise component differences
    %model: independent normals

    methods
        function this = naiveDistances(trainData,labs)
            this = this@markerModel(trainData,labs);
            ss   = this.getRobustStd(0.94);
            %Why is the second cosntraint here?
            this.activeStats = ss < 15 & ss < (this.statMean/2);
        end
        function [logL,g] = loglikelihood(this,data)
            ss = this.summaryStats(data);
            %sigma=this.statStd;
            sigma = this.getRobustStd(0.94);
            %mu=this.statMean;
            mu   = this.statMedian;
            logL = markerModel.normalLogL(ss,mu,sigma);
            logL(~this.activeStats,:) = 0;
            logL = logL(this.activeStats,:);
            logL(isnan(logL)) = 0;
            g = [];
        end
        function i = indicatrix(this,fullFlag,M) %MxP
            if nargin < 3 || isempty(M)
                M = this.Nmarkers;
            end
            ind = triu(true(M),1);
            i   = nan(M,M*(M-1)/2);
            for mrkr = 1:M
                aux = zeros(M);
                aux(:,mrkr) = 1;
                aux(mrkr,:) = 1;
                i(mrkr,:) = aux(ind(:));
            end
            if nargin < 2 || isempty(fullFlag) || fullFlag == false
                i = i(:,this.activeStats); %Default
            end
        end
        function fh = seeModel(this)
            fh = this.seeModel@markerModel;
            subplot(3,2,[2,4,6])
            hold on
            m     = median(this.trainingData, 3, 'omitnan');
            i     = this.indicatrix;
            sigma = this.getRobustStd(0.94);
            sigma = sigma(this.activeStats);
            mu    = this.statMedian(this.activeStats);
            for stt = 1:size(i,2)
                %if this.activeStats(stt)
                aux = find(i(:,stt));
                n   = mean(m(aux,:));
                for k = 1:length(aux)
                    plot3([n(1) m(aux(k),1)],[n(2) m(aux(k),2)], ...
                        [n(3) m(aux(k),3)],'k')
                end
                text(n(1),n(2),n(3), ...
                    ['mu=' num2str(mu(stt),3) ', sigma=' ...
                    num2str(sigma(stt),2)])
                %end
            end
        end
        function [badFlag,mirrorOutliers,outOfBoundsOutlier] = ...
            validateMarkerModel(this,verbose)
            %TODO: change this to load getRefData() and use the bounds from
            %there as the ONLY source of testing. If that works well, move
            %this function to markerModel(), since it won't have any class
            %specific information, other than what getRefData() provides
            %This function compares a trained model vs. a reference model
            %of the class, and returns a potential list of markers with
            %issues. It is meant to be used as a diagnostics tool to detect
            %bad models (possibly caused by bad training data).
            outOfBoundsOutlier = false(size(this.trainingData,1),1);
            if nargin < 2 || isempty(verbose)
                verbose = true;
            end
            badFlag = false;
            %Check three things:
            %1) No marker is closer to a contralateral marker
            %than its ipsilateral counterpart
            %This requires L/R markers to be sorted properly
            mu         = naiveDistances.stat2Matrix(this.statMedian);
            M          = size(mu,1);
            firstHalf  = 1:ceil(M/2);
            secondHalf = ceil(M/2)+1:M;
            mu1        = triu(mu(firstHalf,firstHalf));
            mu2        = triu(fliplr(mu(firstHalf,secondHalf)));
            mu3        = triu(mu(secondHalf,secondHalf));
            mu4        = triu(flipud(mu(firstHalf,secondHalf)));
            %Using 700mm as a threshold for distances to look at
            D          = [mu2 < mu1,zeros(size(mu1));zeros(size(mu1)), ...
                mu4 < mu3] & mu([firstHalf secondHalf], ...
                [firstHalf secondHalf]) < 700;
            %otherwise we compare something like RPSIS to RTOE and LTOE,
            %which by geometry are almost equally far from RPSIS, and any
            %movement or placement asymmetry will raise an alarm.
            %Excluding SHANK and THIGH from this, since markers are not
            %meant to be placed symmetrically
            [bool,idxs] = compareListsNested(this.markerLabels, ...
                {'RTHI','LTHI','LTHIGH','RTHIGH','RSHANK','LSHANK', ...
                'LSHA','RSHA','LSHNK','RSHNK'});
            D(idxs(bool),:) = false;
            D(:,idxs(bool)) = false;
            outMarkers1 = ...
                markerModel.untangleOutliers( ...
                naiveDistances.distMatrix2stat(D),this.indicatrix(true));
            if any(outMarkers1)
                if verbose
                    fprintf([ ...
                        'Mislabeled markers. Contralat. distances > ' ...
                        'ipsilat. for: '])
                    fprintf([cell2mat( ...
                        strcat(this.markerLabels(outMarkers1),', ')) '\n'])
                end
                badFlag = true;
            end
            mirrorOutliers = outMarkers1;

            %2) The two (three?) closest markers (ipsilaterally along
            %z-axis: as sorted before) to any given marker have std<10
            sigma = naiveDistances.stat2Matrix(this.getRobustStd(0.94));
            if any(any(triu(sigma)-triu(sigma,3))) > 10
                if verbose
                    fprintf([ ...
                        'Too much variability for adjacent markers.\n'])
                end
                badFlag = true;
            end

            %3) No marker pair has a distance outside the admissible bounds
            load distanceModelReferenceData.mat
            [bool,idxs] = compareListsNested(this.markerLabels, ...
                markerLabels);
            list1 = this.markerLabels(idxs(bool));
            list2 = markerLabels(bool);
            if ~all(strcmp(list1,list2))
                error('Incompatible lists')
            end
            upperBound = upperBound(bool,bool);
            lowerBound = lowerBound(bool,bool);
            reducedMu  = mu(idxs(bool),idxs(bool));
            if any(any(reducedMu < lowerBound | reducedMu > upperBound))
                D = zeros(size(mu));
                D(idxs(bool),idxs(bool)) = reducedMu < lowerBound | ...
                    reducedMu > upperBound;
                in          = this.indicatrix(true);
                outMarkers2 = ...
                    markerModel.untangleOutliers( ...
                    naiveDistances.distMatrix2stat(D),in);
                if verbose
                    fprintf([ ...
                        'Marker distances above or below the allowed ' ...
                        'limits for markers: '])
                    fprintf([cell2mat( ...
                        strcat(this.markerLabels(outMarkers2),', ')) '\n'])
                end
                % [ii,jj]=find(reducedMu<lowerBound | reducedMu>upperBound);
                % for i1=1:length(ii)
                %    disp(['Mean distance from ' ...
                %    distanceModel.markerLabels{ ...
                %    ii(i1)} ' to ' distanceModel.markerLabels{ ...
                %    jj(i1)} ' (' num2str(reducedMu(ii(i1),jj(i1)), ...
                %    3) 'mm) exceeds limits [' num2str( ...
                %    lowerBound(ii(i1),jj(i1)), ...
                %    3) ', ' num2str(upperBound(ii(i1),jj(i1)),3) 'mm].'])
                % end
                badFlag = true;
                outOfBoundsOutlier = outMarkers2;
            end

        end
        function [permutationList,newModel] = permuteModelLabels(model)
            %Checks if a model is invalid, and if it is, tries to find label
            %permutations that would make it valid.
            %TO DO: can this be achieved by just finding permutations of
            %the training data of the model against the reference model? If
            %so we can avoid duplicating code.
            %Iny any case, this can be moved to markerModel()
            %See also: naiveDistances.validateMarkerModel
            %markerModel.validateMarkerModel

            [~,mirrorOutliers,outOfBoundsOutlier] = ...
                model.validateMarkerModel(false);
            nBad     = sum(mirrorOutliers | outOfBoundsOutlier);
            nBinit   = nBad;
            newModel = model;
            %if nBad>10 %Too many permutations, search is not feasible
            %    error('Too many possible permutations, search is not
            %    feasible')
            %end

            %First try with permutations of markers marked as bad:
            permutationList = nan(0,2);
            if nBad > 1 && any(mirrorOutliers)
                [newModel,permutationList,nBad] = ...
                    tryPermutations(newModel,find(mirrorOutliers));
            end

            %Second: if there are still bad things, try with permutations of
            %mirror outliers OR outOfBounds
            if nBad > 1
                [~,mirrorOutliers,outOfBoundsOutlier] = ...
                    validateMarkerModel(newModel,false);
                [newModel,permutationList2,nBad] = ...
                    tryPermutations(model, ...
                    find(mirrorOutliers | outOfBoundsOutlier));
                permutationList = [permutationList;permutationList2];
            end

            %Third: try with permutations of everything (possibly unfeasible
            %because of number of permutations to try)
            %if nBad>0
            %    [~,mirrorOutliers,outOfBoundsOutlier] = ...
            %    validateMarkerModel(model,false);
            %    [newModel,permutationList2,nBad]=tryPermutations(model, ...
            %    find(mirrorOutliers | outOfBoundsOutlier));
            %    permutationList=[permutationList;permutationList2];
            %end

            if nBad == 0 %No issues remain
                %disp('Success! Found permutation that fixes issues.')
            elseif nBad < nBinit
                %warning('Improved results through permutation, but some
                %issues remain.')
            else
                %warning('No improvement was found')
                permutationList = [];
                newModel        = model;
            end
        end
        function newModel = applyPermutation(model,permutation)
            %TODO: applying a permutation should require to only permute
            %labels.
            % Also, if this function is needed, should be in markerModel
            % superclass
            newModel = model;
            %First, permute the training data:
            for ii = 1:size(permutation,1)
                newModel.trainingData(permutation(ii,:),:,:) = ...
                    newModel.trainingData(fliplr(permutation(ii,:)),:,:);
            end
            %Inefficient: re-train
            newModel = naiveDistances(newModel.trainingData, ...
                newModel.markerLabels);
            %Efficient:...
        end
        function mleData = reconstruct(this,data,dataPriors,fastFlag)
            %INPUTs:
            %this: a model
            %data: M (markers) x3(dim) xN (frames)
            %priors: MxN or Mx1 matrix containing the uncertainty (std) in
            %positions we think we have: assumes spherical uncertainty
            [M,D,N] = size(data);
            if nargin < 3 || isempty(dataPriors)
                %Assume that priors are each marker's score according to
                %this same model
                %priors=...
                dataPriors = ones(M,N);
            end
            if nargin < 4 || isempty(fastFlag)
                fastFlag = false;
            end
            mleData = nan(size(data));
            wD      = 1./this.getRobustStd(0.94).^2;
            wD(wD > 1) = 1; %Don't trust any distance TOO much
            lastSol = [];
            for k = 1:N
                %TODO: for speed, only run if at least one dataPrior is
                %larger than X mm (ie. if we are certain about ALL markers,
                %there is nothing to optimize for).
                %TODO: based on training data, estimate a decent threshold
                %for the cost function of the reconstruction
                wP = 1./dataPriors(:,k).^2;
                %Don't trust any position TOO much, leads to bad numerical
                %properties
                wP(wP > 1) = 1;
                lastSol = naiveDistances.invertAndAnchor(this.statMean, ...
                    data(:,:,k),wP,wD,lastSol,fastFlag);
                mleData(:,:,k) = lastSol;
            end
            %Validate result:
            %             logLBefore=this.loglikelihood(data);
            %             outlierBefore=this.outlierDetectFast(data);
            %             logLAfter=this.loglikelihood(mleData);
            %             outlierAfter=this.outlierDetectFast(mleData);
            %             if any(outlierAfter & ~outlierBefore) || ...
            %    any((logLAfter<logLBefore) & (logLAfter<-5))
            %                 warning('Reconstruction made some things
            %                 worse: this is not working.')
            %             end
            %             if any(outlierAfter)
            %                 warning('Reconstruction did not remove all
            %                 outliers: try reducing confidence in original
            %                 measurements')
            %             end
        end
    end
    methods(Hidden)
        % function [model,permutationList,nBad]=tryPermutations(model, ...
        %    listToPermute)
        %     %TODO: test this agains markerModel.tryPermutations() and see
        %     %which one performs best & fastest. If not this one,
        %     deprecate.
        %
        %     %Overload!
        %     permutationList=zeros(0,2);
        %     %Benchmark to compare:
        %     [~,mirrorOutliers,outOfBoundsOutlier] = ...
        %    validateMarkerModel(model,false);
        %     nBad=sum(mirrorOutliers | outOfBoundsOutlier);
        %
        %     while nBad>0
        %         %Permutations to consider:
        %         listOfPermutations=nchoosek(listToPermute,2);
        %         N=size(listOfPermutations,1);
        %         count=0;
        %         while count<N
        %            count=count+1;
        %            modelAux=applyPermutation(model, ...
        %    listOfPermutations(count,:)); %Permute
        %            [~,newMO,newOBO] = validateMarkerModel(modelAux,false);
        %            newNB=sum(newMO | newOBO);
        %            if newNB<nBad %Found permutation that improves things
        %                break
        %            end
        %         end
        %         if newNB>=nBad %Checking if while exited without making
        %         any improvements
        %             return
        %         else %Improvement was made!
        %             %New benchmark:
        %             model=modelAux;
        %             [~,mirrorOutliers,outOfBoundsOutlier] = ...
        %    validateMarkerModel(model,false);
        %             nBad=sum(mirrorOutliers | outOfBoundsOutlier);
        %             permutationList=[permutationList; ...
        %    listOfPermutations(count,:)]; %Adding permutation to list
        %         end
        %     end
        % end
        function dataFrame = invertAndAnchor(ss,anchorFrame, ...
            anchorWeights,distanceWeights,initGuess,fastFlag)
            knownDistances  = naiveDistances.stat2DistMatrix(ss);
            distanceWeights = ...
                naiveDistances.stat2DistMatrix(distanceWeights);
            if nargin < 6 || isempty(fastFlag)
                fastFlag = false;
            end
            if ~fastFlag
                dataFrame = getPositionFromDistances_v3(anchorFrame, ...
                    knownDistances,anchorWeights,distanceWeights,initGuess);
            else
                %Option 1:
                %knownDistances=stat2DistMatrix(ss);
                %[dataFrame] = getPositionFromDistances_v2(anchorFrame, ...
                %    knownDistances,anchorWeights,anchorFrame);
                %Option 2:
                %Divide markers in certain and uncertain. Certain markers
                %are
                %offered as knownPositions and NOT optimized for.
                %Uncertain markers are optimized for, and have no known
                %positions
                dataFrame    = anchorFrame;
                %Arbitrary threshold
                fixedMarkers = anchorWeights >= 0.5 | ...
                    isnan(anchorWeights) | anchorWeights == Inf;
                if any(~fixedMarkers)
                    anchorFrame     = anchorFrame(fixedMarkers,:);
                    knownDistances  = ...
                        knownDistances(fixedMarkers,~fixedMarkers);
                    distanceWeights = ...
                        distanceWeights(fixedMarkers,~fixedMarkers);
                    anchorWeights   = anchorWeights(~fixedMarkers);
                    if ~isempty(initGuess)
                        initGuess = initGuess(~fixedMarkers,:);
                    end
                    %TODO:
                    %Do the optimization one marker at a time. May be
                    %slower, but better conditioned.
                    %After optimizing: check that the result is decent (no
                    %outlier markers remain)
                    aux = getPositionFromDistances_v3(anchorFrame, ...
                        knownDistances,zeros(size(anchorWeights)), ...
                        distanceWeights,initGuess);
                    dataFrame(~fixedMarkers,:) = aux;
                end
            end
        end
    end
    methods(Static)
        %Implementing superclass required methods:
        function [ss,g] = summaryStats(data)
            D  = computeDistanceMatrix(data);
            ss = naiveDistances.distMatrix2stat(D);
            if nargout > 2
                g = []; %TODO
            end
        end
        function this = learn(data,labels,noDisp)
            if nargin < 2
                labels = {};
            end
            this = naiveDistances(data,labels);
            if nargin < 3 || isempty(noDisp) || ~noDisp
                this.seeModel()
            end

        end
        function [D,xl,yl] = stat2Matrix(ss)
            D  = triu(naiveDistances.stat2DistMatrix(ss));
            xl = 'markerLabels';
            yl = 'markerLabels';
        end
        function [model,meanLB,meanUB,stdLB,stdUB,A,b] = getRefData()
            [model,lowerBound,upperBound] = ...
                load('../data/distanceModelReferenceData.mat');
            meanLB = naiveDistances.distMatrix2stat(lowerBound);
            meanUB = naiveDistances.distMatrix2stat(upperBound);
            stdLB  = zeros(size(meanLB));
            stdUB  = Inf*ones(size(meanLB));
            A      = zeros(0,size(meanLB,2));
            b      = zeros(0,1);
        end

        %Subclass-specific functions:
        function D = stat2DistMatrix(ss)
            %ss is M(M-1)/2 x N
            M   = ceil(sqrt(2*size(ss,1)));
            N   = size(ss,2);
            ind = triu(true(M),1);
            D   = zeros(M^2,N);
            D(ind,:) = ss;
            D = reshape(D,M,M,N);
            D = D+permute(D,[2,1,3]);
        end
        function ss = distMatrix2stat(D)
            %D can be MxM or MxMxN
            M   = size(D,1);
            N   = size(D,3);
            ss  = reshape(D,M^2,N);
            ind = triu(true(M),1);
            %Keeping only upper half: PxN, with P=M*(M-1)/2
            ss  = ss(ind(:),:);
        end
    end
end
