classdef markerModel

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
            M = size(this.trainingData,1);
        end
        function mu = get.statMedian(this)
            mu = this.statPrctiles(:,51);
        end

        %To be implemented in subclass:
        %Returns PxN likelihood and gradient
        [logL,g] = loglikelihood(this,data)
        i       = indicatrix(this)
        mapData = reconstruct(this,dataPrior,priorConfidence)
        function [badFlag,outlierClass1,outlierClass2] = ...
            validateMarkerModel(this,verbose)
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
            %Sixth: check, for the full given model, that each marker has
            %some (2 or more) tight constraints, otherwise that marker is
            %not being modeled properly
            badFlag   = any(outlierClass1 | outlierClass2 | outlierClassS);
            sortedSTD = sort(SS); %Ascending order, along columns
            %Marking as bad if second tightest std of constraints of any
            %marker are above 15mm
            badFlag   = badFlag | any(sortedSTD(2,:) > 15);
        end
        function newThis = fixLabels(this)
            %This function tries to permute labels in a model so the model
            %would pass, or at least do better, at validate()
        end

        %Convenience functions:
        function s = getRobustStd(this,CI)
            %Uses the central confidence interval CI to estimate the std of
            %the distribution
            %assuming the central part is normally distributed
            %CI has to be a number in [0.02,.98]
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
            %Drops the markers in markerList from the model, if present.
            %If keepMarkersFlag is set, then we only keep the markers in
            %markerList and drop the rest. The markers are re-ordered to
            %match the order in the given list.
            %keptIdx is such that
            %this.markerLabels(keptIdx)=newThis.markerLabels
            %And will be equal to markerList if ALL markers in markerList
            %are present
            %keptStats is such that
            %this.statMean(keptStats)=newThis.statMean
            if nargin < 3 || isempty(keepMarkersFlag)
                keepMarkersFlag = false;
            end
            error('Unimplemented')
        end
        function [outlierMarkers,markerScores,logL] = ...
            outlierDetect(this,data,threshold,fastFlag)
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
            % Convenience function that re-sorts the rows of data, so that
            % they match the order of the labels in this model.
            error('Unimplemented')
            %To do: compare lists of labels and model.markerLabels, find
            %sorting, and sort the data. Use compareLists()
        end
        function sharedMarkerList = getSharedMarkerList(model1,model2)
            error('Unimplemented')
        end
    end
    methods(Hidden)
        function markerScores = scoreMarkersRanked(this,data,N)
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
            %Tries to permute labels on single dataFrame to maximize
            %likelihood of data.
            permutationList = zeros(0,2);
            %Benchmark to compare:
            L0   = model.loglikelihood(dataFrame);
            bad  = L0 < -5^2/2;
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
            %values is PxN, means and stds are Px1
            %Returns PxN likelihood of value under each normal
            d  = 0.5*((values-means)./stds).^2;
            lL = -d;% -log(stds) -.9189;
            %lL=-sqrt(2*d); %Mahalanobis distance
            %.9189 = log(2*pi)/2
        end
        function frameScores = marker2frameScoresNaive(markerScores)
            frameScores = mean(markerScores, 1, 'omitnan');
        end
        function [newDataFrame,params] = ...
            anchor(dataFrame,anchorFrame,anchorWeights)
            %Convenience function that finds the 3D rotation/translation of
            %dataFrame to best match the anchorFrame
            %TODO: use weights to do a weighted optimization
            [R,t,newDataFrame] = getTranslationAndRotation(dataFrame, ...
                anchorFrame);
            params.R = R;
            params.t = t;
        end
        function markerScores = untangleLikelihoods(L,indicatrix)
            A = -indicatrix';
            %Relax tolerances for fast compute
            options = optimoptions('fmincon','Display','off', ...
                'SpecifyObjectiveGradient',false,'OptimalityTolerance', ...
                1e-1,'StepTolerance',1e-1,'ConstraintTolerance',1e-1);
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
            %Solve: min 1'*y s.t. L<=i'*y and y>=(i*L -1'*y), where L =
            %outlier stats for marker
            %This means we find the minimum outlier set, such that each
            %outlier stat has at least one causing outlier marker AND any
            %marker that has strictly more outlier stats than there are
            %outlier
            %markers is an outlier itself [I think this is implied by the
            %other but am not sure].
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

