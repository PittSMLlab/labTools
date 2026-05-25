%% V2P_Tester — Parse and Inspect V2P Data File
% purpose: Load a data file (JSON or CSV), extract force and event
%   columns, and report basic timing statistics.

clear
clc
close all

%% Load file
filename = uigetfile('*.*');

f = fopen(filename);
g = fgetl(f);
fclose(f);

if strcmp(g(1), '[')
    [header, data] = JSONtxt2cell(filename);
else
    S      = importdata(filename, ',', 1);
    data   = S.data;
    Header = S.textdata;
end

%% Extract signals
frame = data(:, 1) - data(1, 1);
Rz  = data(:, 2);
Lz  = data(:, 3);
RHS = data(:, 4);
LHS = data(:, 5);

%% Compute timing statistics
bframe    = frame(10:end);
framediff = diff(bframe);
mean(framediff)                 % display mean frame interval (diagnostic)
disp(['% data received: ' ...
    num2str(length(bframe) / (bframe(end) - bframe(1)) * 100)]);
timeelap = (bframe(end) - bframe(1)) / 100;
freq = length(bframe) / timeelap   % display computed frequency (diagnostic)

%% Plot
figure(1)
plot(framediff);
ylim([-4 6])

RHS(isnan(RHS)) = [];
figure(2)
plot(frame, Rz, 1:length(RHS), RHS);
