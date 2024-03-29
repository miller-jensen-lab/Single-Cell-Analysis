function choice = choose_ch_dialog(prompt,signal_names,chosen_channels)

prompt2=strcat(prompt(chosen_channels),signal_names(chosen_channels));
d = dialog('Units','Normalized','Position',[0.4 0.4 0.2 0.1],'Name','Select One');
txt = uicontrol('Parent',d,'Units','Normalized',...
    'Style','text',...
    'Position',[0.2 0.65 0.6 0.3],...
    'String','Select a channel to align GenePix signal (usually 555nm)',...
    'FontSize',12);

popup = uicontrol('Parent',d,'Units','Normalized',...
    'Style','popup',...
    'Position',[0.2 0.4 0.6 0.2],...
    'String',prompt2,...
    'Callback',@popup_callback,...
    'Value',1,'FontSize',12);

btn = uicontrol('Parent',d,'Units','Normalized',...
    'Position',[0.4 0.1 0.2 0.2],...
    'String','Close',...
    'Callback','delete(gcf)',...
    'FontSize',12);
choice=1;


% Wait for d to close before running to completion
uiwait(d);

    function popup_callback(popup,callbackdata)
        choice = popup.Value;
    end
end
