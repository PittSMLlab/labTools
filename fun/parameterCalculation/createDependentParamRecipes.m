fieldList={...
'hipContribution',      '@(w,x,y,z) w-x-y-z',           {'netContributionNorm2','spatialContributionNorm2','stepTimeContributionPNorm','velocityContributionPNorm'},            'computes the proposed hip contrib'...
};

%% Add p,e,t (EMG) params from s
muscleList={'TA','PER','MG','LG','SOL','RF','VM','VF','SEMT','SEMB','BF','GLU','TFL','HIP','ADM'};
%Going from 's' to 'p' parameters is equivalent to averaging each 2 's'
%parameters into a single 's' param. In other words, for each muscle, multiplying by the matrix:
%s2pMatrix=nan(12,6);
%s2pMatrix([1:2:12, 2:2:12],:)=.5*[eye(6) eye(6)]';
sides={'R','L'};
desc={'SHS to FTO', 'FTO to mid fast swing', 'mid fast swing to FHS', 'FHS to STO', 'STO to mid slow swing', 'mid slow swing to SHS'};
timeScaleParam={'doubleSupportTemp','doubleSupportTemp','swingTimeFast','swingTimeFast','swingTimeFast','swingTimeFast','doubleSupportSlow','doubleSupportSlow','swingTimeSlow','swingTimeSlow','swingTimeSlow','swingTimeSlow'};
timeScaleK=[2,2,1,1,1,1,2,2,1,1,1,1];
for j=1:2
    ss=sides{j};
    for i=1:length(muscleList)
        for k=1:6 % 'p' params
            fieldList(end+1,:)={[ss muscleList{i} 'p' num2str(k)],'@(x,y) .5*(x+y)',{[ss muscleList{i} 's' num2str(2*k-1)],[ss muscleList{i} 's' num2str(2*k)]},['Average of proc EMG data in muscle ' [ss muscleList{i}] ' from ' desc{k}]};
        end
        for k=1:12 % 't' params
            fieldList(end+1,:)={[ss muscleList{i} 't' num2str(k)],['@(x,y) .25*x.*y*' num2str(timeScaleK(k))],{[ss muscleList{i} 's' num2str(k)],timeScaleParam{k}},['Integrated (instead of averaged) version of ' [ss muscleList{i} 's' num2str(k)]]};
        end
        for k=1:12 % 'e' params
            fieldList(end+1,:)={[ss muscleList{i} 'e' num2str(k)],['@(x,y) x./y'],{[ss muscleList{i} 't' num2str(k)],'strideTimeSlow'},['Time normalize (by stride cycle duration) version of ' [ss muscleList{i} 't' num2str(k)]]};
        end
    end
end

%% write
dn=mfilename('fullpath');
fn=mfilename;
ff=regexp(dn,fn,'split');
save([ff{1} 'DependParamRecipes.mat'], 'fieldList')