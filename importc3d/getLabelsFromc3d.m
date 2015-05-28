function getLabelsFromc3d

[file,path]=uigetfile('*.c3d','Choose a .c3d file');

if file~=0
    H=btkReadAcquisition([path file]);
    markers = btkGetMarkers(H);
end
markerLabels=fields(markers);
disp('The marker labels are: ')
disp(markerLabels)

end