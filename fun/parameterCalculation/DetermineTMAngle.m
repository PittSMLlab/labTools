function [ ang ] = DetermineTMAngle( trialData )
%UNTITLED This function determines what angle a trial was run at based on
%the trial districiption which must contain this information
%  08/2016, CJS, The input trial is the trial description

%There is assuredely a better way to do this, but for right now...
%trial

trial=trialData.description;
if iscell(trial)
    trial=trial{1};
end
if iscell(trial)
    trial=char(trial);
end

% (~iscell(regexp(trial, 'deg')) && ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(regexp(trial, '8.5')) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5'))) 
failRead=false; 
if ~isempty(findstr(trial, 'deg'))%( ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(cell2mat(regexp(trial, '8.5'))) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5'))) 
%     if ~isempty(findstr(trial, '8.5 deg incline')) || ~isempty(findstr(trial, '8.5 deg uphill')) %(~iscell(regexp(trial, '8.5 deg incline')) && ~isempty(cell2mat(regexp(trial, '8.5 deg incline')))) || (~iscell(regexp(trial, '8.5 deg uphill')) && ~isempty(cell2mat(regexp(trial, '8.5 deg uphill')))) %~isempty(cell2mat(regexp(trial, '8.5 deg incline'))) || ~isempty(cell2mat(regexp(trial, '8.5 deg uphill'))) %|| (~isempty(regexp(trial, '8.5 deg'))
%         ang=8.5;
%     elseif ~isempty(findstr(trial, '8.5 deg decline')) || ~isempty(findstr(trial, '8.5 decline')) || ~isempty(findstr(trial, '8.5 deg downhill')) %(~iscell(regexp(trial, '8.5 deg decline')) ) || (~iscell(regexp(trial, '8.5 deg downhill')) )|| (~iscell(regexp(trial, '8.5 decline'))) % || || 
%         %(~iscell(regexp(trial, '8.5 deg decline')) && ~isempty(cell2mat(regexp(trial, '8.5 deg decline')))) || (~iscell(regexp(trial, '8.5 deg downhill')) && ~isempty(cell2mat(regexp(trial, '8.5 deg downhill'))))|| (~iscell(regexp(trial, '8.5 decline')) && ~isempty(cell2mat(regexp(trial, '8.5 decline')))) % || || 
%         ang=-8.5;
%     elseif ~isempty(cell2mat(regexp(trial, '5 deg incline')))|| ~isempty(cell2mat(regexp(trial, '5 deg uphill'))) || ~isempty(cell2mat(regexp(trial, '5 deg')))
%         ang=5;
%     elseif ~isempty(cell2mat(regexp(trial, '5 deg decline')))|| ~isempty(cell2mat(regexp(trial, '5 deg downhill')))
%         ang=-5;
%     else
%         ang=input(['What angle (in degrees) was the study run at ', trial, ': ',trialData.type ,'?   ']);
%     end
    if ~isempty(findstr(trial,'decline')) || ~isempty(findstr(trial,'downhill'))
        sign=-1;
    else %Assuming incline by default
        sign=1;
    end
    i=regexp(trial,'deg');
    if iscell(i)
        i=i{1};
    end
    string=trial(max([i,7])-6:i);
    digits=regexp(string,'\d'); %Assuming the number of degrees does not precede the string 'deg' by more than 5 chars
    if ~isempty(digits)
    number=str2double(string(digits)); %This discards any decimal points that may appear
    firstDigit=digits(1);
    lastDigit=digits(end);
    if firstDigit~=lastDigit
        dots=regexp(string,'\.');

        %Should check that digits are consecutive indexes, except for a single
        %dot in the middle:
        aux=sort([digits dots],'ascend');
        if any((aux-firstDigit-[0:length(aux)-1])~=0)
            failRead=true;
        end

        if ~isempty(dots)
            dots=dots(1);
            decimalPosition=lastDigit-dots(1);
            number=number/10^decimalPosition;
        end
    end
    
    if firstDigit>1 && string(firstDigit-1)=='-' %Using a minus sign to flip value
        sign=-1;
    end
    ang=number*sign;
    else %Didn't find digits
        failRead=true;
    end
    if failRead
        ang=input(['What angle (in degrees) was the study run at (' , trial, '): ',trialData.type ,'?   ']);
    end
        
else
    ang=0;
end

end

