function [] = AddPythonData()
%function to process a python biofeedback data file and add the columns of
%data onto the end of the subject's adaptData instance
%  No inputs required, inputs are asked for during the execution.
%  No output is returned, however a message is displayed which indicated
%  success or failure

%select python file(s) to process
[filenames,~] = uigetfiles('*.*','Select filenames');

if iscell(filenames)
    
    
else
    
end

end

