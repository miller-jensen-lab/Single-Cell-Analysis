[cprobname, cprobpath]= uigetfile('.csv','Choose File to Recalculate');
if isequal(cprobname,0) || isequal(cprobpath,0)
    disp('User pressed cancel')
    return
else
    cprob=readtable([cprobpath cprobname],'ReadRowNames',1);
    close all
    hfig=figure;
    hfig.Position=get(0,'Screensize');    hfig.Units='centimeters'; %Fix paper size for proper printing
    set(hfig,'PaperPositionMode','manual','PaperUnits','centimeters')
    pos=get(hfig,'Position');    
    set(hfig,'PaperSize',[pos(3) pos(4)], 'PaperPosition',[0 0 pos(3) pos(4)]);
    set(hfig,'Units','pixels');

%     
    [him]=heatmap(cprob{:,:},cprob.Properties.RowNames,...
        cprob.Properties.VariableNames,1,'Colormap','hot',...
        'MinColorValue',0,'MaxColorValue',1,'ShowAllTicks',1,...
        'TickFontSize',16,'Colorbar',1,'TextColor','m','FontSize',12);
    him.Parent.XAxisLocation='top';
    him.Parent.TickLength=[0 0];
    title(cprobname(1:end-4));
    %     him=imagesc(cprob{:,:});
    %     hax=him.Parent;
    %     hax.XTick=cprob.Properties.VariableNames;
    %     hax.YTick=cprob.Properties.RowNames;
    %     colormap(hax.Parent,'default')
    %     hcolor=colorbar;
    button=questdlg('Save figure?');
    if strcmpi('yes',button);
    saveas(hfig,[cprobname(1:end-4) '.pdf'],'pdf');
    end
    
end