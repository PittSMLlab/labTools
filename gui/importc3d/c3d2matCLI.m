function [expData,rawExpData,adaptData]=c3d2matCLI(infoFile,eventClass)
%This function does the same as c3d2mat but without a GUI
%Information normally acquired through the GUI is loaded from a file
%Creating this file DOES require using the GUI: call c32dmat or GetInfoGUI

if nargin<2
    eventClass=''; %Default
end

handles=loadInfoFile(infoFile,'');
out = errorProofInfo(handles,ignoreErrors);
[expData,rawExpData,adaptData]=loadSubject(info,eventClass);


end