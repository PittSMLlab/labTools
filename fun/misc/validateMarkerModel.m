function [badFlag] = validateMarkerModel(distanceModel,verbose)

if nargin<2 || isempty(verbose)
    verbose=true;
end
badFlag=false;
%Check three things: 
%1) No marker is closer to a contralateral marker
%than its ipsilateral counterpart
mu=naiveDistances.stat2Matrix(distanceModel.statMedian);
M=size(mu,1);
firstHalf=1:M/2;
secondHalf=M/2+1:M;
mu1=triu(mu(firstHalf,firstHalf));
mu2=triu(fliplr(mu(firstHalf,secondHalf)));
mu3=triu(mu(secondHalf,secondHalf));
mu4=triu(flipud(mu(firstHalf,secondHalf)));
D=[mu2<mu1,zeros(size(mu1));zeros(size(mu1)),mu4<mu3] & mu<700; %Using 700mm as a threshold for distances to look at
%otherwise we compare something like RPSIS to RTOE and LTOE, which by geometry are almost equally far from RPSIS, and any movement or placement asymmetry will raise an alarm. 
%Excluding SHANK and THIGH from this, since markers are not meant to be placed symmetrically
[bool,idxs] = compareListsNested(distanceModel.markerLabels,{'RTHI','LTHI','LTHIGH','RTHIGH','RSHANK','LSHANK','LSHA','RSHA','LSHNK','RSHNK'});
D(idxs(bool),:)=false;
D(:,idxs(bool))=false;
[outMarkers1]=markerModel.untangleOutliers( naiveDistances.distMatrix2stat(D),distanceModel.indicatrix(true));
if any(outMarkers1)
    if verbose
    fprintf(['Mislabeled markers. Contralat. distances > ipsilat. for: '])
    fprintf([cell2mat(strcat(distanceModel.markerLabels(outMarkers1),', ')) '\n'])
    end
    badFlag=true;
end
%2) The two (three?) closest markers (ipsilaterally along z-axis: as sorted before) to any given marker have std<10
sigma=naiveDistances.stat2Matrix(distanceModel.getRobustStd(.94));
if any(any(triu(sigma)-triu(sigma,3)))>10
    if verbose
    fprintf(['Too much variability for adjacent markers.\n'])
    end
    badFlag=true;
end

%3) No marker pair has a distance outside the admissible bounds
load distanceModelReferenceData.mat
[bool,idxs] = compareListsNested(distanceModel.markerLabels,markerLabels);
list1=distanceModel.markerLabels(idxs(bool));
list2=markerLabels(bool);
if ~all(strcmp(list1,list2))
    error('Incompatible lists')
end   
upperBound=upperBound(bool,bool);
lowerBound=lowerBound(bool,bool);
reducedMu=mu(idxs(bool),idxs(bool));
if any(any(reducedMu<lowerBound | reducedMu>upperBound))
    D= zeros(size(mu));
    D(idxs(bool),idxs(bool))= reducedMu<lowerBound | reducedMu>upperBound;
    in=distanceModel.indicatrix(true);
    [outMarkers1]=markerModel.untangleOutliers(naiveDistances.distMatrix2stat(D),in);
    if verbose
    fprintf(['Marker distances above or below the allowed limits for markers: '])
    fprintf([cell2mat(strcat(distanceModel.markerLabels(outMarkers1),', ')) '\n'])
    end
%                             [ii,jj]=find(reducedMu<lowerBound | reducedMu>upperBound);
%                             for i1=1:length(ii)
%                                disp(['Mean distance from ' distanceModel.markerLabels{ii(i1)} ' to ' distanceModel.markerLabels{jj(i1)} ' (' num2str(reducedMu(ii(i1),jj(i1)),3) 'mm) exceeds limits [' num2str(lowerBound(ii(i1),jj(i1)),3) ', ' num2str(upperBound(ii(i1),jj(i1)),3) 'mm].']) 
%                             end
    badFlag=true;
 end
                        
end

