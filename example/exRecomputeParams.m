%% This is an example file on how to recomputeParameters
%Assumes an object of the experimentData class named 'expData' exists in workspace

%% Example 1: recompute all parameters & generate new adaptData object, and save both to disk
expData=expData.recomputeParameters;
save ./expDataWithNewParams.mat expData; %This usually takes time!
adaptData=expData.makeDataObj;
save ./adaptDataWithNewParams.mat adaptData

%% Example 2: recompute spatial & force parameters only
expData=expData.recomputeParameters([],[],{'force','spatial'});

%% Example 3: recompute parameters using kinematic parameters
expData=expData.recomputeParameters('kin');

%% Example 4: recompute parameters using one specific leg as initial step
%Note: by default we use the logic of computing events as fast-slow,
%where the fast leg step happens AFTER the slow leg step
%Let's say that fast=R, and slow=L in this example.
%We could compute the same set of parameters as left-right, considering the left step that comes after a right step
%Note that this is NOT the opposite definition: if we number steps consecutively,
%for example with the left steps being odd, and the right steps being even,
%then the original case defines R(2)-L(1) and R(4)-L(3) as parameters, while the
%alternative defines L(3)-R(2) and L(5)-R(4), which are not the opposite of the previous ones
expData=expData.recomputeParameters([],'L');
