function cell_locations(handles)
%Get CellProfiler File
[cpname, cppath]= uigetfile('*.mat',...
    'Choose Cell Profiler file', handles.output.filepath);
if isequal(cpname,0) || isequal(cppath,0)
    disp('User pressed cancel')
else
    h=waitbar(0,'Importing CellProfiler Data...','WindowStyle','modal');
    CPstruct=load([cppath cpname]);
    
    x_locations=cellfun(@round,CPstruct.handles.Measurements.Cells.Location_Center_X,...
        'UniformOutput',0);
    y_locations=cellfun(@round,CPstruct.handles.Measurements.Cells.Location_Center_Y,...
        'UniformOutput',0);
    column_number=str2double(CPstruct.handles.Measurements.Image.Metadata_Column);
    cut_number=str2double(CPstruct.handles.Measurements.Image.Metadata_Cut);
    
    %Preallocate variables
    numImages=length(x_locations);
    %%%%%%%%CHANGE THIS FOR DIFFERENT NUMBER OF WELLS%%%%%%%%%%%%
    numWells=handles.output.numWells;
    cell_locs_x=cell(1,14);
    cell_locs_x=cellfun(@(X) cell(numWells,1),cell_locs_x,'UniformOutput',0);
    cell_locs_y=cell_locs_x;

    
    for i=1:numImages;
        waitbar(i/numImages,h,'Importing CellProfiler Data...');
        %Offset by original cut number
        cut=cut_number(i); c=column_number(i);
        y_locations{i}=y_locations{i}+...
            handles.output.cut_locations{c}(cut,1)-1;
        %Look through each well to locate what cells are in what well. Logical
        %indexing for each cell iterated through all wells.
        allwells_check=cellfun(@(X) inpolygon(x_locations{i},y_locations{i},...
            X(:,2),X(:,1)),handles.output.well_borders{c},'UniformOutput',0);
        %Locate the cell index (from CP analysis) in each well
        cells_in_wells=cellfun(@find,allwells_check,'UniformOutput',0);
        %Locate the indexes of the wells that have at least one cell in them
        %(not empty).
        positive_wells=find(~cellfun(@isempty,cells_in_wells));
        %Transfer the location of the identified cells to their corresponding
        %wells in the cell_locs cell array
        cell_locs_x{c}(positive_wells)=cellfun(@(X) x_locations{i}(X),...
            cells_in_wells(positive_wells),'UniformOutput',0);
        cell_locs_y{c}(positive_wells)=cellfun(@(X) y_locations{i}(X),...
            cells_in_wells(positive_wells),'UniformOutput',0);
        
        
    end
    
    
    waitbar(0.99,h,'Saving Data...');
    handles.output.Cell_Locs.x=cell_locs_x;
    handles.output.Cell_Locs.y=cell_locs_y;
    handles.output.import_CP_push_count=1;
    
    %Re-set the buttons and the push count for cells
    handles.Import_CP_push.String='Re-Import CellProfiler Data';
    handles.Edit_cells_push.Enable='on';
    
    %Update handles structure
    guidata(handles.Load_fig, handles);
    %Save the main file
    save([handles.output.filepath ...
        handles.output.filename],'-struct','handles','output')
    delete(h)
    
end

end



