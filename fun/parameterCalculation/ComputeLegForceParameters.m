function [SB, SBsum, SP, SPsum, SBmax, SBmax_ABS, SBmaxQS, SPmax, SPmaxQS, ImpactMagS] = ComputeLegForceParameters(striderS,  LevelofInterest, FlipB, titleTXT)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin<4 || isempty(titleTXT)
    titleTXT='';
end

% Identify all the 'braking' (i.e., negative) and 'propeling' (i.e.,
% positive data points for the stride
ns=find((striderS-LevelofInterest)<0);
ps=find((striderS-LevelofInterest)>0);

%From the first 15% of the stride, determin the peak anterior-posterior impact force
[ImpactMagS, ImpactSWhere]=nanmax(striderS(1:round(0.15*length(striderS))));

% if there is an impact force, then we do not want the impact behavior to
% be considered when we are computing braking and propulsion measures.
if isempty(ImpactSWhere)~=1
    % New method 2/25/2020
        ps(find(ps<ImpactSWhere))=[];
        ns(find(ns<ImpactSWhere))=[];
end

%% Mean Behaviors

% Braking Force Characterization
if isempty(ns) %No Braking Data
    SB=NaN;
    SBsum=NaN;
else % As long as there are some braking data points
    SB=FlipB.*(nanmean(striderS(ns)-LevelofInterest));
    SBsum=FlipB.*nansum(striderS(ns)-LevelofInterest);
end

% Propulsion Force Characterization
if isempty(ps)
    SP=NaN;
    SPsum=NaN;
else % As long as there are some propulsion data points
    SP=nanmean(striderS(ps)-LevelofInterest);
    SPsum=nansum(striderS(ps)-LevelofInterest);
end

ns_ALL=ns;
ps_ALL=ps;

%% Peak Behaviors

%Prevent Impulse & Tail end of forces traces from being identified at peaks
ns(find(ns>=0.9*length(striderS)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as the braking force 4/11/2017 CJS
ps(find(ps<=0.1*length(striderS)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.

if isempty(ns)
    SBmax=NaN;
    SBmax_ABS=NaN;
    SBmaxQS=NaN;
else% As long as there are some braking data points    
    [SBmax]=nanmin(striderS(ns));%-LevelofInterest
    SBmax=FlipB.*SBmax;
    SBmaxQS=SBmax-2.*FlipB.*(LevelofInterest);
    SBmax_ABS=FlipB.*(nanmin(striderS-LevelofInterest));
end
 
if isempty(ps)
    SPmax=NaN;
   SPmaxQS=NaN;
else % As long as there are some propulsion data points
    [SPmax]=nanmax(striderS(ps));%-LevelofInterest
    SPmaxQS=SPmax-2.*LevelofInterest;
end

% if ps(MaxWhereS)<=0.1*length(striderS)
%     figure
%     plot(striderS, 'k'); hold on
%     line([0.1*length(striderS) 0.1*length(striderS)], [-.2 .2])
%     line([0.9*length(striderS) 0.9*length(striderS)], [-.2 .2])
%     plot(ps(MaxWhereS), striderS(ps(MaxWhereS)), 'r*')
%     plot(ns(MinWhereS), striderS(ns(MinWhereS)), 'b*')
%     title(titleTXT)
% end

end
