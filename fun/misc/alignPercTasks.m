function [paddedData]=alignPercTasks(data)
%alignPercTasks Aligns time-course data with multiple, sequential
%interleaved perceptual tasks by independently padding/truncating each
%segment (walk/task) to standardize data across all participants.
%
% For conditions WITH perceptual tasks:
%   - Walking segments are truncated to the MINIMUM length across participants
%   - Perceptual Task segments are padded to the MAXIMUM length across
%   participants (padded with NaNs)
%   - Task markers are preserved and adjusted to new positions
%
% For conditions WITHOUT perceptual tasks (e.g., baseline walking):
%   - All participants are cropped to the MINIMUM stride count
%   - Ensures uniform length across participants for analysis
%
% INPUTS:
%   data - A structure containing fields with PxN matrices where:
%          * P=number of participants (rows)
%          * N=number of strides (columns)
%          Required fields:
%            - percTaskInitStride: Binary markers (1) indicating task start
%            - percTaskEndStride: Binary markers (1) indicating task end
%            - pertSizePercTask: Perturbation size for each task (not
%            currenlty used but might need in the future MGR)
%            - Other data fields to be aligned (e.g., kinematic variables)
%          Each field contains subfields for conditions (e.g., .trial1)
%
% OUTPUTS:
%   paddedData - A structure with the same fields as input, containing:
%                * Aligned matrices with uniform length per condition
%                * Updated task marker positions in percTaskInitStride/percTaskEndStride
%                * All data fields processed identically for consistency

