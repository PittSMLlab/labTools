function [c,k,a,p] = findTemplate(template,dataseries,whitenFlag)
%FINDTEMPLATE Cross-correlation search for a template in a signal.
%
%   [c,k,a,p] = FINDTEMPLATE(template,dataseries,whitenFlag) searches for
% occurrences (or near-occurrences) of a template within a longer signal
% (dataseries) with a normalized cross-correlation computed through the FFT.
% The cosine c is that of the (detrended) window of dataseries with the
% template at each sample. The match is meant to be tested against a beta
% distribution fitted to c; the probability p is currently not computed.
% Errors if the cosines are complex or outside [-1,1].
%
% Inputs:
%   template   - vector, signal to look for
%   dataseries - vector, signal to search in (NaN counts as 0)
%   whitenFlag - (optional) 1 to whiten dataseries first (assumes
%                independent samples; improves detection)
%
% Outputs:
%   c - cosine between the template and the data window at each sample
%   k - scaling of the data to the template (energy ratio)
%   a - parameter of the beta distribution fitted to (1+c)/2
%   p - empty (probability of a match is not computed)
%
% Toolbox Dependencies: None
%
% See also XCORR.

N        = length(dataseries);
M        = length(template);
template = detrend(template,'constant');

%Remove NaN
dataseries(isnan(dataseries)) = 0;

%% Compute energy ratios (to be used if matches are found):
fft1 = fft(dataseries);
fft2 = fft(template,N);
fft3 = fft(ones(M,1),N);
k    = ifft(fft1.*conj(fft2))/norm(template)^2;

%% Whitening (improves detection under the assumption of independent
%% samples)
if nargin > 2 && ~isempty(whitenFlag)
    if whitenFlag == 1
        fftAux     = fft1;
        dataseries = ifft(fftAux./abs(fftAux),'symmetric');
        %template=ifft(fft(template,N)./abs(fftAux));
        %template=template(1:M);
        clear fftAux
    end
end

%% Determine auto-correlation matrix of noise
%The optimal matched filter should take the form: h=pinv(MM)*s
%where s is the signal we are looking for, and MM the auto-correlation
%matrix of the noise (undesired signal). If the noise is white, MM=eye(M)
MM = eye(M); %White noise assumption
%If we try to empirically determine the auto-correlation matrix (assuming
%most of the signal is noise):
%aux=ifft(fft(dataseries).*conj(fft(dataseries))); %Auto-correlation
%aux=aux(1:M)/aux(1);
%MM=toeplitz(aux);

%% Define the filter
filter = pinv(MM)*template;
filter = filter/norm(filter);
clear MM

%% Do the filtering
%Proper and inefficient way:
% p2=zeros(N-M+1,1);
% k2=zeros(N-M+1,1);
% for i=1:N-M+1
%    subTS=dataseries(i:i+M-1);
%    subTS=detrend(subTS,'constant');
%    k=norm(subTS);
%    subTS=subTS./k;
%    aux2=subTS'*template/norm(template);
%    p2(i)=aux2;
%    k2(i)=k/norm(template);
% end

%Try an efficient way:
fft2 = fft(filter,N);
fft2(1) = 0;
fft1      = fft(dataseries);
%Compute the inner product of template with a window of dataseries, all at
%once! (efficient xcorr)
p3        = ifft(fft1.*conj(fft2),'symmetric');
%Not detrended version
normTerm2 = ifft(fft(dataseries.^2).*conj(fft3),'symmetric');
%Here we remove the effect of the moving average (trend)
normTerm2 = normTerm2 - 1/M * ifft(fft1.*conj(fft3)).^2;
%Here we force all values to be positive. Non-positive values may happen
%because of rounding errors.
normTerm2(normTerm2 <= 0) = eps;
c = p3./(sqrt(normTerm2)*norm(filter));

if any(imag(c) ~= 0) | any(isnan(c))
    error('findTemplate:complexResults', ...
        'Computed cosine values were complex.')
end
if any(abs(c) > 1)
    error('findTemplate:numericalIssues', ...
        'Computed cosine values were outside the [-1,1] range')
end

%% Estimation of a parameter (beta distribution):
%From data:
%sigma2=var((1+p3)/2);
%a=.5*(1/(4*sigma2)-1); %Finding the best-fitting beta distribution given
%the variance. In theory, if all samples in the signal are iid, a=(M-1)/2;
H = 1/mean(2./(1+c));
%Another estimation of the distribution parameter that is less susceptible
%to heavy tails (which may occurr if there are many copies of the template
%hidden in the data).
a = (H-1)/(2*H-1);

%If whitened:
if nargin > 2 && ~isempty(whitenFlag)
    if whitenFlag == 1
        %In theory, if samples are independent:
        a = (M-1)/2;
    end
end

%% Compute probabilities of observing each value:
%p=betacdf((1+c)/2,a,a);
p = [];
% figure
% subplot(2,1,1)
% hist(c)
% subplot(2,1,2)
% hist(p)
%% Make a nice plot to compare histograms.
% figure
% [count,x]=hist(p2,100);
% hold on
% plot(x,cumsum(count)/(N-M+1))
% p=betacdf([0:.01:1],a,a);
% plot(2*[0:.01:1]-1,p,'r')
% hold off

%p=2*abs(betacdf((output+1)/2,(M-1)/300,(M-1)/300)-.5); %This is a way of
%computing the probability of seen that value from the expected random
%probability (beta) if we assume that all samples in the dataseries are
%independent (which is probably not the case, since our signal was
%filtered, and we are probably over-sampling it greatly).

end
