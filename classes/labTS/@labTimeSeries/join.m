function this = join(labTSCellArray)
%join  Joins cell array of labTimeSeries
%
%   this = join(labTSCellArray) concatenates multiple labTimeSeries
%   along time axis
%
%   Inputs:
%       labTSCellArray - cell array of labTimeSeries objects with
%                        consistent labels and sampling periods
%
%   Outputs:
%       this - joined labTimeSeries
%
%   See also: cat, concatenate

masterSampPeriod = labTSCellArray{1}.sampPeriod;
masterLabels = labTSCellArray{1}.labels;
newData = labTSCellArray{1}.Data;
for i = 2:length(labTSCellArray(:))
    % Check sampling rate & dimensions are consistent, and append at
    % end of data
    if all(cellfun(@strcmp, masterLabels, labTSCellArray{i}.labels)) && ...
            masterSampPeriod == labTSCellArray{i}.sampPeriod
        newData = [newData; labTSCellArray{i}.Data];
    else
        warning(['Element ' num2str(i) ' of input cell array does not ' ...
            'have labels or sampling period consistent with ' ...
            'other elements.']);
    end
    this = labTimeSeries(newData, labTSCellArray{1}.Time(1), ...
        masterSampPeriod, masterLabels);
end
end

