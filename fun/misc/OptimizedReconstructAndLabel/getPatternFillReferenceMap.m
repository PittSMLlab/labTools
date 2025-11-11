function refMap = getPatternFillReferenceMap()

    refMap = containers.Map;

    refMap('RPSIS') = 'RGT';
    refMap('RASIS') = 'RGT';
    refMap('LPSIS') = 'LGT';
    refMap('LASIS') = 'LGT';
    refMap('RGT') = 'RKNEE';
    refMap('RTHI') = 'RGT';
    refMap('RKNEE') = 'RGT';
    refMap('RSHANK') = 'RKNEE';
    refMap('RANK') = 'RKNEE';
    refMap('RHEEL') = 'RANK';
    refMap('RTOE') = 'RANK';
    refMap('LGT') = 'LKNEE';
    refMap('LTHI') = 'LGT';
    refMap('LKNEE') = 'LGT';
    refMap('LSHANK') = 'LKNEE';
    refMap('LANK') = 'LKNEE';
    refMap('LHEEL') = 'LANK';
    refMap('LTOE') = 'LANK';
end
