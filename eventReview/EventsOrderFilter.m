function [RHS,RTO,LHS,LTO] = EventsOrderFilter(RightHS,RightTO,LeftHS,LeftTO)
% 
% ldata = Trial.Angle.LLimb;
% rdata = Trial.Angle.RLimb;

RightHS(RightHS==0)=[];
RightTO(RightTO==0)=[];
LeftHS(LeftHS==0)=[];
LeftTO(LeftTO==0)=[];



if RightHS(1)<LeftHS(1)
    
    tempLHS = LeftHS(1);
    events = RightHS(RightHS > 0 & RightHS < tempLHS);
    RHS(1) = tempLHS - min(abs(events-tempLHS));
    events = LeftTO(LeftTO > RHS(1) & LeftTO < tempLHS);
    if isempty(events)
        LTO(1) = LeftTO(find(LeftTO>tempLHS,1,'first'));
        tempLHS = LeftHS(find(LeftHS>LTO(1),1,'first'));
%         [blah, LTO(1)] = min(ldata(RHS(1):tempLHS));
    else
        LTO(1) = tempLHS - min(abs(events-tempLHS));
    end
    
    tempRHS = RightHS(find(RightHS>tempLHS,1,'first'));
    events = LeftHS(LeftHS>LTO(1) & LeftHS<tempRHS);
    LHS(1) = tempRHS - min(abs(events-tempRHS));
    events = RightTO(RightTO>LHS(1) & RightTO<tempRHS);
    if isempty(events)
        RTO(1) = RightTO(find(RightTO>tempRHS,1,'first'));
        tempRHS = RightHS(find(RightHS>RTO(1),1,'first'));
    else
        RTO(1) = tempRHS - min(abs(events-tempRHS));
    end
    
    for n = 2:1000
        tempLHS = LeftHS(find(LeftHS>tempRHS,1,'first'));
        if isempty(tempLHS)
            break
        end
        events = RightHS(RightHS > RTO(n-1) & RightHS < tempLHS);
        if isempty(events)
            break
        end
        RHS(n) = tempLHS - min(abs(events-tempLHS));
        events = LeftTO(LeftTO > RHS(n) & LeftTO < tempLHS);
        if isempty(events)
            if ~isempty(find(LeftTO>tempLHS,1,'first'))
                LTO(n) = LeftTO(find(LeftTO>tempLHS,1,'first'));
                tempLHS = LeftHS(find(LeftHS>LTO(n),1,'first'));
                if isempty(tempLHS)
                    break
                end
            else
                break
            end
        else
            LTO(n) = tempLHS - min(abs(events-tempLHS));
        end
        
        tempRHS = RightHS(find(RightHS>tempLHS,1,'first'));
        if isempty(tempRHS)
            break
        end
        events = LeftHS(LeftHS>LTO(n) & LeftHS<tempRHS);
        if isempty(events)
            break
        end
        LHS(n) = tempRHS - min(abs(events-tempRHS));
        events = RightTO(RightTO>LHS(n) & RightTO<tempRHS);
        if isempty(events)            
            if ~isempty(find(RightTO>tempRHS,1,'first'))              
                RTO(n) = RightTO(find(RightTO>tempRHS,1,'first'));
                tempRHS = RightHS(find(RightHS>RTO(n),1,'first'));
                if isempty(tempRHS)
                    break
                end
            else
                break
            end
        else
            RTO(n) = tempRHS - min(abs(events-tempRHS));
        end
    end
    
else %LeftHS(1)<RightHS(1)
    
    tempRHS = RightHS(1);
    events = LeftHS(LeftHS > 0 & LeftHS < tempRHS);
    LHS(1) = tempRHS - min(abs(events-tempRHS));
    events = RightTO(RightTO > LHS(1) & RightTO < tempRHS);
    if isempty(events)
        RTO(1) = RightTO(find(RightTO>tempRHS,1,'first'));
        tempRHS = RightHS(find(RightHS>RTO(1),1,'first'));
    else
        RTO(1) = tempRHS - min(abs(events-tempRHS));
    end
    
    tempLHS = LeftHS(find(LeftHS>tempRHS,1,'first'));
    events = RightHS(RightHS>RTO(1) & RightHS<tempLHS);
    RHS(1) = tempLHS - min(abs(events-tempLHS));
    events = LeftTO(LeftTO>RHS(1) & LeftTO<tempLHS);
    if isempty(events)
        LTO(1) = LeftTO(find(LeftTO>tempLHS,1,'first'));
        tempLHS = LeftHS(find(LeftHS>LTO(1),1,'first'));
    else
        LTO(1) = tempLHS - min(abs(events-tempLHS));
    end
    
    for n = 2:1000
        tempRHS = RightHS(find(RightHS>tempLHS,1,'first'));
        if isempty(tempRHS)
            break
        end
        events = LeftHS(LeftHS > LTO(n-1) & LeftHS < tempRHS);
        if isempty(events)
            break
        end
        LHS(n) = tempRHS - min(abs(events-tempRHS));
        events = RightTO(RightTO > LHS(n) & RightTO < tempRHS);
        if isempty(events)
             if ~isempty(find(RightTO>tempRHS,1,'first'))
                RTO(n) = RightTO(find(RightTO>tempRHS,1,'first'));
                tempRHS = RightHS(find(RightHS>RTO(n),1,'first'));
                if isempty(tempRHS)
                    break
                end
            else
                break
            end
        else
            RTO(n) = tempRHS - min(abs(events-tempRHS));
        end
        
        tempLHS = LeftHS(find(LeftHS>tempRHS,1,'first'));
        if isempty(tempLHS)
            break
        end
        events = RightHS(RightHS>RTO(n) & RightHS<tempLHS);
        if isempty(events)
            break
        end
        RHS(n) = tempLHS - min(abs(events-tempLHS));
        events = LeftTO(LeftTO>RHS(n) & LeftTO<tempLHS);
        if isempty(events)
            if ~isempty(find(LeftTO>tempLHS,1,'first'))
                LTO(n) = LeftTO(find(LeftTO>tempLHS,1,'first'));
                tempLHS = LeftHS(find(LeftHS>LTO(n),1,'first'));                
                if isempty(tempLHS)
                    break
                end
            else
                break
            end
        else
            LTO(n) = tempLHS - min(abs(events-tempLHS));
        end
    end
    
end
