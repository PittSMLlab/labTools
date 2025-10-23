function addMarkerPair(correctLabel,altLabel)

fileStr = which('markerLabelKey.mat');
load(fileStr);

for lbl = 1:size(matchedLabels,1)                   % for each label, ...
    if strcmpi(correctLabel,matchedLabels{lbl,2})
        matchedLabels{lbl,1} = [matchedLabels{lbl,1} {altLabel}];
    end
end

save(fileStr,'matchedLabels');

end

