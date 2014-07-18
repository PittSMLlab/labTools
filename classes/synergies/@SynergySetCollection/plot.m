function [figHandle] = plot(this)
%PLOT Implementation of the plot method for SynergySetCollections

%clusteredSynergySetCollections override this plotting function!


figHandle=figure('Name',['Plot of ' this.name ' Collection']);
hold on
%IF collection is 1D, plot each set in the collection as a row of a 2D
%array of plots
if numel(this.content)==length(this.content)
    N=numel(this.content);
    M=size(this.content{1}.content,1);
    h1=zeros(M,N);
    h2=zeros(M,N);
    for i=1:N
        for j=1:M
            h1(j,i)=subplot(3*N,M,[3*M*(i-1)+j, 3*M*(i-1)+j+M]);
            h2(j,i)=subplot(3*N,M,[3*M*(i-1)+j+2*M]);
        end
    end
    for i=1:N
        this.content{i}.plot(h1(:,i));
        subplot(h1(1,i))
        ylabel(this.indexLabels{1}{i})
    end
end
hold off
%If collection is 2D, issue an error, suggesting the collection is
%clustered and plotted then.

end

