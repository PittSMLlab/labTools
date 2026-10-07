function figHandle = plot(this)
%PLOT Implementation of the plot method for SynergySetCollections

%clusteredSynergySetCollections override this plotting function!


figHandle = figure('Name',['Plot of ' this.name ' Collection']);
hold on
%IF collection is 1D, plot each set in the collection as a row of a 2D
%array of plots
if numel(this.content) == length(this.content)
    N  = numel(this.content);
    M  = size(this.content{1}.content,1);
    h1 = zeros(M,N);
    h2 = zeros(M,N);
    for ii = 1:N
        for jj = 1:M
            h1(jj,ii) = subplot(3*N,M,[3*M*(ii-1)+jj, 3*M*(ii-1)+jj+M]);
            h2(jj,ii) = subplot(3*N,M,[3*M*(ii-1)+jj+2*M]);
        end
    end
    for ii = 1:N
        this.content{ii}.plot(h1(:,ii));
        subplot(h1(1,ii))
        ylabel(this.indexLabels{1}{ii})
    end
end
hold off
%If collection is 2D, issue an error, suggesting the collection is
%clustered and plotted then.

end