conditions=fields(data.percTaskInitStride);
for cond=1:length(conditions) % I think trial is always one so will use this as a reference for now

    taskInitMatrix=data.percTaskInitStride.(conditions{cond}).trial1;
    taskEndMatrix=data.percTaskEndStride.(conditions{cond}).trial1;
    % pertSize=data.pertSizePercTask.(conditions{cond}).trial1;
    [nParticipants,~]=size(taskInitMatrix);

    % Check if this condition has any perceptual tasks
    noPercTasks=true;
    if sum(find(taskInitMatrix==1))~=0 && sum(find(taskEndMatrix==1))~=0
        noPercTasks=false;
    end

    % for conditions without any perceptual tasks: calculate the minimun
    % stride count
    if noPercTasks
        % Get all field names to process
        fieldsToAlign=fieldnames(data);
        fieldsToAlign=fieldsToAlign(~contains(fieldsToAlign,{'percTaskInitStride','percTaskEndStride','pertSizePercTask'}));

        % Calculate minimum stride length across participants
        for i=1:nParticipants
            currentRow=data.(fieldsToAlign{1}).(conditions{cond}).trial1(i,:);
            maxStridesCond(i)=find(~isnan(currentRow),1,'Last');
        end
        maxStridesCond=min(maxStridesCond); % Maximum index for non-perceptual trials conditions
    end

    % Extract task marker indices for each participant
    allInitIndices=cell(nParticipants,1);
    allEndIndices=cell(nParticipants,1);
    % allpertSize=cell(nParticipants,1);

    numTasks=zeros(nParticipants,1);

    for i=1:nParticipants
        allInitIndices{i}=find(taskInitMatrix(i,:)==1);
        allEndIndices{i}=find(taskEndMatrix(i,:)==1);
        % allpertSize{i}=pertSize(i,find(taskInitMatrix(i,:)==1));

        % Number of tasks is equal to the number of init markers
        numTasks(i)=length(allInitIndices{i});

        % Sanity check: must have same number of start and end markers
        if length(allInitIndices{i})~=length(allEndIndices{i})
            warning('Participant %d has unequal number of init (%d) and end (%d) markers. Skipping alignment.', ...
                i,length(allInitIndices{i}),length(allEndIndices{i}));
            numTasks(i)=0;
        end
    end

    % Calculate the length of each segment (walking and perceptual task
    % segments) per participant
    numStrideSegments=zeros(nParticipants,min(numTasks)*2);

    for i=1:nParticipants
        count=1;
        for s=1:min(numTasks)
            if s==1
                % First walking segment: from start to first perceptual
                % task
                numStrideSegments(i,count)=length(1:allInitIndices{i}(s)-1);
                % First perceptual task segment
                numStrideSegments(i,count+1)=length(allInitIndices{i}(s):allEndIndices{i}(s));
                count=count+2;
            else
                % Subsequent walking segments: between perceptual tasks
                numStrideSegments(i,count)=length(allEndIndices{i}(s-1)+1:allInitIndices{i}(s)-1);
                % Susequent perceptual task segment
                numStrideSegments(i,count+1)=length(allInitIndices{i}(s):allEndIndices{i}(s));
                count=count+2;
            end

        end
    end

    % determine target length for each segment (walking/task)
    targetSegmentLength=[];
    for j=1:size(numStrideSegments,2)
        if mod(j, 2) ~= 0 % Odd Segment (Walking): Truncate to MIN length
            targetSegmentLength=[targetSegmentLength min(numStrideSegments(:,j))];
        else % Even Segment (Task): Pad to MAX length
            targetSegmentLength=[targetSegmentLength max(numStrideSegments(:,j))];
        end
    end

    % Calculate total length of aligned data
    finalMatrixLength=sum(targetSegmentLength);

    %Get all data fields to align (exclude marker fields)
    fieldsToAlign=fieldnames(data);
    fieldsToAlign=fieldsToAlign(~contains(fieldsToAlign,{'percTaskInitStride','percTaskEndStride','pertSizePercTask'}));

    % Initialize cells to store new marker positions
    newInitIndices=cell(nParticipants,1);
    newEndIndices=cell(nParticipants,1);

    % Process each data field
    for field=1:length(fieldsToAlign)
        fieldName=fieldsToAlign{field};

        %Access the original data matrix
        originalMatrix=data.(fieldName).(conditions{cond}).trial1;
        finalPaddedMatrix=NaN(nParticipants,finalMatrixLength);

        for i=1:nParticipants
            currentRow=originalMatrix(i,:);
            lastNonNaNidx=find(~isnan(currentRow),1,'Last');
            initIdx=allInitIndices{i};
            endIdx=allEndIndices{i};

            currentPaddedRow=[];
            current_new_init_indices=[];
            current_new_end_indices=[];
            currentStride=1;

            % Process each segment (walk/task alternating)
            for j=1:length(targetSegmentLength)

                targetLen=targetSegmentLength(j);
                current_padded_row_len=length(currentPaddedRow);

                % Determine segment boundaries based on task markers
                if j==1
                    % First segment: start to first perceptual task
                    segEnd=initIdx(1)-1;
                elseif mod(j,2)==0
                    % even segments are perceptual tasks
                    k=j/2;
                    taskStart=initIdx(k);
                    taskEnd=endIdx(k);
                    currentStride=taskStart;
                    segEnd=taskEnd;
                else
                    % odd segments are walking between tasks
                    k=(j-1)/2;
                    if k<min(numTasks)
                        walkEnd=initIdx(k+1)-1;
                    else
                        walkEnd=finalMatrixLength;
                    end
                    currentStride=endIdx(k)+1;
                    segEnd=walkEnd;
                end

                %Extract segment data
                if segEnd>=currentStride
                    segment=currentRow(currentStride:segEnd);
                    nextStride=segEnd+1;
                else
                    segment=[];
                    nextStride=currentStride;
                end
                currentStride=nextStride;

                %Apply Truncation or Padding
                currentLen=length(segment);

                if mod(j,2)~=0 % Odd Segment(MIN/Truncate for Walking)
                    processedSegment=segment(1:min(currentLen,targetLen));

                    if length(processedSegment)<targetLen
                        padding=NaN(1,targetLen-length(processedSegment));
                        processedSegment=[processedSegment,padding];
                    end

                else %Even Segment(MAX/Pad for Task)
                    padding=NaN(1,targetLen-currentLen);
                    processedSegment=[segment,padding];
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