classdef markerModel
    %MARKERMODEL Abstract statistical model of a marker set.
    %
    %   Stores the training marker data (markers x 3 x frames) and the
    % distribution of a set of summary statistics of it, computed with the
    % subclass method summaryStats(). Subclasses implement loglikelihood,
    % indicatrix, reconstruct, learn, summaryStats, stat2Matrix and
    % getRefData. The model scores new data (per marker and per frame),
    % detects outlier markers and tries label permutations that improve the
    % fit.
    %
    % NOTE: work in progress. validateMarkerModel, labelData, dropMarkers,
    % sortMarkerOrder and getSharedMarkerList are unimplemented stubs, and
    % several methods call functions that are not in the repository
    % (getTranslationAndRotation).
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %   (prctile), Optimization Toolbox (fmincon, linprog, intlinprog,
    %   optimoptions). Low confidence: the dependency analyzer reported only
    %   Optimization; prctile was added by hand.
    %
    % See also NAIVEDISTANCES.

    properties
        markerLabels %Mx1 cell array
        trainingData %Mx3xN
        statMean
        statStd
        %Stores prctiles for log-l distribution in training data
        trainingLogLPrctiles = [];
        statPrctiles
        activeStats
    end
    properties(Dependent)
        Nmarkers
        statMedian
    end

    methods
        function mm = markerModel(trainData,labels)
            %MARKERMODEL Train a marker model from marker data.
            %
            %   mm = MARKERMODEL(trainData,labels) computes the summary
            % statistics of the training data and stores their mean,
            % standard deviation and 0 to 100th percentiles (and the
            % percentiles of the log-likelihood of the training data). All
            % statistics start out active.
            %
            % Inputs:
            %   trainData - markers x 3 x frames training positions
            %   labels    - markers x 1 cell array of marker labels
            %
            % Outputs:
            %   mm - markerModel object
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %   (prctile)

            mm.markerLabels = labels;
            mm.trainingData = trainData;
            trainStats = mm.summaryStats(trainData);
            mm.statMean = mean(trainStats, 2, 'omitnan');
            mm.statStd = std(trainStats, [], 2, 'omitnan');
            mm.statPrctiles = prctile(trainStats,0:100,2);
            mm.trainingLogLPrctiles = ...
                prctile(mm.loglikelihood(trainData),0:100,2);
            mm.activeStats = true(size(mm.statMean));
        end
        function M = get.Nmarkers(this)
            %GETNMARKERS Number of markers in the model.
            %
            % Inputs:
            %   this - markerModel object
            %
            % Outputs:
            %   M - number of rows of the training data
            %
            % Toolbox Dependencies: None

            M = size(this.trainingData,1);
        end
        function mu = get.statMedian(this)
            %GETSTATMEDIAN Median of each statistic over training data.
            %
            % Inputs:
            %   this - markerModel object
            %
            % Outputs:
            %   mu - 51st column of the stored 0 to 100th percentiles
            %
            % Toolbox Dependencies: None

            mu = this.statPrctiles(:,51);
        end

        %To be implemented in subclass:
        %Returns PxN likelihood and gradient
        [logL,g] = loglikelihood(this,data)
        i       = indicatrix(this)
        mapData = reconstruct(this,dataPrior,priorConfidence)
        function [badFlag,outlierClass1,outlierClass2] = ...
            validateMarkerModel(this,verbose)
            %VALIDATEMARKERMODEL Compare model to a reference model.
            %
            %   [badFlag,outlierClass1,outlierClass2] =
            % VALIDATEMARKERMODEL(this) checks, against the reference data
            % of the class (getRefData), that the means and standard
            % deviations of the statistics are inside their bounds and that
            % the inequality constraints on the means hold. The model is bad
            % if any check fails or if, for any marker, the second tightest
            % standard deviation of its constraints is above 15 mm.
            %
            % NOTE: currently errors, because it relies on
            % getSharedMarkerList and dropMarkers, which are unimplemented.
            %
            % Inputs:
            %   this    - markerModel object
            %   verbose - (optional) not used (default: true)
            %
            % Outputs:
            %   badFlag       - true if the model fails any check
            %   outlierClass1 - statistics that violate the inequality
            %                   constraints
            %   outlierClass2 - statistics whose mean is outside its bounds
            %
            % Toolbox Dependencies: None

            if nargin < 2 || isempty(verbose)
                verbose = true;
            end
            %Get stds as matrix indexed by markers
            SS = this.stat2Matrix(this.statStd);
            %First: get reference data
            [refModel,meanLB,meanUB,stdLB,stdUB,A,b] = getRefData();
            %Second: drop non-shared markers from both reference and
            %current model (that is the only thing that can be compared)
            sharedMarkerList = this.getSharedMarkerList(refModel);
            [this,keptIdx] = this.dropMarkers(sharedMarkerList,true);
            [refModel,keptIdxRef,keptStats] = ...
                refModel.dropMarkers(sharedMarkerList,true);
            %Third: check mean upper and lower bounds are satisfied
            outlierClass2 = this.statMean > meanUB(keptStats) | ...
                this.statMean < meanLB(keptStats);
            %Fourth: check std upper and lower bounds are satisfied
            outlierClassS = this.statStd > stdUB(keptStats) | ...
                this.statStd < stdLB(keptStats);
            %Fifth: check inequality constraints
            outlierClass1 = A(:,keptStats)*this.statMean > b;
            maxSecondStd = 15; % mm: limit on the second tightest std
            %Sixth: check, for the full given model, that each marker has
            %some (2 or more) tight constraints, otherwise that marker is
            %not being modeled properly
            badFlag   = any(outlierClass1 | outlierClass2 | outlierClassS);
            sortedSTD = sort(SS); %Ascending order, along columns
            %Marking as bad if second tightest std of constraints of any
            %marker are above 15mm
            badFlag   = badFlag | any(sortedSTD(2,:) > maxSecondStd);
        end
        function newThis = fixLabels(this)
            %FIXLABELS Permute labels to pass validation (stub).
            %
            %   This function is meant to permute the labels so the model
            % passes, or at least does better at, validateMarkerModel. It is
            % not implemented and newThis is never assigned.
            %
            % Inputs:
            %   this - markerModel object
            %
            % Outputs:
            %   newThis - model with fixed labels (never assigned)
            %
            % Toolbox Dependencies: None

        end

        %Convenience functions:
        function s = getRobustStd(this,CI)
            %GETROBUSTSTD Std estimated from a central percentile range.
            %
            %   s = GETROBUSTSTD(this,CI) estimates the standard deviation
            % of each statistic from the central confidence interval CI of
            % its training distribution, assuming the central part is
            % normally distributed. For the classical 0.95 value the
            % interval spans 2*1.96 sigma.
            %
            % Inputs:
            %   this - markerModel object
            %   CI   - (optional) central interval in [0.02, 0.98] (default:
            %          0.95); errors otherwise
            %
            % Outputs:
            %   s - standard deviation of each statistic
            %
            % Toolbox Dependencies: None

            if nargin < 2
                CI = 0.95;
            elseif CI > 0.98 || CI < 0.02
                error('CI has to be a number in [0.02,.98]')
            end
            lb = 50-100*CI/2; %Here I am assuming central CI
            ub = 100*CI/2 +50;
            %Get the lb percentile:
            w  = 1-(lb-floor(lb));
            pl = this.statPrctiles(:,floor(lb)+[0,1]+1)*[w;1-w];
            %Get the ub percentile:
            w  = 1-(ub-floor(ub));
            pu = this.statPrctiles(:,floor(ub)+[0,1]+1)*[w;1-w];

            %Get how many sigmas correspond to each of the chosen
            %percentiles in a normal distribution:
            %For the classical 0.95 value, this is 2*1.96 sigma, asumming
            %central CI again
            Nsigma = 2*erfinv(CI)*sqrt(2);
            s      = (pu-pl)/Nsigma;
        end
        function fh = seeModel(this)
            %SEEMODEL Plot the model.
            %
            %   fh = SEEMODEL(this) opens a figure with the cdf of the
            % training statistics, the median marker positions in 3-D and
            % the standard deviation and median of the statistics as
            % matrices.
            %
            % Inputs:
            %   this - markerModel object
            %
            % Outputs:
            %   fh - figure handle
            %
            % Toolbox Dependencies: None

            data = this.trainingData;
            fh   = figure;
            c    = colormap;
            c(1,:) = [1 1 1];
            colormap(c)
            subplot(3,2,1)
            plot(this.statPrctiles',0:100)
            title('Training stat cdfs')
            subplot(3,2,[2,4,6])
            idx = all(all(~isnan(this.trainingData)));
            d   = this.trainingData(:,:,idx);
            %This needs to be rotated accordingly on a frame-by-frame basis
            %for the plot to work well
            m   = median(d,3);
            plot3(m(:,1),m(:,2),m(:,3),'o','LineWidth',2,'MarkerSize',4)
            view(3)
            axis equal
            hold on
            text(m(:,1),m(:,2),m(:,3),this.markerLabels)


            subplot(3,4,5)
            s = this.stat2Matrix(this.statStd);
            [s,xl,yl] = this.stat2Matrix(this.getRobustStd(0.95));
            if strcmp(xl,'markerLabels')
                xl = this.markerLabels;
            end
            if strcmp(yl,'markerLabels')
                yl = this.markerLabels;
            end
            s(s == 0) = -5;
            imagesc(s)
            colorbar
            caxis([-5 100])
            title('\sigma training (mm)')
            axis equal
            axis tight
            set(gca,'XTickLabels',xl,'XTickLabelRotation',90,'XTick', ...
                1:size(data,1),'YTickLabels',yl,'YTick',1:size(data,1))
            subplot(3,4,6)
            m = this.stat2Matrix(this.statMedian);
            m(m == 0) = NaN;
            imagesc(m)
            colorbar
            caxis([min(m(:), [], 'omitnan')-100 max(m(:), [], 'omitnan')])
            title('\mu training (mm)')
            axis equal
            axis tight
            set(gca,'XTickLabels',xl,'XTickLabelRotation',90,'XTick', ...
                1:size(data,1),'YTickLabels',yl,'YTick',1:size(data,1))

            % %Reference data
            % [m,s,l]=naiveDistances.getRefData();
            % subplot(3,4,9)
            % s=triu(s);
            % s(s==0)=-5;
            % m=triu(m);
            % m(m==0)=-25;
            % imagesc(s)
            % colorbar
            % %colormap(c)
            % caxis([-5 100])
            % title('\sigma reference (mm)')
            % axis equal
            % axis tight
            % set(gca,'XTickLabels',l,'XTickLabelRotation',90,'XTick', ...
            %    1:size(s,1),'YTickLabels',l,'YTick',1:size(s,1))
            % subplot(3,4,10)
            % imagesc(m)
            % caxis([-25 1000])
            % colorbar
            % title('\mu reference (mm)')
            % axis equal
            % axis tight
            % set(gca,'XTickLabels',l,'XTickLabelRotation',90,'XTick', ...
            %    1:size(s,1),'YTickLabels',l,'YTick',1:size(s,1))
        end
        function [newThis,keptIdx,keptStats] = ...
            dropMarkers(this,markerList,keepMarkersFlag)
            %DROPMARKERS Drop markers from the model (stub).
            %
            %   [newThis,keptIdx,keptStats] =
            % DROPMARKERS(this,markerList,keepMarkersFlag) is meant to drop
            % the markers in markerList, or to keep only them (in the order
            % of the list) if keepMarkersFlag is set. keptIdx is such that
            % this.markerLabels(keptIdx) = newThis.markerLabels and
            % keptStats is such that this.statMean(keptStats) =
            % newThis.statMean. It is not implemented and errors.
            %
            % Inputs:
            %   this            - markerModel object
            %   markerList      - markers to drop (or keep)
            %   keepMarkersFlag - (optional) keep only the listed markers
            %                     (default: false)
            %
            % Outputs:
            %   newThis   - model without the dropped markers
            %   keptIdx   - indices of the kept markers
            %   keptStats - indices of the kept statistics
            %
            % Toolbox Dependencies: None

            if nargin < 3 || isempty(keepMarkersFlag)
                keepMarkersFlag = false;
            end
            error('Unimplemented')
        end
        function [outlierMarkers,markerScores,logL] = ...
            outlierDetect(this,data,threshold,fastFlag)
            %OUTLIERDETECT Detect outlier markers.
            %
            %   [outlierMarkers,markerScores,logL] =
            % OUTLIERDETECT(this,data) scores the markers with scoreMarkers
            % and flags those with a score below -threshold^2/2.
            %
            % Inputs:
            %   this      - markerModel object
            %   data      - markers x 3 x frames positions
            %   threshold - (optional) number of standard deviations
            %               (default: -5)
            %   fastFlag  - (optional) use only the fast scoring (default:
            %               false)
            %
            % Outputs:
            %   outlierMarkers - markers x frames logical, true for outliers
            %   markerScores   - markers x frames scores
            %   logL           - empty (not computed)
            %
            % Toolbox Dependencies: Optimization Toolbox (through
            %   scoreMarkers)

            if nargin < 3 || isempty(threshold)
                threshold = -5;
            end
            if nargin < 4 || isempty(fastFlag)
                fastFlag = false;
            end
            markerScores = [];
            logL         = [];
            %One option: find outlier stats and disentangle those
            %logL=this.loglikelihood(data);
            %outStats=logL<(-threshold^2/2);
            %[outlierMarkers]=markerModel.untangleOutliers(outStats, ...
            %    this.indicatrix);
            %Another: disentangle likelihoods themselves & then detect
            markerScores   = scoreMarkers(this,data,fastFlag);
            outlierMarkers = markerScores < (-threshold^2/2);
        end
        function markerScores = scoreMarkers(this,data,fastFlag)
            %SCOREMARKERS Score each marker in each frame.
            %
            %   markerScores = SCOREMARKERS(this,data) scores the markers
            % with the second-worst log-likelihood of their statistics. This
            % works well if only one outlier marker is present, or two or
            % more non-adjacent markers (no strong distance constraints
            % between them), and is problematic otherwise. Unless fastFlag
            % is set, frames with more than one outlier marker are re-scored
            % with untangleLikelihoods.
            %
            % Inputs:
            %   this     - markerModel object
            %   data     - markers x 3 x frames positions
            %   fastFlag - (optional) skip the improved scoring (default:
            %              false)
            %
            % Outputs:
            %   markerScores - markers x frames scores
            %
            % Toolbox Dependencies: Optimization Toolbox (through
            %   untangleLikelihoods)

            if nargin < 3 || isempty(fastFlag)
                fastFlag = false;
            end
            markerScores = this.scoreMarkersRanked(data,2); %Fast scoring
            %This fast scoring works well if only one outlier marker is
            %present, or if two or more non-adjacent (ie. no strong distance
            %constraints) markers are present. Otherwise problematic.
            if ~fastFlag %Improve scoring for complex situations
                i = indicatrix(this); %MxP
                markerScores = this.scoreMarkersFast(data);
                outMarkers = this.outlierDetectFast(data);
                %More than one bad marker per frame
                badFrames = sum(outMarkers) > 1;
                L = this.loglikelihood(data(:,:,badFrames));
                %This may only be useful on not too long trials (otherwise
                %every marker will possibly be a part of at least one bad
                %frame, and all markers will get selected)
                badMarkers = any(outMarkers(:,badFrames),2);
                badMarkers = true(size(badMarkers));
                in = i(badMarkers,:); %Indicatrix of bad markers only
                activeConstraints = any(in,1);
                markerScores(badMarkers,badFrames) = ...
                    markerModel.untangleLikelihoods(L(activeConstraints, ...
                    :),in(:,activeConstraints));
            else

            end
        end
        function [labels1,labels2] = labelData(this,dataFrames)
            %LABELDATA Assign labels to unlabeled marker data (stub).
            %
            %   [labels1,labels2] = LABELDATA(this,dataFrames) errors
            % immediately ('This function doesnt work yet'); the body below
            % the error call sketches two heuristics: assigning the most
            % likely pair one at a time, and random labels followed by
            % pairwise permutations.
            %
            % Inputs:
            %   this       - markerModel object
            %   dataFrames - markers x 3 x 1 positions (one frame)
            %
            % Outputs:
            %   labels1 - labels from the first heuristic
            %   labels2 - labels from the second heuristic
            %
            % Toolbox Dependencies: None

            error('This function doesnt work yet.')
            M2 = size(dataFrames,1); %Markers in data frame
            M1 = this.Nmarkers; %Markers in model (need not be equal)
            if M1 ~= M2
                error(['Option to have different number of markers is ' ...
                    'not yet implemented.'])
            end
            Nframes = size(dataFrames,3);
            if Nframes ~= 1
                error('Multiple frames not-yet supported')
            end
            %Heuristic 2: (to initialize labeling)
            i1 = this.indicatrix;
            i2 = this.indicatrix(true,M2);
            i2 = i2(:,this.activeStats);
            %TODO: what is the smart way to handle this?
            dataFrames(isnan(dataFrames)) = 0;
            S     = this.summaryStats(dataFrames);
            S     = S(this.activeStats,:);
            mu    = this.statMedian(this.activeStats);
            sigma = this.getRobustStd(0.94);
            sigma = sigma(this.activeStats);
            for fr = 1:Nframes
                %Heuristic: get most likely pair, one at a time:
                counter = 0;
                labels1 = cell(M2,1);
                map     = nan(M2,1);
                %This assumes normal distributions
                L       = markerModel.normalLogL(S(:,fr),mu',sigma');
                mL      = min(L(:));
                L((isnan(L))) = mL;
                P = i1*(1./sqrt(-L))/i2;
                P = L;
                while counter < M2
                    counter = counter+1;
                    [ii,jj] = find(P == max(P(:)),1,'first')
                    map(jj) = ii;
                    %i1(ii,:)=0;
                    %L(:,i2(jj,:)==1)=-1e6;
                    P(ii,:) = -Inf;
                    P(:,jj) = -Inf;
                end
                labels1 = this.markerLabels(map);

                %TODO:  I want to get the most likely map of M2 onto
                %M1, this is a permutation of M2, (idx: M1x1) such that
                %sum(diag(P(:,idx))) is maximized.
                %TODO: Need to think about what happens if M2< M1 (if
                %larger,
                %we just dont assign some)
            end
            %Heuristic 1: assign random labels, then try pair-wise
            %permutations and see if they improve likelihood of data.
            %Keep permutations that do, and reset pairwise list to try
            %End when all pairwise permutations have been tried and none
            %improves reconstruction
            %Perhaps repeat a couple times and select best of final results
            randInit = randperm(M1);
            for fr = 1:Nframes
                [newFrame,permList] = ...
                    this.tryPermutations(dataFrames(randInit,:,fr));
            end
            labels2 = this.markerLabels(randInit);
            labels2 = markerModel.applyPermutationList(labels2,permList);

        end
        function sortedData = sortMarkerOrder(model,data,labels)
            %SORTMARKERORDER Sort data rows to model labels (stub).
            %
            %   sortedData = SORTMARKERORDER(model,data,labels) is meant to
            % re-sort the rows of data so they match the order of the labels
            % in the model. It is not implemented and errors.
            %
            % Inputs:
            %   model  - markerModel object
            %   data   - markers x ... data
            %   labels - labels of the rows of data
            %
            % Outputs:
            %   sortedData - data re-sorted to the model order
            %
            % Toolbox Dependencies: None

            error('Unimplemented')
            %To do: compare lists of labels and model.markerLabels, find
            %sorting, and sort the data. Use compareLists()
        end
        function sharedMarkerList = getSharedMarkerList(model1,model2)
            %GETSHAREDMARKERLIST Markers shared by two models (stub).
            %
            %   sharedMarkerList = GETSHAREDMARKERLIST(model1,model2) is not
            % implemented and errors.
            %
            % Inputs:
            %   model1 - markerModel object
            %   model2 - markerModel object
            %
            % Outputs:
            %   sharedMarkerList - labels present in both models
            %
            % Toolbox Dependencies: None

            error('Unimplemented')
        end
    end
    methods(Hidden)
        function markerScores = scoreMarkersRanked(this,data,N)
            %SCOREMARKERSRANKED Score markers by the N-th worst statistic.
            %
            %   markerScores = SCOREMARKERSRANKED(this,data,N) scores each
            % marker with the N-th lowest log-likelihood among the
            % statistics that involve it (the minimum if N is 1).
            %
            % Inputs:
            %   this - markerModel object
            %   data - markers x 3 x frames positions
            %   N    - (optional) rank of the score to use (default: 2)
            %
            % Outputs:
            %   markerScores - markers x frames scores
            %
            % Toolbox Dependencies: None

            if nargin < 3
                N = 2; %Using second-worse score
            end
            L = loglikelihood(this,data); %PxN
            [P,Nn] = size(L);
            i = indicatrix(this); %MxP
            if N > 1
                markerScores = nan(size(i,1),size(L,2));
                for mrkr = 1:size(i,1) %Each marker
                    aux = sort(L(i(mrkr,:) == 1,:),1);
                    NN  = min(N,size(aux,1));
                    markerScores(mrkr,:) = aux(NN,:);
                end
            else
                markerScores = squeeze(min(i.*reshape(L,1,P,Nn),[],2));
            end
        end
        function [dataFrame,permutationList] = ...
            tryPermutations(model,dataFrame,listToPermute)
            %TRYPERMUTATIONS Permute labels in one frame to improve fit.
            %
            %   [dataFrame,permutationList] =
            % TRYPERMUTATIONS(model,dataFrame) tries pairwise permutations
            % of the markers associated with bad statistics (log-likelihood
            % below -5^2/2) and then of all markers, keeping each
            % permutation that increases the total log-likelihood, until no
            % statistic is bad or no permutation helps.
            %
            % Inputs:
            %   model         - markerModel object
            %   dataFrame     - markers x 3 positions of a single frame
            %   listToPermute - (optional) markers to permute (default: bad
            %                   markers, then all)
            %
            % Outputs:
            %   dataFrame       - frame with the accepted permutations
            %                     applied
            %   permutationList - accepted pairwise permutations, one pair
            %                     per row
            %
            % Toolbox Dependencies: None

            permutationList = zeros(0,2);
            %Benchmark to compare:
            L0   = model.loglikelihood(dataFrame);
            bad  = L0 < -5^2/2; % TODO: source? (5 std)
            nBad = sum(model.indicatrix* bad > 0);
            %TODO: start with markers associated to bad distances, and then
            %move to a larger set
            if nargin < 3 || isempty(listToPermute)
                %Run for bad markers.
                if nBad > 0
                    listToPermute = find(model.indicatrix* bad > 0);
                    [dataFrame,permutationList] = ...
                        tryPermutations(model,dataFrame,listToPermute);
                end
                %Run for all markers.
                [dataFrame,permutationList2] = ...
                    tryPermutations(model,dataFrame,1:size(dataFrame,1));
                permutationList = [permutationList;permutationList2];
            else
                %If no log-L is too bad, do nothing, save time.
                while nBad > 0
                    %Permutations to consider:
                    %Pairwise permutations
                    listOfPermutations = nchoosek(listToPermute,2);
                    N = size(listOfPermutations,1);
                    count = 0;
                    while count < N
                        count = count+1;
                        newDataFrame = dataFrame;
                        newDataFrame = ...
                            markerModel.applyPermutationList(dataFrame, ...
                            listOfPermutations(count,:));
                        L = model.loglikelihood(newDataFrame);
                        %Found permutation that improves things
                        if sum(L) > sum(L0)
                            break %Exiting inner while-loop
                        end
                    end
                    %Checking if while exited without making any
                    %improvements
                    if sum(L) <= sum(L0)
                        return %Inner loop finished without progress
                    else %Improvement was made!
                        %Update benchmark:
                        dataFrame = newDataFrame;
                        L0        = L;
                        nBad      = sum(L0 < -5^2/2);
                        %Adding permutation to list
                        permutationList(end+1,:) = ...
                            listOfPermutations(count,:);
                    end
                end
            end
        end
    end
    methods(Static)
        %To be implemented in subclass:
        model = learn(data,labels)
        %Returns PxN summary stats, and P x 3M x N gradient
        [ss,g] = summaryStats(data)
        %gradient can be P x 3M if it is the same for all frames, as is the
        %case in linear models
        [M,xl,yl] = stat2Matrix(stats)
        %Returns an example, well-calibrated model
        [model,meanLB,meanUB,stdLB,stdUB,A,b] = getRefData();

        %Convenience functions:
        function lL = normalLogL(values,means,stds)
            %NORMALLOGL Log-likelihood under normal distributions.
            %
            %   lL = NORMALLOGL(values,means,stds) returns
            % -0.5*((values-means)./stds).^2, the log-density up to additive
            % terms that do not depend on the value.
            %
            % Inputs:
            %   values - P x N values
            %   means  - P x 1 means
            %   stds   - P x 1 standard deviations
            %
            % Outputs:
            %   lL - P x N log-likelihoods
            %
            % Toolbox Dependencies: None

            d  = 0.5*((values-means)./stds).^2;
            lL = -d;% -log(stds) -.9189;
            %lL=-sqrt(2*d); %Mahalanobis distance
            %.9189 = log(2*pi)/2
        end
        function frameScores = marker2frameScoresNaive(markerScores)
            %MARKER2FRAMESCORESNAIVE Mean marker score per frame.
            %
            % Inputs:
            %   markerScores - markers x frames scores
            %
            % Outputs:
            %   frameScores - 1 x frames mean score
            %
            % Toolbox Dependencies: None

            frameScores = mean(markerScores, 1, 'omitnan');
        end
        function [newDataFrame,params] = ...
            anchor(dataFrame,anchorFrame,anchorWeights)
            %ANCHOR Rotate and translate a frame to match an anchor frame.
            %
            %   [newDataFrame,params] =
            % ANCHOR(dataFrame,anchorFrame,anchorWeights) finds the 3-D
            % rotation and translation of dataFrame that best match
            % anchorFrame, using getTranslationAndRotation (not in the
            % repository).
            %
            % TODO: use the weights to do a weighted optimization
            % (anchorWeights is currently not used).
            %
            % Inputs:
            %   dataFrame     - markers x 3 positions to move
            %   anchorFrame   - markers x 3 reference positions
            %   anchorWeights - weights of the anchor markers (not used)
            %
            % Outputs:
            %   newDataFrame - moved positions
            %   params       - struct with the rotation R and translation t
            %
            % Toolbox Dependencies: None

            [R,t,newDataFrame] = getTranslationAndRotation(dataFrame, ...
                anchorFrame);
            params.R = R;
            params.t = t;
        end
        function markerScores = untangleLikelihoods(L,indicatrix)
            %UNTANGLELIKELIHOODS Assign statistic likelihoods to markers.
            %
            %   markerScores = UNTANGLELIKELIHOODS(L,indicatrix) finds, for
            % each frame, marker deviations x >= 0 (in standard deviations)
            % that explain the statistic likelihoods: a linear program
            % minimizes sum(x) subject to indicatrix'*x >= sqrt(-2*L); among
            % solutions with the same active constraints, fmincon then picks
            % the one with the largest sum(x.^2), that is, the most unequal
            % one. The score is -0.5*x.^2. The tolerances are relaxed for
            % speed. Prints the number of frames and the elapsed time.
            %
            % Inputs:
            %   L          - statistics x frames log-likelihoods
            %   indicatrix - markers x statistics matrix, 1 where the
            %                statistic involves the marker
            %
            % Outputs:
            %   markerScores - markers x frames scores
            %
            % Toolbox Dependencies: Optimization Toolbox (fmincon, linprog,
            %   optimoptions)

            A = -indicatrix';
            %Relax tolerances for fast compute
            relaxedTol = 1e-1;
            options = optimoptions('fmincon','Display','off', ...
                'SpecifyObjectiveGradient',false,'OptimalityTolerance', ...
                relaxedTol,'StepTolerance',relaxedTol, ...
                'ConstraintTolerance',relaxedTol);
            options2 = optimoptions('linprog','Display','off');
            N = size(indicatrix,1);
            LB = zeros(N,1);
            f = ones(N,1);
            M = size(L,2); %number of frames
            markerScores = nan(N,M);
            display(['Running for ' num2str(M) ' frames. Expect ' ...
                num2str(M/75,2) ' sec. processing time (75 fps).'])
            tic
            for fr = 1:M
                %transform likelihood to std away from expectation
                b = -sqrt(-2*L(:,fr));
                %Get linear programming solution:
                %Being used to identify active inequalities only
                [x0,~,~,~,lam] = linprog(f,A,b,[],[],LB,[],options2);
                %f'*x0
                %Sparsify solution: (for each active constraint, selecting
                %the most
                %unequal solution possible, notice this maintains the cost
                %f'*x constant)
                activeConstraints = (lam.ineqlin == 1);
                A1 = -A(activeConstraints,:); %Active inequalities
                %For each marker there is at least 1 active inequality, or
                %one of the bounds was reached
                idx = any(A1 ~= 0);
                A2 = A1(:,idx);
                %Notice this adds as constraint that active inequalities
                %from linprog are maintained
                aux = fmincon(@(x) [-sum(x.^2)],x0(idx), ...
                    A(~activeConstraints,idx),b(~activeConstraints),A2, ...
                    A2*x0(idx),LB(idx),[],[],options);
                x0(idx) = aux;
                markerScores(:,fr) = -0.5*x0.^2;
                %f'*x0 %Check that this was maintained
            end
            toc
        end
        %Single frame: L is vector
        function outMarkers = untangleOutliers(outStats,in)
            %UNTANGLEOUTLIERS Smallest marker set explaining outliers.
            %
            %   outMarkers = UNTANGLEOUTLIERS(outStats,in) solves, for each
            % frame, min 1'*y s.t. outStats <= in'*y and y >= (in*outStats -
            % 1'*y)/K with intlinprog, where K is the largest number of
            % statistics per marker. This finds the minimum outlier set such
            % that each outlier statistic has at least one outlier marker
            % causing it, and any marker with more outlier statistics than
            % there are outlier markers is itself an outlier. The program is
            % only solved for a frame when the initial set (markers with
            % more than one outlier statistic) violates these constraints or
            % has more than one marker.
            %
            % Inputs:
            %   outStats - statistics x frames logical, true for outlier
            %              statistics
            %   in       - markers x statistics indicatrix
            %
            % Outputs:
            %   outMarkers - markers x frames logical, true for outlier
            %                markers
            %
            % Toolbox Dependencies: Optimization Toolbox (intlinprog,
            %   optimoptions)

            [M,P] = size(in);
            uno        = ones(M,1);
            cero       = zeros(M,1);
            f          = [uno]; %Vector to solve y
            lb         = [cero];
            ub         = [uno];
            opts       = optimoptions('intlinprog','Display','off');
            %This marks markers only if they have more than one outlier stat
            outMarkers = (in*outStats) > 1;
            for fr = 1:size(outStats,2)
                b1 = outStats(:,fr);
                b2 = in*outStats(:,fr);
                c  = outMarkers(:,fr);
                %Only run if the inequalities are not already satisified or
                %if two markers were outliers in the same frame
                if any(b1 > in'*c) || any(c < (b2-sum(c))) || sum(c) > 1
                    %Ineq 1: L<=i'*y -> -L>= -i'*y
                    A1 = -in';
                    b1 = -b1;
                    %Ineq 2: y>=(i*L -1'*y)/K -> -y-(1'*y)/K<=-i*L/K
                    K  = max(sum(in,2));
                    A2 = [-eye(M)-ones(M)/K];
                    b2 = -b2/K;
                    outMarkers(:,fr) = ...
                        intlinprog(f,[1:M],[A1;A2],[b1;b2],[],[],lb,ub, ...
                        opts);
                end
            end
        end
    end
    methods(Static,Hidden)
        function data = applyPermutationList(data,permutationList)
            %APPLYPERMUTATIONLIST Apply pairwise row permutations in order.
            %
            %   data = APPLYPERMUTATIONLIST(data,permutationList) swaps, for
            % each row of permutationList, the two listed rows of data
            % (along dimension 1). A row vector is converted to a column
            % first.
            %
            % Inputs:
            %   data            - array permuted along dimension 1
            %   permutationList - n x 2 pairs of row indices to swap
            %
            % Outputs:
            %   data - permuted array
            %
            % Toolbox Dependencies: None

            if size(data,1) == 1 %Row vector
                data = data(:);
            end
            %Applies a list of pair-wise permutations along dim 1
            for ii = 1:size(permutationList,1)
                data(permutationList(ii,:),:) = ...
                    data(fliplr(permutationList(ii,:)),:);
            end
        end
    end
end

