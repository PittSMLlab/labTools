classdef labDate
    %labDate   stores a single date.
    %
    %labDate properties:
    %   day - number
    %   month - number (1-12)
    %   year - four digit number
    %
    %labDate Methods:
    %   monthString - outputs month as a 3-letter string
    %   genIDFromClock
    %   getCurrent
    %   default - generates default date (Jan 1, 1900)
    
    properties
        day; %a day (ex: 27)
        month; %a month (ex: 4)
        year;% a year (ex: 2015)
    end
    
    methods
        %constructor
        function this=labDate(dd,mm,year)
            this.day=dd;
            if isa(mm,'char') && length(mm)==3
                switch lower(mm)
                    case {'jan','ene'}
                        this.month=1;
                    case {'feb'}
                        this.month=2;
                    case {'mar'}
                        this.month=3;
                    case {'apr','abr'}
                        this.month=4;
                    case {'may'}
                        this.month=5;
                    case {'jun'}
                        this.month=6;
                    case {'jul'}
                        this.month=7;
                    case {'aug','ago'}
                        this.month=8;
                    case {'sep','set'}
                        this.month=9;
                    case {'oct'}
                        this.month=10;
                    case {'nov'}
                        this.month=11;
                    case {'dec','dic'}
                        this.month=12;
                    otherwise
                        ME=MException('labDate:Constructor','Unrecognized month string.');
                        throw(ME);
                end
           elseif isa(mm,'double') && mm<=12
               this.month=mm;
           else
                ME=MException('labDate:Constructor','Month parameter is not a 3-letter string or a valid numerical value.');
                throw(ME);
           end 
            this.year=year;
        end
        
        %Setters
        function this=set.day(this,dd)
            if dd<32 && dd>0 && rem(dd,1)==0
                this.day=dd;
            else
                ME=MException('labDate:Constructor','Day parameter is not an integer in the [1,31] range.');
                throw(ME);
            end
        end        
        
        % HH: no setter for month because it was mis-behaving
%         function this=set.month(this,mm)
%            
%         end        
        function this=set.year(this,year)
            if rem(year,1)==0
                this.year=year;
            else
                ME=MException('labDate:Constructor','Year parameter is not an integer.');
                throw(ME);
           end 
        end
    end 
    
    
    %Suggested method: find number of years/months/days that separate two
    %dates. The method could be called like
    %[days,months,years]=labDate1.timeSince(labDate2)
    
    methods(Static)
        
        function str=monthString(a)
        % monthString  turns numeric month value into a string
        %   str=monthString(a) outputs a three-character string for an
        %   integer between 1 and 12 (inclusive).
        %   example:
        %       monthString(1) returns 'jan'.
            switch a
                case 1
                    str='jan';
                case 2
                    str='feb';
                case 3
                    str='mar';
                case 4
                    str='apr';
                case 5
                    str='may';
                case 6
                    str='jun';
                case 7
                    str='jul';
                case 8
                    str='aug';
                case 9
                    str='sep';
                case 10
                    str='oct';
                case 11
                    str='nov';
                case 12
                    str='dec';
                otherwise
                    str='';
            end
        end
        
        function id=genIDFromClock()
           aux=clock;
           id=num2str(aux(1)*10^10+aux(2)*10^8+aux(3)*10^6+aux(4)*10^4+aux(5)*10^2+round(aux(6)));
        end
        
        function d=getCurrent()
            aux=clock;
            d=labDate(aux(3),labDate.monthString(aux(2)),aux(1));
        end
        
        function d=default()
            d=labDate(1,'jan',1900);
        end
    end
    
end

