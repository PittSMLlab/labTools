function [LHS, RHS, LTO, RTO] = getEventsFromForces(FzL, FzR, fsample)
%GETEVENTSFROMFORCES Detect gait events from vertical ground reaction forces.
%
%   Determines heel-strike (HS) and toe-off (TO) events for left and right
% legs by thresholding vertical GRF signals. Delegates stance detection to
% GETSTANCEFROMFORCES and event extraction to GETEVENTSFROMSTANCE.
%
% Inputs:
%   FzL     - N×1 double, left vertical GRF signal (N, positive upward)
%   FzR     - N×1 double, right vertical GRF signal (N, positive upward)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   LHS - N×1 logical, left heel-strike events
%   RHS - N×1 logical, right heel-strike events
%   LTO - N×1 logical, left toe-off events
%   RTO - N×1 logical, right toe-off events
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMFORCES, GETEVENTSFROMSTANCE.

%% Get stance phases
forceThresh = 10; % detection threshold (N)

% % Temporary filter the force data (4th order butterworth Low pass filter
% % with cutoff frequency of 10)
% Wn=2*10/fsample;
% filterList=fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,Wn+.2*(1-Wn),1.5,20); %Ast=10dB (/octave) results in a 4th order Butterworth filter (-80dB/dec fall).
% lowPassFilter=design(filterList,'butter'); %Changed on Oct 21, 2014 to have less ripple in impulse response. This is a 4th order filter.
% FzL=filtfilthd(lowPassFilter,FzL);  %Ext function
% FzR=filtfilthd(lowPassFilter,FzR);  %Ext function

[stanceL] = getStanceFromForces(FzL, forceThresh, fsample);
[stanceR] = getStanceFromForces(FzR, forceThresh, fsample);
%[stanceL] = getStanceFromForcesAlt(FzL, [], fsample); %New method
%[stanceR] = getStanceFromForcesAlt(FzR, [], fsample); %New method

%% Get events from stance
[LHS, RHS, LTO, RTO] = getEventsFromStance(stanceL, stanceR);

%% Eliminate any events that occur prior to actual activity in the trial
% This section was commented out by Pablo on 2/20/2015 because it led to
% the very first step not being properly detected, which can be a big
% problem.

% Rheel=FzR;
% Lheel=FzL;
% aux=Rheel(:,1)-Rheel(1,1); %Zero initial value
% aux2=cumsum(aux.^2); %Cumulative energy
% begin_index1=find(aux2>.001*aux2(end),1); %First element whose cumulative energy is at least .1% of total energy
% aux=Lheel(:,1)-Lheel(1,1); %Zero initial value
% aux2=cumsum(aux.^2); %Cumulative energy
% begin_index2=find(aux2>.001*aux2(end),1); %First element whose cumulative energy is at least .1% of total energy
%
% begin_index=max([begin_index1,begin_index2]);
%
% LHS(1:begin_index)=false;
% RHS(1:begin_index)=false;
% LTO(1:begin_index)=false;
% RTO(1:begin_index)=false;

%% Check consistency
%[consistent] = checkEventConsistency(LHS,RHS,LTO,RTO);

end
