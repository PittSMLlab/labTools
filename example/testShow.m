%Test script to show uses of Objects
%Test change


%% Generate an object:
time=[1:100];
data=randn(100,10)+repmat([1:100]',1,10);
a=timeseries(data,time,'Name','OriginalTS') %Constructor
%Not using ; after an object (a) implicitly calls the function
%a.display/display(a) 
figure
plot(a) %This is already defined, saves time!


%% Some useful functions already defined for timeseries objects:
%% Detrend
b=a.detrend('constant');
b.Name='ZeroMeanTS';
figure
subplot(1,2,1)
plot(b)
c=a.detrend('linear');
c.Name='ZeroMeanTimeInvariantTS';
subplot(1,2,2)
plot(c)

%We could add a function that not only detrends, but normalizes to the
%[0,1] interval=+

%% Retrieve partial data
d=getsampleusingtime(a,);
figure
plot(d)

%% Interpolate
a=a.setinterpmethod('zoh');
a2 = resample(a,[1:.1:100]); %Notice the 10x fold increase in samples, and zero-order hold interpolation method
figure
plot(a2)2,5

%% Define events and get data between events
a=a.addevent('LTO',1.3);
a=a.addevent('LTO',3.4);
a=a.addevent('LTO',5.2);
a=a.addevent('RTO',2.0);
a=a.addevent('RTO',4.1);
a=a.addevent('RTO',6.7);

e=a.gettsbetweenevents('LTO','RTO',2,3);
e.Name='Between 2nd LTO and 3rd RTO';
figure
plot(e)

%% Other defined functions:
%filter, idealfilter
