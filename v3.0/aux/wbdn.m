%Callback function that executes when clicking down on Image with
%add/remove well clicked on
function wbdn(hObject, eventdata, handles)
%Re-load handles object
handles=guidata(handles.MasterGUI);
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
        %Left click to add well
        new_line=copyobj(handles.hplot{i}{well_index},handles.axes_tab(i));
        x_init=new_line.XData;
        y_init=new_line.YData;
        new_well_visible=true(1);
        handles.MasterGUI.WindowButtonMotionFcn={@wbmot, handles};
        handles.MasterGUI.WindowButtonUpFcn={@wbup, handles};
    elseif strcmpi(sel_type,'alt')
        handles.MasterGUI.WindowButtonUpFcn={@wbup, handles};
    end
else
    if strcmpi(sel_type,'normal')
        %Left click to add invisible well when you click outside a well
        new_well_visible=false(1);
        %Make x and y vertices for a square 10 pixels around selected point
        inv_x= [targetx-10 targetx+10 targetx+10 targetx-10 targetx-10]';
        inv_y= [targety-10 targety-10 targety+10 targety+10 targety-10]';
        new_line= plot(handles.axes_tab(i),inv_x,inv_y,'r-',...
            'PickableParts','none');
        set(handles.MasterGUI,'WindowButtonUpFcn',{@wbup, handles});
        %Define well index
%         well_mins=cellfun(@(X) min(X(:,1)), handles.BWcol_border{i});
%         [~, well_index]=min(abs(well_mins-targety));
    elseif strcmpi(sel_type,'alt')
        del_box=plot(handles.axes_tab(i),targetx,targety,'b-',...
            'PickableParts','none');
        set(handles.MasterGUI,'WindowButtonMotionFcn',{@wbmot, handles});
        set(handles.MasterGUI,'WindowButtonUpFcn',{@wbup, handles});
    end
end


%Callback function that executes when moving mouse while clicking down
    function wbmot(hObject, eventdata, handles)
        %Get poistion of mouse to see if it is above the active panel
        set(handles.MasterGUI,'Units','normalized');
        set(handles.uipanel1,'Units','normalized');
        mouse_pos=get(handles.MasterGUI,'CurrentPoint');
        uipanel_pos=get(handles.uipanel1,'Position');
        set(handles.MasterGUI,'Units','default');
        set(handles.uipanel1,'Units','default');
        
        if mouse_pos(1)>=uipanel_pos(1) && mouse_pos(1)<=uipanel_pos(1)+uipanel_pos(3)...
                && mouse_pos(2)>=uipanel_pos(2) && mouse_pos(2)<=uipanel_pos(2)+uipanel_pos(4);
            if strcmpi(sel_type,'normal')
                new_point=handles.axes_tab(i).CurrentPoint;
                x_diff=new_point(1,1)-targetx;
                y_diff=new_point(1,2)-targety;
                new_x=x_init + x_diff;
                new_y=y_init + y_diff;
                set(new_line,'XData',new_x);
                set(new_line,'YData',new_y);
                drawnow;
            elseif strcmpi(sel_type,'alt')
                new_point=handles.axes_tab(i).CurrentPoint;
                newx=new_point(1,1);
                newy=new_point(1,2);
                del_box.XData=[targetx newx newx targetx targetx];
                del_box.YData=[targety targety newy newy targety];
                drawnow;
            end
            
            
            %                 disp('you moved')
            
        end
    end

