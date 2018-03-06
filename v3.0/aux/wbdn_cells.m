function wbdn_cells(hObject, eventdata, handlesM)
%Executes when clicked on image with add/remove cells toggle on
%Load guidata otherwise the cell update doesn't change
handles=guidata(handlesM);
tabname=handles.tabgroup.SelectedTab.Title;
i=sscanf(tabname,'%*s%d');
targetx=eventdata.IntersectionPoint(1);
targety=eventdata.IntersectionPoint(2);
sel_type=get(handles.MasterGUI,'SelectionType');
%Check if selected point is inside any well
well_index=find(cellfun(@(X) inpolygon(targetx, targety, ...
    X(:,2),X(:,1)),handles.BWcol_border{i}));
if ~isempty(well_index)
    if length(well_index)>1
        well_index=well_index(end);
    end
    if strcmpi(sel_type,'normal')
        %Left click to add cell
        handles.Cell_Locs.x{i}{well_index}=...
            [handles.Cell_Locs.x{i}{well_index}; targetx];
        handles.Cell_Locs.y{i}{well_index}=...
            [handles.Cell_Locs.y{i}{well_index}; targety];
    elseif strcmpi(sel_type,'alt')
        sel_cellsx=handles.Cell_Locs.x{i}{well_index};
        sel_cellsy=handles.Cell_Locs.y{i}{well_index};
        target_cell=find(sel_cellsx>=targetx-14 & sel_cellsx<=targetx+14 ...
            & sel_cellsy>=targety-14 & sel_cellsy<= targety+14,1);
        
        if ~isempty(target_cell)
            %Delete chosen cell
            handles.Cell_Locs.x{i}{well_index}(target_cell)=[];
            handles.Cell_Locs.y{i}{well_index}(target_cell)=[];
            %If chosen well is now empty, make sure cell is an empty vector
            %with dimensions 0X0
            if isempty(handles.Cell_Locs.x{i}{well_index});
                handles.Cell_Locs.x{i}{well_index}=[];
                handles.Cell_Locs.y{i}{well_index}=[];
            end
        else
            return
        end
        
    end
    %Display the cell outlined in circles
    cell_centers=[vertcat(handles.Cell_Locs.x{i}{:}) ...
        vertcat(handles.Cell_Locs.y{i}{:})];
    delete(handles.vis_circles_tab(i));
    if ~isempty(cell_centers);
        radii_vec=ones(size(cell_centers,1),1).*12;
        handles.vis_circles_tab(i)=viscircles(handles.axes_tab(i),cell_centers,...
            radii_vec);
        handles.vis_circles_tab(i).PickableParts='none';
    end
    %Updates only that individual text file
    cell_count=num2str(length(handles.Cell_Locs.x{i}{well_index}));
    labels=strcat('Well\_',num2str(well_index),' (', cell_count, ' cells)');
    handles.htext{i}(well_index).String=labels;
% % %     %Updates text all of it (very slow)
% % %     delete(handles.htext{i});
% % %     %Insert text
% % %     sorted_well_mins=cell2mat(cellfun(@(X) X(find(X(:,2)==min(X(:,2)),1),:), handles.BWcol_border{i},...
% % %                 'UniformOutput',0));
% % %             %Below is original form detecting minimum row and column, but
% % %             %lavbels could be off
% % % %     sorted_well_mins=cell2mat(cellfun(@min, handles.BWcol_border{i},...
% % % %         'UniformOutput',0));          
% % %     well_nums=num2cell(1:length(handles.BWcol_border{i}))';
% % %     well_nums=cellfun(@num2str, well_nums,'UniformOutput',0);
% % %     cell_count=cellfun(@(X) num2str(length(X)),handles.Cell_Locs.x{i},'UniformOutput',0);
% % % %     cell_count=cellfun(@num2str,cell_count,'UniformOutput',0);
% % %     labels=strcat('Well\_',well_nums,' (', cell_count, ' cells)');
% % %     not_visible=find(handles.visibility{i}==0);
% % %     labels(not_visible)=strcat('Invisible\_',labels(not_visible));
% % %     handles.htext{i}=text(sorted_well_mins(:,2)-80,sorted_well_mins(:,1),labels,'Parent',...
% % %         handles.axes_tab(i),'Color','r','FontSize',14,'PickableParts','none');
% % %     %Change color to green if all wells identified in this
% % %     %column.
% % %     if length(handles.BWcol_border{i})==handles.numWells
% % %         set(handles.htext{i},'Color','g');
% % %         cellfun(@(X) set(X,'Color','g'),handles.hplot{i});
% % %     else
% % %         set(handles.htext{i},'Color','r');
% % %         cellfun(@(X) set(X,'Color','r'),handles.hplot{i});
% % %     end
    %Update handles structure
    guidata(handles.MasterGUI,handles);
    
end
end
