function cColor = contrastColor(color)
%CONTRASTCOLOR
% NOTE: color must be vector of length 3 (RGB values from 0 to 1)

% counting the perceptive luminance - human eye favors green color ...
a = (0.299 * color(1) + 0.587 * color(2) + 0.114 * color(3));

if a > 0.5
    d = 0;      % bright colors - black font
else
    d = 1;      % dark colors - white font
end

cColor = [d d d];

end

