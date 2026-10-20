classdef naiveDistances < markerModel
    %NAIVEDISTANCES Marker model of the pairwise distances between markers.
    %
    %   The summary statistics are the distances between each pair of
    % markers (upper triangle of the distance matrix). The model treats them
    % as independent normal variables (naive Bayes) with robust standard
    % deviations. Statistics are active only if their robust standard
    % deviation is below 15 mm and below half their mean.
    %
    % NOTE: work in progress. validateMarkerModel loads
    % distanceModelReferenceData.mat, and reconstruct and getRefData depend
    % on files that are not in the repository.
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %   (inherited from markerModel: prctile), Optimization Toolbox
    %   (inherited). Low confidence: the dependency analyzer reported None
    %   for this file.
    %
    % See also MARKERMODEL.

    methods
        function this = naiveDistances(trainData,labs)
            %NAIVEDISTANCES Train a pairwise-distance model.
            %
            %   this = NAIVEDISTANCES(trainData,labs) trains the superclass
            % model and activates the statistics with a robust standard
            % deviation (94% central interval) below 15 mm and below half of
            % their mean.
            %
            % Inputs:
            %   trainData - markers x 3 x frames training positions
            %   labs      - markers x 1 cell array of marker labels
            %
            % Outputs:
            %   this - naiveDistances object
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %   (prctile)

            this = this@markerModel(trainData,labs);
            ss   = this.getRobustStd(0.94); % TODO: source? (94% interval)
            %Why is the second cosntraint here?
            this.activeStats = ss < 15 & ss < (this.statMean/2);
        end
        function [logL,g] = loglikelihood(this,data)
            %LOGLIKELIHOOD Log-likelihood of the active statistics.
            %
            %   [logL,g] = LOGLIKELIHOOD(this,data) evaluates the pairwise
            % distances of the data under independent normal distributions
            % with the training median and robust standard deviation. NaN
            % values count as 0.
            %
            % Inputs:
            %   this - naiveDistances object
            %   data - markers x 3 x frames positions
            %
            % Outputs:
            %   logL - active statistics x frames log-likelihoods
            %   g    - not assigned (gradient not implemented)
            %
            % Toolbox Dependencies: None

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
            %INDICATRIX Which pairwise distances involve each marker.
            %
            %   i = INDICATRIX(this,fullFlag,M) returns a matrix with a 1 in
            % (m,p) when statistic p (a marker pair) involves marker m.
            %
            % Inputs:
            %   this     - naiveDistances object
            %   fullFlag - (optional) true to keep all M*(M-1)/2 statistics
            %              instead of only the active ones (default: false)
            %   M        - (optional) number of markers (default:
            %              this.Nmarkers)
            %
            % Outputs:
            %   i - markers x statistics indicator matrix (MxP)
            %
            % Toolbox Dependencies: None

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
            %SEEMODEL Plot the model, marking each active statistic in 3-D.
            %
            %   fh = SEEMODEL(this) calls the superclass plot and, in its
            % 3-D axes, draws a segment from the middle of every active
            % marker pair to its two markers and writes the mean and
            % standard deviation of the pair.
            %
            % Inputs:
            %   this - naiveDistances object
            %
            % Outputs:
            %   fh - figure handle
            %
            % Toolbox Dependencies: None
            %
            % See also MARKERMODEL.SEEMODEL.

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
            %VALIDATEMARKERMODEL Compare a model with reference data.
            %
            %   [badFlag,mirrorOutliers,outOfBoundsOutlier] =
            % VALIDATEMARKERMODEL(this, verbose) returns markers with
            % potential issues; it is a diagnostic to detect bad models
            % (possibly caused by bad training data). It checks that (1) no
            % marker is closer to a contralateral marker than to its
            % ipsilateral counterpart (this requires left and right markers
            % to be sorted properly; only distances below 700 mm are
            % compared, and the thigh and shank markers are excluded because
            % they are not placed symmetrically), (2) the closest markers to
            % any marker have a standard deviation below 10 mm, and (3) no
            % distance is outside the bounds of the reference data. Prints
            % the findings if verbose.
            %
            % Side effects: loads distanceModelReferenceData.mat (not in the
            % repository) from the path and errors with 'Incompatible lists'
            % if the marker labels do not match; prints to the command
            % window.
            %
            % TODO: load getRefData() and use its bounds as the only source
            % of testing; then move this function to markerModel.
            %
            % Inputs:
            %   this    - naiveDistances object
            %   verbose - (optional) print the findings (default: true)
            %
            % Outputs:
            %   badFlag            - true if any check fails
            %   mirrorOutliers     - markers failing check 1
            %   outOfBoundsOutlier - markers failing check 3
            %
            % Toolbox Dependencies: None
            %
            % See also MARKERMODEL.VALIDATEMARKERMODEL.

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
            maxCompareDist = 700; % mm: threshold for distances to look at
            %Using 700mm as a threshold for distances to look at
            D          = [mu2 < mu1,zeros(size(mu1));zeros(size(mu1)), ...
                mu4 < mu3] & mu([firstHalf secondHalf], ...
                [firstHalf secondHalf]) < maxCompareDist;
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
            maxAdjacentStd = 10; % mm
            if any(any(triu(sigma)-triu(sigma,3))) > maxAdjacentStd
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
            %PERMUTEMODELLABELS Find permutations that fix a model.
            %
            %   [permutationList,newModel] = PERMUTEMODELLABELS(model)
            % checks if the model is invalid and, if so, tries permutations
            % of the markers marked as bad (first the mirror outliers, then
            % those or the out-of-bounds ones) until the validation passes.
            % If the permutations do not reduce the number of bad markers,
            % the model is returned unchanged with an empty list.
            %
            % NOTE: calls tryPermutations with the signature of the
            % commented-out version at the end of this file, which is not
            % the one in markerModel.
            %
            % TODO: can this be achieved by just finding permutations of the
            % training data against the reference model? If so, duplicated
            % code is avoided. It could also be moved to markerModel.
            %
            % Inputs:
            %   model - naiveDistances object
            %
            % Outputs:
            %   permutationList - permutations applied, one pair per row
            %   newModel        - model after the permutations
            %
            % Toolbox Dependencies: None
            %
            % See also VALIDATEMARKERMODEL, MARKERMODEL.VALIDATEMARKERMODEL.

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
            %APPLYPERMUTATION Swap marker pairs and retrain.
            %
            %   newModel = APPLYPERMUTATION(model,permutation) swaps the
            % rows of the training data listed in each row of permutation
            % and trains a new model from the permuted data (inefficient).
            %
            % TODO: applying a permutation should only require permuting the
            % labels. If this function is needed, it should be in the
            % markerModel superclass.
            %
            % Inputs:
            %   model       - naiveDistances object
            %   permutation - n x 2 pairs of marker indices to swap
            %
            % Outputs:
            %   newModel - retrained model
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %   (prctile)

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
            %RECONSTRUCT Reconstruct positions from model distances.
            %
            %   mleData = RECONSTRUCT(this,data,dataPriors,fastFlag) finds,
            % frame by frame, the positions that best satisfy the model mean
            % distances while staying close to the measured positions.
            % Weights are the inverse variance of the positions (from
            % dataPriors) and of the distances (from the robust standard
            % deviation), capped at 1 so no position or distance is trusted
            % too much (numerical conditioning). Uses
            % getPositionFromDistances_v3, which is not in the repository.
            %
            % TODO: only run if at least one prior is larger than some
            % threshold in mm (nothing to optimize if all markers are
            % certain).
            % TODO: estimate a decent threshold for the cost function from
            % the training data.
            %
            % Inputs:
            %   this       - naiveDistances object
            %   data       - markers x 3 x frames positions
            %   dataPriors - (optional) markers x frames or markers x 1
            %                uncertainty (std) of the positions, assuming
            %                spherical uncertainty (default: ones)
            %   fastFlag   - (optional) optimize only the uncertain markers
            %                (default: false)
            %
            % Outputs:
            %   mleData - markers x 3 x frames reconstructed positions
            %
            % Toolbox Dependencies: None

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
            %INVERTANDANCHOR Positions from distances and anchors.
            %
            %   dataFrame = INVERTANDANCHOR(ss,anchorFrame,anchorWeights,
            % distanceWeights,initGuess,fastFlag) finds positions whose
            % pairwise distances match the statistics ss, weighted by
            % anchorWeights toward anchorFrame, using
            % getPositionFromDistances_v3 (not in the repository). With
            % fastFlag, markers that are certain (weight at least 0.5, NaN
            % or Inf) are kept as known positions and only the others are
            % optimized.
            %
            % TODO: optimize one marker at a time (slower but better
            % conditioned) and check that no outlier marker remains in the
            % result.
            %
            % Inputs:
            %   ss              - pairwise distance statistics (P x 1)
            %   anchorFrame     - markers x 3 measured positions
            %   anchorWeights   - markers x 1 weights of the measured
            %                     positions
            %   distanceWeights - weights of the distances (P x 1)
            %   initGuess       - initial positions, or empty
            %   fastFlag        - (optional) optimize only uncertain markers
            %                     (default: false)
            %
            % Outputs:
            %   dataFrame - markers x 3 positions
            %
            % Toolbox Dependencies: None

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
            %SUMMARYSTATS Pairwise distances between markers as statistics.
            %
            %   [ss,g] = SUMMARYSTATS(data) returns the upper triangle of
            % the distance matrix of every frame.
            %
            % Inputs:
            %   data - markers x 3 x frames positions
            %
            % Outputs:
            %   ss - P x frames distances, P = M*(M-1)/2
            %   g  - not assigned (gradient not implemented)
            %
            % Toolbox Dependencies: None
            %
            % See also DISTMATRIX2STAT.

            D  = computeDistanceMatrix(data);
            ss = naiveDistances.distMatrix2stat(D);
            if nargout > 2
                g = []; %TODO
            end
        end
        function this = learn(data,labels,noDisp)
            %LEARN Train a model and show it.
            %
            %   this = LEARN(data,labels,noDisp) trains a naiveDistances
            % model and, unless noDisp is true, plots it with seeModel.
            %
            % Inputs:
            %   data   - markers x 3 x frames training positions
            %   labels - (optional) marker labels (default: {})
            %   noDisp - (optional) true to skip the plot (default: false)
            %
            % Outputs:
            %   this - trained naiveDistances object
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %   (prctile)

            if nargin < 2
                labels = {};
            end
            this = naiveDistances(data,labels);
            if nargin < 3 || isempty(noDisp) || ~noDisp
                this.seeModel()
            end

        end
        function [D,xl,yl] = stat2Matrix(ss)
            %STAT2MATRIX Statistics as an upper-triangular matrix.
            %
            %   [D,xl,yl] = STAT2MATRIX(ss) returns the statistics as a
            % matrix indexed by markers; the axis labels are the string
            % 'markerLabels', meaning the model marker labels.
            %
            % Inputs:
            %   ss - P x 1 statistics
            %
            % Outputs:
            %   D  - M x M upper-triangular matrix
            %   xl - 'markerLabels'
            %   yl - 'markerLabels'
            %
            % Toolbox Dependencies: None

            D  = triu(naiveDistances.stat2DistMatrix(ss));
            xl = 'markerLabels';
            yl = 'markerLabels';
        end
        function [model,meanLB,meanUB,stdLB,stdUB,A,b] = getRefData()
            %GETREFDATA Reference model and distance bounds.
            %
            %   [model,meanLB,meanUB,stdLB,stdUB,A,b] = GETREFDATA() loads
            % the reference bounds from
            % ../data/distanceModelReferenceData.mat (not in the repository;
            % relative to the current folder). The standard deviation bounds
            % are 0 and Inf and there are no inequality constraints.
            %
            % Outputs:
            %   model  - reference model
            %   meanLB - lower bounds of the mean distances
            %   meanUB - upper bounds of the mean distances
            %   stdLB  - lower bounds of the standard deviations (zeros)
            %   stdUB  - upper bounds of the standard deviations (Inf)
            %   A      - inequality constraint matrix (empty)
            %   b      - inequality constraint vector (empty)
            %
            % Toolbox Dependencies: None

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
            %STAT2DISTMATRIX Statistics to symmetric distance matrices.
            %
            %   D = STAT2DISTMATRIX(ss) places the statistics in the upper
            % triangle and mirrors them to the lower triangle; the diagonal
            % is 0.
            %
            % Inputs:
            %   ss - M*(M-1)/2 x N statistics
            %
            % Outputs:
            %   D - M x M x N symmetric distance matrices
            %
            % Toolbox Dependencies: None
            %
            % See also DISTMATRIX2STAT.

            M   = ceil(sqrt(2*size(ss,1)));
            N   = size(ss,2);
            ind = triu(true(M),1);
            D   = zeros(M^2,N);
            D(ind,:) = ss;
            D = reshape(D,M,M,N);
            D = D+permute(D,[2,1,3]);
        end
        function ss = distMatrix2stat(D)
            %DISTMATRIX2STAT Distance matrices to statistics.
            %
            %   ss = DISTMATRIX2STAT(D) keeps the upper triangle (without
            % the diagonal) of each distance matrix.
            %
            % Inputs:
            %   D - M x M or M x M x N distance matrices
            %
            % Outputs:
            %   ss - M*(M-1)/2 x N statistics
            %
            % Toolbox Dependencies: None
            %
            % See also STAT2DISTMATRIX.

            M   = size(D,1);
            N   = size(D,3);
            ss  = reshape(D,M^2,N);
            ind = triu(true(M),1);
            %Keeping only upper half: PxN, with P=M*(M-1)/2
            ss  = ss(ind(:),:);
        end
    end
end
