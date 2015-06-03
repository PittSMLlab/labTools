function addMarkerPair(correctLabel,altLabel)

fileStr=which('markerLabelKey.mat');
load(fileStr)

for i=1:size(matchedLabels,1)
   if strcmpi(correctLabel,matchedLabels{i,2})
       matchedLabels{i,1}=[matchedLabels{i,1} {altLabel}];       
   end
end

save(fileStr,'matchedLabels')

end