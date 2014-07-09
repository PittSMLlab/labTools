function [stance] = deleteShortPhases(stance,fsample,minDuration)

N=ceil(minDuration*fsample);

%%Dilate stance, and erode
%dilStance=conv(double(stance),ones(N,1),'same')>0;
%eroStance=conv(double(dilStance),ones(N,1),'same')>=N;

%Dilate swing, and erode
%dilSwing=conv(double(~eroStance),ones(N,1),'same')>0;
%eroSwing=conv(double(dilSwing),ones(N,1),'same')>=N;

%stance=~eroSwing;

if ~isempty(stance)
    for i=1:N
        stance=conv(double(stance),ones(2*i+1,1),'same')>i;
    end
end

end

