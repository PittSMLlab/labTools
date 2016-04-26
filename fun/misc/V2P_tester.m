clear
clc
close all

filename = uigetfile('*.*');

f = fopen(filename);
g = fgetl(f);
fclose(f);

if strcmp(g(1),'[')
    [header,data] = JSONtxt2cell(filename);
else
    S = importdata(filename,',',1);
    data = S.data;
    Header = S.textdata;
end

frame = data(:,1)-data(1,1);
% disp(['% data received: ' num2str(length(frame)/frame(end)*100)]);
Rz = data(:,2);
Lz = data(:,3);
RHS = data(:,4);
LHS = data(:,5);

bframe = frame(10:end);
% bframe = frame;
framediff = diff(bframe);
mean(framediff)
disp(['% data received: ' num2str(length(bframe)/(bframe(end)-bframe(1))*100)]);
timeelap = (bframe(end)-bframe(1))/100;
freq = length(bframe)/timeelap

figure(1)
plot(framediff);
ylim([-4 6])

RHS(isnan(RHS))=[];
figure(2)
plot(frame,Rz,1:length(RHS),RHS);