%Callback function that executes when releasing mouse click
    function wbup(hObject, eventdata, handles)
        %Get poistion of mouse to see if it is above the active panel
        set(handles.MasterGUI,'WindowButtonMotionFcn',[]);
        set(handles.MasterGUI,'Units','normalized');
        set(handles.uipanel1,'Units','normalized');
        mouse_pos=get(handles.MasterGUI,'CurrentPoint');
        uipanel_pos=get(handles.uipanel1,'Position');
        set(handles.MasterGUI,'Units','default');
        set(handles.uipanel1,'Units','default');
        
        if mouse_pos(1)>=uipanel_pos(1) && mouse_pos(1)<=uipanel_pos(1)+uipanel_pos(3)...
                && mouse_pos(2)>=uipanel_pos(2) && mouse_pos(2)<=uipanel_pos(2)+uipanel_pos(4);
            if strcmpi(sel_type,'normal')
                %Find if the new line is above or below 
                %Adds the new copied well to the handle structure
                handles.BWcol_border{i}=vertcat(handles.BWcol_border{i},...
                    [new_line.YData' new_line.XData']);
                %Re-orders the wells in appropriate order
                well_mins=cellfun(@(X) min(X(:,1)), handles.BWcol_border{i});
                [~,sortindex]=sortrows(well_mins);
                handles.BWcol_border{i}=handles.BWcol_border{i}(sortindex);
                %Finds the number of the new well
                if new_well_visible==0
                    %Release point is location of the invisible well
                    release_point=[targetx targety];
                else
                    %Release point is the location of the new dragged well
                    release_point=get(handles.axes_tab(i),'CurrentPoint');
                end
                %New well number
                r_well=find(cellfun(@(X) inpolygon(release_point(1,1),...
                    release_point(1,2), X(:,2),X(:,1)),handles.BWcol_border{i}));
                %Adds the hline in correct order
                handles.hplot{i}=vertcat(handles.hplot{i}(1:r_well-1),...
                    {new_line}, handles.hplot{i}(r_well:end));
                clear('new_line');
                %Adds visibility in the correct order
                handles.visibility{i}=vertcat(handles.visibility{i}(1:r_well-1),...
                    new_well_visible, handles.visibility{i}(r_well:end));
                if strcmpi(handles.caller,'cellsandsignal')
                    %Adds new well for cell counts in the correct order
                    handles.Cell_Locs.x{i}=vertcat(handles.Cell_Locs.x{i}(1:r_well-1),...
                        {[]}, handles.Cell_Locs.x{i}(r_well:end));
                    handles.Cell_Locs.y{i}=vertcat(handles.Cell_Locs.y{i}(1:r_well-1),...
                        {[]}, handles.Cell_Locs.y{i}(r_well:end));
                end
                
            elseif strcmpi(sel_type,'alt')
                %If you chose to delete a well
                %Deletes the selected well from the handles structure
                %If no well chosen (if you dragged multiple wells)
                if isempty(well_index)
                    release_point=handles.axes_tab(i).CurrentPoint;
                    lastx=release_point(1,1);
                    lasty=release_point(1,2);
                    well_mins=cell2mat(cellfun(@min, handles.BWcol_border{i},...
                        'UniformOutput',0));
                    well_max=cell2mat(cellfun(@max, handles.BWcol_border{i},...
                        'UniformOutput',0));
                    well_index=find(inpolygon(well_mins(:,2),well_mins(:,1),...
                        del_box.XData,del_box.YData) |...
                        inpolygon(well_max(:,2),well_max(:,1),...
                        del_box.XData,del_box.YData) );
                    delete(del_box);
                    
                    if isempty(well_index)
                        set(handles.MasterGUI,'WindowButtonUpFcn',[]);
                        return;
                    end
                    
                end
                handles.BWcol_border{i}(well_index)=[];
                %Deletes the outline plot
                delete([handles.hplot{i}{well_index}]);
                handles.hplot{i}(well_index)=[];
                %Deletes the visibility data
                handles.visibility{i}(well_index)=[];
                if strcmpi(handles.caller,'cellsandsignal')
                    %Delete Cell_location well
                    handles.Cell_Locs.x{i}(well_index)=[];
                    handles.Cell_Locs.y{i}(well_index)=[];
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
                  
                end
            end
            %Updates text
            delete(handles.htext{i});
            %Insert text
            sorted_well_mins=cell2mat(cellfun(@(X) X(find(X(:,2)==min(X(:,2)),1),:), handles.BWcol_border{i},...
                'UniformOutput',0));
            well_nums=num2cell(1:length(handles.BWcol_border{i}))';
            well_nums=cellfun(@num2str, well_nums,'UniformOutput',0);
            if strcmpi(handles.caller,'wells')
                %Make labels with well numbers
                labels=strcat('Well\_',well_nums);
                not_visible=find(handles.visibility{i}==0);
                labels(not_visible)=strcat('Invisible\_',labels(not_visible));
                handles.htext{i}=text(sorted_well_mins(:,2)-60,sorted_well_mins(:,1),labels,'Parent',...
                    handles.axes_tab(i),'Color','r','FontSize',14,'PickableParts','none');
                
            elseif strcmpi(handles.caller,'cellsandsignal')
                %Make labels with well numbers and cell counts
                cell_count=cellfun(@length,handles.Cell_Locs.x{i},'UniformOutput',0);
                cell_count=cellfun(@num2str,cell_count,'UniformOutput',0);
                labels=strcat('Well\_',well_nums,' (', cell_count, ' cells)');
                not_visible=find(handles.visibility{i}==0);
                labels(not_visible)=strcat('Invisible\_',labels(not_visible));
                handles.htext{i}=text(sorted_well_mins(:,2)-80,sorted_well_mins(:,1),labels,'Parent',...
                    handles.axes_tab(i),'Color','r','FontSize',14,'PickableParts','none');
            end
            
            %Change color to green if all wells identified in this
            %column.
            if length(handles.BWcol_border{i})==handles.numWells
                set(handles.htext{i},'Color','g');
                cellfun(@(X) set(X,'Color','g'),handles.hplot{i});
            else
                set(handles.htext{i},'Color','r');
                cellfun(@(X) set(X,'Color','r'),handles.hplot{i});
            end
        else
            disp('Released outside window');
            if strcmpi(sel_type,'normal')
                delete(new_line);
            elseif strcmpi(sel_type,'alt')
                delete(del_box);
            end
            
        end
        set(handles.MasterGUI,'WindowButtonUpFcn',[]);
        guidata(handles.MasterGUI,handles);
        
    end
end