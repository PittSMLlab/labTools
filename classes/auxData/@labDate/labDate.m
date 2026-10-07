classdef labDate
    % labDate  Stores a single date as day, month, and year.
    %
    %   labDate provides a simple date representation and utilities for
    % date manipulation, comparison, and generation of date-based
    % identifiers.
    %
    % labDate properties:
    %   day   - day of month (1-31)
    %   month - month number (1-12)
    %   year  - four-digit year number
    %
    % labDate methods:
    %   labDate   - constructor for date object
    %   timeSince - calculates elapsed time from another date in months
    %   isempty   - checks if date equals default value
    %
    % labDate static methods:
    %   monthString    - converts month number to 3-letter string
    %   genIDFromClock - generates timestamp ID from current time
    %   getCurrent     - creates labDate for current date
    %   default        - generates the default date (Jan 1, 1900)
    %
    % See also: datetime

    % TODO: labDate essentially reimplements a small subset of what
    % datetime already provides — storage, construction from components,
    % and elapsed-time arithmetic — with less accuracy and no timezone or
    % DST awareness. Wrapping or replacing it with datetime would eliminate
    % the 30-days/month approximation in timeSince, remove the need for the
    % custom setters, and make the class interoperable with the rest of
    % MATLAB's date/time ecosystem. This is admittedly a large refactor
    % given how widely labDate is presumably used across labTools.

    %% Properties
    properties
        day   (1,1) double {mustBeInteger, mustBeInRange(day,   1, 31)} = 1
        month (1,1) double {mustBeInteger, mustBeInRange(month, 1, 12)} = 1
        year  (1,1) double {mustBeInteger} = 1900
    end

    %% Constructor
    methods
        function this = labDate(dd, mm, year)
            % labDate  Constructor for labDate class.
            %
            %   Inputs:
            %     dd   - Day of month; integer in range [1, 31]
            %     mm   - Month; either integer (1-12) or 3-character
            %            string (e.g., 'jan', 'dec')
            %     year - Four-digit year number
            %
            %   Outputs:
            %     this - labDate object
            %
            %   Examples:
            %     d = labDate(15, 3,     2015);
            %     d = labDate(15, 'mar', 2015);
            %
            %   See also: getCurrent, default

            this.day = dd;
            if ischar(mm) && length(mm) == 3
                switch lower(mm)
                    case {'jan', 'ene'},  this.month = 1;
                    case {'feb'},         this.month = 2;
                    case {'mar'},         this.month = 3;
                    case {'apr', 'abr'},  this.month = 4;
                    case {'may'},         this.month = 5;
                    case {'jun'},         this.month = 6;
                    case {'jul'},         this.month = 7;
                    case {'aug', 'ago'},  this.month = 8;
                    case {'sep', 'set'},  this.month = 9;
                    case {'oct'},         this.month = 10;
                    case {'nov'},         this.month = 11;
                    case {'dec', 'dic'},  this.month = 12;
                    otherwise
                        ME = MException('labDate:Constructor', ...
                            'Unrecognized month string.');
                        throw(ME);
                end
            elseif isnumeric(mm) && mm <= 12
                this.month = mm;
            else
                ME = MException('labDate:Constructor', ...
                    ['Month parameter is not a 3-letter string or ' ...
                    'a valid numerical value.']);
                throw(ME);
            end
            this.year = year;
        end
    end

    %% Date Calculation Methods
    methods
        % Suggested method: find number of years/months/days that
        % separate two dates. The method could be called like:

        % Defined in separate files in the @labDate class folder
        timeInMonths = timeSince(this, other)

        % TODO: Overriding isempty to mean "equals the sentinel date" is
        % unconventional — MATLAB users generally expect isempty to return
        % true only when an object has no data (e.g., a 0×0 array). A name
        % like isDefault() or isUninitialized() would be less surprising,
        % and would leave isempty free to behave as MATLAB's built-in would
        % expect.
        flag = isempty(this)

        % function disp(this)
        %     disp([num2str(this.day) ' ' ...
        %         labDate.monthString(this.month) ' ' ...
        %         num2str(this.year)]);
        % end
    end

    %% Static Methods
    methods (Static)
        function str = monthString(a)
            % monthString  Converts a numeric month to a 3-letter string.
            %
            %   Inputs:
            %     a - Month number (1-12)
            %
            %   Outputs:
            %     str - Three-character month abbreviation (lowercase)
            %
            %   Example:
            %     str = labDate.monthString(1);  % returns 'jan'
            %
            %   See also: labDate

            switch a
                case 1,  str = 'jan';
                case 2,  str = 'feb';
                case 3,  str = 'mar';
                case 4,  str = 'apr';
                case 5,  str = 'may';
                case 6,  str = 'jun';
                case 7,  str = 'jul';
                case 8,  str = 'aug';
                case 9,  str = 'sep';
                case 10, str = 'oct';
                case 11, str = 'nov';
                case 12, str = 'dec';
                otherwise, str = '';
            end
        end

        function id = genIDFromClock()
            % genIDFromClock  Generates timestamp ID from the current time.
            %
            %   Formats the current wall-clock time as a zero-padded string
            % in the form yyyymmddHHMMSS.
            %
            %   Outputs:
            %     id - String timestamp (e.g., '20150821111631')
            %
            %   Example:
            %     id = labDate.genIDFromClock();
            %
            %   See also: getCurrent, datetime

            t = datetime('now');
            id = sprintf('%04d%02d%02d%02d%02d%02d', ...
                t.Year, t.Month, t.Day, ...
                t.Hour, t.Minute, round(t.Second));
        end

        function d = getCurrent()
            % getCurrent  Creates a labDate for the current date.
            %
            %   Outputs:
            %     d - labDate object representing today's date
            %
            %   Example:
            %     d = labDate.getCurrent();
            %
            %   See also: default, datetime

            t = datetime('now');
            d = labDate(t.Day, labDate.monthString(t.Month), t.Year);
        end

        function d = default()
            % default  Generates the default sentinel date (Jan 1, 1900).
            %
            %   Outputs:
            %     d - labDate object set to Jan 1, 1900
            %
            %   See also: getCurrent, isempty

            d = labDate(1, 'jan', 1900);
        end
    end

end

