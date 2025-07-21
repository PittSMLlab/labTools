
%% Example for non-heteroscedastic residuals
x = transpose(0.1:0.1:50);
y = x + randn(numel(x),1);



% with Linear model input
lm = fitlm(x,y);
[T,P,df] = BPtest(lm);


% with matrix input
[T,P,df] = BPtest([x,y]);



%% Example for heteroscedastic residuals

x = transpose(0.1:0.1:50);
y = x.*randn(numel(x),1);


% lm input (with standard BP test)
lm = fitlm(x,y);
[T,P,df] = BPtest(lm,false);
plotResiduals(lm,'fitted')
