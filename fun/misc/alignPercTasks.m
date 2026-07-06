function paddedData = alignPercTasks(data)
%ALIGNPERCTASKS Align time-course data across participants with
%perceptual tasks.
%
%   Standardizes stride-indexed data across participants by
% independently padding or truncating each segment (walking or
% perceptual task) to a uniform length. For conditions with tasks,
% walking segments are truncated to the minimum length and task
% segments are padded (with NaN) to the maximum length. For
% conditions without tasks, all participants are cropped to the
% minimum stride count.
%
% Inputs:
%   data - struct with PxN fields (P = participants, N = strides).
%          Required fields:
%            percTaskInitStride - binary matrix; 1 = task start
%            percTaskEndStride  - binary matrix; 1 = task end
%            pertSizePercTask   - perturbation size per task
%          Each field has subfields for conditions (e.g., .trial1).
%
    % pertSize=data.pertSizePercTask.(conditions{cond}).trial1;
% Outputs:
%   paddedData - struct with the same fields as DATA, containing
%                aligned matrices of uniform length per condition,
%                with updated task marker positions
%
% Toolbox Dependencies: None
%
% See also FIELDS, FIELDNAMES.
conditions = fields(data.percTaskInitStride);

for con = 1:length(conditions)

    taskInitMatrix = ...
        data.percTaskInitStride.(conditions{con}).trial1;
    taskEndMatrix  = ...
        data.percTaskEndStride.(conditions{con}).trial1;
    [nParticipants, ~] = size(taskInitMatrix);

    % check if this condition has any perceptual tasks
    noPercTasks = true;
    if sum(find(taskInitMatrix == 1)) ~= 0 && ...
            sum(find(taskEndMatrix == 1)) ~= 0
        noPercTasks = false;
    end

    % for conditions without perceptual tasks: find minimum stride count
    if noPercTasks
        fieldsToAlign = fieldnames(data);
        fieldsToAlign = fieldsToAlign(~contains(fieldsToAlign, ...
            {'percTaskInitStride','percTaskEndStride', ...
             'pertSizePercTask'}));

        maxStridesCond = zeros(nParticipants, 1);
        for pp = 1:nParticipants
            currentRow = data.(fieldsToAlign{1}). ...
                (conditions{con}).trial1(pp, :);
            maxStridesCond(pp) = find(~isnan(currentRow), 1, 'Last');
        end
        % minimum last-non-NaN index across all participants
        maxStridesCond = min(maxStridesCond);
    end

    % allpertSize=cell(nParticipants,1);
        % allpertSize{i}=pertSize(i,find(taskInitMatrix(i,:)==1));
    % extract task marker indices for each participant
    allInitIndices = cell(nParticipants, 1);
    allEndIndices  = cell(nParticipants, 1);
    numTasks       = zeros(nParticipants, 1);

    for pp = 1:nParticipants
        allInitIndices{pp} = find(taskInitMatrix(pp, :) == 1);
        allEndIndices{pp}  = find(taskEndMatrix(pp, :) == 1);
        numTasks(pp)       = length(allInitIndices{pp});

        % sanity check: equal number of start and end markers
        if length(allInitIndices{pp}) ~= length(allEndIndices{pp})
            warning(['Participant %d has unequal number of init ' ...
                '(%d) and end (%d) markers. Skipping alignment.'], ...
                pp, length(allInitIndices{pp}), ...
                length(allEndIndices{pp}));
            numTasks(pp) = 0;
        end
    end

    % compute length of each walk/task segment per participant
    numStrideSegments = zeros(nParticipants, min(numTasks) * 2);

    for pp = 1:nParticipants
        count = 1;
        for s = 1:min(numTasks)
            if s == 1
                % first walking segment: start to first task
                numStrideSegments(pp, count) = ...
                    length(1:allInitIndices{pp}(s) - 1);
                % first task segment
                numStrideSegments(pp, count+1) = ...
                    length(allInitIndices{pp}(s):allEndIndices{pp}(s));
            else
                % subsequent walking segment: between tasks
                numStrideSegments(pp, count) = length( ...
                    allEndIndices{pp}(s-1)+1 : allInitIndices{pp}(s)-1);
                % subsequent task segment
                numStrideSegments(pp, count+1) = length( ...
                    allInitIndices{pp}(s):allEndIndices{pp}(s));
            end
            count = count + 2;
        end
    end

    % determine target length for each segment type
    targetSegmentLength = [];
    for jj = 1:size(numStrideSegments, 2)
        if mod(jj, 2) ~= 0  % odd = walking → truncate to MIN
            targetSegmentLength = [targetSegmentLength, ...  %#ok<AGROW>
                min(numStrideSegments(:, jj))];
        else                 % even = task → pad to MAX
            targetSegmentLength = [targetSegmentLength, ...  %#ok<AGROW>
                max(numStrideSegments(:, jj))];
        end
    end

    % Calculate total length of aligned data
    finalMatrixLength = sum(targetSegmentLength);

    % get data fields to align (exclude task marker fields)
    fieldsToAlign = fieldnames(data);
    fieldsToAlign = fieldsToAlign(~contains(fieldsToAlign, ...
        {'percTaskInitStride','percTaskEndStride','pertSizePercTask'}));

    % initialize cells for updated marker positions
    newInitIndices = cell(nParticipants, 1);
    newEndIndices  = cell(nParticipants, 1);

    for field = 1:length(fieldsToAlign)
        fieldName      = fieldsToAlign{field};
        originalMatrix = data.(fieldName).(conditions{con}).trial1;
        finalPaddedMatrix = NaN(nParticipants, finalMatrixLength);

        %Access the original data matrix
            % Process each segment (walk/task alternating)
        for pp = 1:nParticipants
            currentRow     = originalMatrix(pp, :);
            lastNonNaNidx  = find(~isnan(currentRow), 1, 'Last');
            initIdx        = allInitIndices{pp};
            endIdx         = allEndIndices{pp};

            currentPaddedRow       = [];
            current_new_init_indices = [];
            current_new_end_indices  = [];
            currentStride          = 1;

            for jj = 1:length(targetSegmentLength)
                targetLen            = targetSegmentLength(jj);
                current_padded_row_len = length(currentPaddedRow);

                % determine segment boundaries from task markers
                if jj == 1
                    % first segment: start to first task
                    segEnd = initIdx(1) - 1;
                elseif mod(jj, 2) == 0
                    % even: perceptual task segment
                    k = jj / 2;
                    taskStart     = initIdx(k);
                    taskEnd       = endIdx(k);
                    currentStride = taskStart;
                    segEnd        = taskEnd;
                else
                    % odd: walking between tasks
                    k = (jj - 1) / 2;
                    if k < min(numTasks)
                        walkEnd = initIdx(k+1) - 1;
                    else
                        walkEnd = finalMatrixLength;
                    end
                    currentStride = endIdx(k) + 1;
                    segEnd        = walkEnd;
                end

                % extract segment data
                if segEnd >= currentStride
                    segment     = currentRow(currentStride:segEnd);
                    nextStride  = segEnd + 1;
                else
                    segment    = [];
                    nextStride = currentStride;
                end
                currentStride = nextStride;

                % apply truncation (walking) or padding (task)
                currentLen = length(segment);
                if mod(jj, 2) ~= 0     % odd = walking: truncate to MIN
                    processedSegment = segment(1:min(currentLen,targetLen));
                    if length(processedSegment) < targetLen
                        padding = NaN(1, targetLen - ...
                            length(processedSegment));
                        processedSegment = [processedSegment, padding];
                    end
                else                    % even = task: pad to MAX
                    padding = NaN(1, targetLen - currentLen);
                    processedSegment = [segment, padding];
                end

                % Calculate new indices for perceptual task markers
                if mod(j,2)==0%Even Segment(Task)
                    %Task initiation marker is at the beginning of the padded task segment
                    new_start_index=current_padded_row_len+1;
                    current_new_init_indices(end+1)=new_start_index;

                    %Task end marker is at the end of the padded task segment
                    new_end_index=current_padded_row_len+targetLen;
                    current_new_end_indices(end+1)=new_end_index;
                end
                currentPaddedRow=[currentPaddedRow,processedSegment];
            end

            % Add trailing data based on condition type
            if strcmp(conditions(cond),'Psychometricfit')
                % Adaptation characterization: add last 50 strides
                currentPaddedRow=[currentPaddedRow,currentRow(lastNonNaNidx-50:lastNonNaNidx)];
            elseif strcmp(conditions(cond),'PSEtracking')
                % PSE tracking: add last 15 strides
                currentPaddedRow=[currentPaddedRow,currentRow(lastNonNaNidx-15:lastNonNaNidx)];
            elseif sum(strcmp(conditions(cond),{'Familiarization','Baseline Perception','Post adaptation'}))>0
                % Standard conditions: add last 10 strides
                currentPaddedRow=[currentPaddedRow,currentRow(lastNonNaNidx-10:lastNonNaNidx)];
            else
                % Conditions without perceptual tasks: crop to minimum stride count
                currentPaddedRow=[currentPaddedRow,currentRow(1:maxStridesCond)];
            end

            % Store new marker indices for this participant
            newInitIndices{i}=current_new_init_indices;
            newEndIndices{i}=current_new_end_indices;

            % Add processed row to final matrix
            finalPaddedMatrix(i,1:length(currentPaddedRow))=currentPaddedRow;
        end
        % Store aligned data for this field
        paddedData.(fieldName).(conditions{cond}).trial1=finalPaddedMatrix;
    end

    % Create new binary marker matrices with updated positions
    newInitMatrix=zeros(nParticipants,size(finalPaddedMatrix,2));
    newEndMatrix=zeros(nParticipants,size(finalPaddedMatrix,2));

    for i=1:nParticipants
        newInitMatrix(i,newInitIndices{i})=1;
        newEndMatrix(i,newEndIndices{i})=1;
    end

    % Store updated marker matrices
    paddedData.percTaskInitStride.(conditions{cond}).trial1=newInitMatrix;
    paddedData.percTaskEndStride.(conditions{cond}).trial1=newEndMatrix;


end
end