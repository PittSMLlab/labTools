function handles=loadInfoFile(file,path)
    aux=load([path file]);
    fieldNames=fields(aux);
    subInfo=aux.(fieldNames{1});
    %TO DO: check that file is correct
    if ~isa(subInfo,'struct')
        error('File selected does not seem to be an info file.','Load Error');
    else
        % -- Experiment Info
        descriptionContents=cellstr(get(handles.description_edit,'string'));
        if isfield(subInfo,'ExpFile') %processed after 4/2015
            if ~any(strcmp(descriptionContents,subInfo.ExpFile)==1)
                set(handles.description_edit,'String',[descriptionContents; subInfo.ExpFile])
                descriptionContents=cellstr(get(handles.description_edit,'string'));
            end
            set(handles.description_edit,'Value',find(strcmp(descriptionContents,subInfo.ExpFile)));
        else
            if ~any(strcmp(descriptionContents,subInfo.ExpDescription)==1)
                set(handles.description_edit,'String',[descriptionContents; subInfo.ExpDescription])
                descriptionContents=cellstr(get(handles.description_edit,'string'));
            end
            set(handles.description_edit,'Value',find(strcmp(descriptionContents,subInfo.ExpDescription)));
        end
        handles.group=subInfo.ExpDescription;
        
        
        set(handles.name_edit,'string',subInfo.experimenter);
        monthContents = cellstr(get(handles.month_list,'String'));
        set(handles.month_list,'Value',find(strcmp(monthContents,subInfo.month)));
        set(handles.day_edit,'string',subInfo.day);
        set(handles.year_edit,'string',subInfo.year);
        set(handles.note_edit,'string',subInfo.exp_obs);
        % -- Subject Info
        set(handles.subID_edit,'string',subInfo.ID);
        DOBmonthContents = cellstr(get(handles.DOBmonth_list,'String'));
        set(handles.DOBmonth_list,'Value',find(strcmp(DOBmonthContents,subInfo.DOBmonth)));
        set(handles.DOBday_edit,'string',subInfo.DOBday);
        set(handles.DOByear_edit,'string',subInfo.DOByear);
        genderContents = cellstr(get(handles.gender_list,'String'));
        set(handles.gender_list,'Value',find(strcmp(genderContents,subInfo.gender)));
        domlegContents = cellstr(get(handles.domleg_list,'String'));
        set(handles.domleg_list,'Value',find(strcmp(domlegContents,subInfo.domleg)));
        domhandContents = cellstr(get(handles.domhand_list,'String'));
        set(handles.domhand_list,'Value',find(strcmp(domhandContents,subInfo.domhand)));
        set(handles.height_edit,'string',subInfo.height);
        set(handles.weight_edit,'string',subInfo.weight);
        if isfield(subInfo,'isStroke') %for subject processed before 11/2014
            set(handles.strokeCheck,'Value',subInfo.isStroke);
        else %Case of old info files, prior support for stroke subjects
            set(handles.strokeCheck,'Value',0);
        end
        if get(handles.strokeCheck,'Value')
            set(handles.popupAffected,'Enable','On');
            set(handles.popupAffected,'Value',subInfo.affectedValue);
        end
        % -- Data Info
        handles.folder_location=subInfo.dir_location;
        set(handles.c3dlocation,'string',handles.folder_location);
        set(handles.basefile,'string',subInfo.basename);
        set(handles.numofconds,'string',subInfo.numofconds);
        numofconds_Callback(handles.numofconds,eventdata,handles)
        set(handles.kinematic_check,'Value',subInfo.kinematics);
        set(handles.force_check,'Value',subInfo.forces);
        set(handles.emg_check,'Value',subInfo.EMGs);
        handles.secfolder_location=subInfo.secdir_location;
        set(handles.secfileloc,'string',handles.secfolder_location)
        % -- Trial Info
        for c = 1:subInfo.numofconds
            condNum=subInfo.cond(c);
            set(handles.(['condition',num2str(c)]),'string',num2str(condNum));
            set(handles.(['condName',num2str(c)]),'string',subInfo.conditionNames{condNum});
            set(handles.(['description',num2str(c)]),'string',subInfo.conditionDescriptions{condNum});
            trialnums=subInfo.trialnums{condNum};
            if length(trialnums)>2 && ~any(diff(trialnums)>1)
                set(handles.(['trialnum',num2str(c)]),'string',[num2str(trialnums(1)),':',num2str(trialnums(end))]);
            else
                set(handles.(['trialnum',num2str(c)]),'string',num2str(trialnums));
            end
            if isfield(subInfo,'isOverGround') %for subjects processed before 7/16/2014
                if subInfo.isOverGround(condNum)
                    set(handles.(['type',num2str(c)]),'string','OG');
                else
                    set(handles.(['type',num2str(c)]),'string','TM');
                end
            else
                set(handles.(['type',num2str(c)]),'string',subInfo.type{condNum});
            end
        end
        % -- emg data
        if isfield(subInfo,'EMGList1') && isfield(subInfo,'EMGList2') %for subjects processed before 7/29/2014
            for i=1:16
                aux1=['emg1_' num2str(i)];
                set(handles.(aux1),'string',subInfo.EMGList1{i});
                aux2=['emg2_' num2str(i)];
                set(handles.(aux2),'string',subInfo.EMGList2{i});
            end
        end
        % --  save location
        handles.save_folder=subInfo.save_folder;
        set(handles.saveloc_edit,'string',handles.save_folder);
        % -- Trial observations
        if isfield(subInfo,'trialObs')
            handles.trialObs=subInfo.trialObs;
        end
    end
end