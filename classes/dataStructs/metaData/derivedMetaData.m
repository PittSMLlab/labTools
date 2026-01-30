classdef derivedMetaData < trialMetaData
    %derivedMetaData  Metadata for data derived from a parent trial
    %
    %   derivedMetaData extends trialMetaData to represent metadata
    %   for data segments or processed data derived from a parent
    %   trial. It maintains a reference to the parent trial's
    %   metadata and can inherit properties from it.
    %
    %derivedMetaData properties:
    %   parentMetaData - reference to the parent trial's metadata
    %                    object
    %   (inherits all properties from trialMetaData)
    %
    %derivedMetaData methods:
    %   derivedMetaData - constructor for derived metadata
    %
    %See also: trialMetaData, strideMetaData

    %% Properties
    properties (SetAccess = private)
        parentMetaData
    end

    %% Constructor
    methods
        function this=derivedMetaData(ID,date,experimenter,desc,obs,refLeg,parentMeta,condition,rawDataFilename,type,schenleyLab,perceptualTasks,datlog,fastLeg)
            if nargin == 7 %parentMeta is give, but no other args are given, set it to the parent
                condition = parentMeta.condition;
                rawDataFilename = parentMeta.rawDataFilename;
                type=parentMeta.type;
                schenleyLab=parentMeta.schenleyLab;
                perceptualTasks=parentMeta.perceptualTasks;
                datlog=parentMeta.datlog;
                % fastLeg=parentMeta.fastLeg;
                % backwardCheck=parentMeta.backwardCheck;
            end
            if ~exist('condition','var') %no condition provided & hasn't been set by parent meta.
                condition = []; %default to empty (the type of default to set see @trialMetaData properties default)
            end
            if ~exist('rawDataFilename','var') %no condition provided
                rawDataFilename = ""; %default to empty
            end
            if ~exist('type','var') %no condition provided
                type = ""; %default to empty
            end
            if ~exist('schenleyLab','var') %no condition provided
                schenleyLab = ""; %default to empty
            end
            if ~exist('perceptualTasks','var') %no condition provided
                perceptualTasks = ""; %default to empty
            end
            if ~exist('datlog','var') %no condition provided
                datlog = ""; %default to empty
            end

            if ~exist('fastLeg','var') %no condition provided
                fastLeg = refLeg; %default to empty
            end

            if ~exist('backwardCheck','var') %no condition provided
                backwardCheck = ""; %default to empty
            end

            this@trialMetaData(ID,desc,obs,refLeg,condition,rawDataFilename,parentMeta.type,schenleyLab,perceptualTasks,datlog)
            %if isa(parentMeta,'labMetaData'); %Had to comment this on
            %10/7/2014, because trialMetaData and experimentMetaData are no
            %longer labMetaData objects. -Pablo
            this.parentMetaData=parentMeta;
            %else
            %    ME=MException('derivedMetaData:Constructor','parentMetaData is not a labMetaData object.');
            %    throw(ME);
            %end
        end

    end

end

