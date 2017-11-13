function f=getOtherLeg(s)
    switch s
        case 'L'
            f='R';
        case 'R'
            f='L';
        case 's'
            f='f';
        case 'f'
            f='s';
    end
end
