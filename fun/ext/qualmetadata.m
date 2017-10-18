classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) qualmetadata
% No help found for tsdata.qualmetadata. 

% Copyright 2005-2011 The MathWorks, Inc.

    properties
        Code;
        Description;
        UserData;
    end

    properties (Hidden = true, GetAccess = protected, SetAccess = protected)
        Version = 10.1;
    end
    
    methods
        
        function A = getData(h, data) %#ok<MANU>
            %GETDATA Extracts quality data from quality
            
            %   GETDATA is used to extract data from the quality ValueArray. It checks
            %   that the stored quality codes match the conversion table specified in
            %   the qualmetadata object.
            %
            %   Copyright 2005-2009 The MathWorks, Inc.
            
            % Cast quality codes back to doubles
            %data = double(data);
            
            if isempty(data) % Don't return any 0xn type arrays, which look strange in displays
                A = [];
            else
                A = data;
            end
        end
        
        function [out,new_metadata] = setData(h, newval)
            %SETDATA Assigns data into quality ValueArray
            %
            %   SETDATA is used to assign data into the quality ValueArray. It checks
            %   that the stored quality codes match the conversion table specified in
            %   the qualmetadata object and converts to int8 values prior to storage.
            
            %   Copyright 2005-2009 The MathWorks, Inc.
            
            % Sets data to the ValueArray data property if the "data" property
            
            % Quality data can be either a vector or an array with the same size
            % as the data
            
            % Cast quality codes to integers and check that this does not corrupt the
            % data
            oldval = newval;
            if any(isnan(newval(:)))
                error(message('MATLAB:tsdata:qualmetadata:setData:allint'))
            end
            newval = int8(real(newval));
            if ~isempty(newval) && any(abs(double(oldval(:))-double(newval(:)))>eps(255))
                error(message('MATLAB:tsdata:qualmetadata:setData:integerCodes'))
            end
            
            % workaround: UDD bug causing segV on non-Windows platforms
            if ~isempty(newval)
                out = newval;
            else
                out = [];
            end
            
            new_metadata = h;
        end
        
        function outmetadata = qualitymerge(in1, in2)
            %QUALITYMERGE  Merges qualmetadata in overloaded arithmetic and
            %concatenation. If quality tables are nested, function returns the
            %description with more info
            
            %   Copyright 2005-2009 The MathWorks, Inc.
            
            
            % Is in1 subset of in2?
            [~,I] = ismember(in1.Code,in2.Code);
            I = I(find(I)); %#ok<*FNDSB>
            if length(I)==length(in1.Code) && ~isempty(in1.Code) &&  ...
                    isequal(in1.Description,in2.Description(I))
                outmetadata = in2;
                return
            end
            
            % Is in1 subset of in2?
            [~,I] = ismember(in2.Code,in1.Code);
            I = I(find(I));
            if length(I)==length(in2.Code) && ~isempty(in2.Code) && ...
                    isequal(in2.Description,in1.Description(I))
                outmetadata = in1;
                return
            end
            
            % otherwise, return an empty one
            outmetadata = tsdata.qualmetadata;
        end
    end
    methods (Static = true)
        function this = loadobj(obj)
            if isstruct(obj)
                this = tsdata.qualmetadata;
                if isfield(obj,'Code')
                    this.Code = obj.Code;
                end
                if isfield(obj,'Description')
                    this.Description = obj.Description;
                end
                if isfield(obj,'UserData')
                    this.UserData = obj.UserData;
                end
            elseif isa(obj,'tsdata.qualmetadata')
                this = obj;
            else
                error(message('MATLAB:tsdata:qualmetadata:loadobj:invloadqualmetadata'));
            end
        end
    end
end



