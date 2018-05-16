function createfigure(data1, data2, data3)
%CREATEFIGURE(DATA1, DATA2, DATA3)
%  DATA1:  histogram data
%  DATA2:  histogram data
%  DATA3:  histogram data

%  Auto-generated by MATLAB on 15-May-2018 05:28:11

% Create figure
figure1 = figure('Name','0_003_24 :position error distribution');

% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);

% Create histogram
histogram(data1,'Parent',subplot1,'BinLimits',[-0.5 0.5],'BinWidth',0.02);

% Create xlabel
xlabel(' x(m) ','FontSize',11);

% Uncomment the following line to preserve the X-limits of the axes
% xlim(subplot1,[-0.5 0.5]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot1,[0 350]);
box(subplot1,'on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);

% Create histogram
histogram(data2,'Parent',subplot2,'BinLimits',[-0.5 0.5],'BinWidth',0.02);

% Create xlabel
xlabel(' y(m) ','FontSize',11);

% Uncomment the following line to preserve the X-limits of the axes
% xlim(subplot2,[-0.5 0.5]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot2,[0 350]);
box(subplot2,'on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);

% Create histogram
histogram(data3,'Parent',subplot3,'BinLimits',[-0.5 0.5],'BinWidth',0.02);

% Create xlabel
xlabel(' z(m) ','FontSize',11);

% Uncomment the following line to preserve the X-limits of the axes
% xlim(subplot3,[-0.5 0.5]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot3,[0 350]);
box(subplot3,'on');