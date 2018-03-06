function cell_locs=detect_cells(datahandle,I,Mask) 
%I and Mask only passed on cut images.


%% Reading file if large image
% handles=guidata(datahandle);
% 
% 
% [imgname, imgpath]= uigetfile('.tif','Choose Oblique Image',...
%     handles.output.darkfield_imgpath);
% handles.output.oblique_imgname=imgname;
% handles.output.oblique_imgpath=imgpath;
close all
h2w=waitbar(0.1,'Loading Image...','WindowStyle','modal');
% I=im2uint8(imread([imgpath imgname]));

%% Background correct
% waitbar(0.15,h2w,'Background Correction...');
% tic
% Ic=imadjust(I,stretchlim(I,0));
% background=imopen(I,strel('disk',50));
% I2=I-background;
% I3=imadjust(I2,stretchlim(I2,0));
% fprintf('%.2f seconds for background correction\n',toc);

%% Edge Detection
waitbar(0.2,h2w,'Edge Detection...');
tic
[BW_sobel,threshso]=edge(I3,'sobel');
% [BW_canny, threshca]=edge(I3,'canny');

BW_sobel2=edge(I3,'sobel',threshso*0.85);
% BW_canny2=edge(I3,'canny',threshca*0.7);

fprintf('%.2f seconds for edge detection\n',toc);


%% Masking
waitbar(0.5,h2w,'Clearing areas outside of wells');
tic
BW_sobel(~Mask)=0;
% BW_canny(~Mask)=0;

BW_sobel2(~Mask)=0;
% BW_canny2(~Mask)=0;

fprintf('%.2f seconds for masking\n',toc);

%% Dilating
% waitbar(0.7,h2w,'Dilating lines');
% tic
% se90 = strel('line', 2, 90);
% se0 = strel('line', 2, 0);
% BW_sobeld=imdilate(BW_sobel,[se90 se0]);
% % BW_cannym=imdilate(BW_cannym,se1);
% 
% BW_sobel2d=imdilate(BW_sobel2,se1);
% % BW_canny2m=imdilate(BW_canny2m,se1);
% 
% fprintf('%.2f seconds for dilating\n',toc);

%% Closing
waitbar(0.6,h2w,'Closing lines');
tic
BW_sobelc=bwmorph(BW_sobel,'close',Inf);
% BW_cannym=bwmorph(BW_canny,'close',Inf);

BW_sobel2c=bwmorph(BW_sobel2,'close',Inf);
% BW_canny2m=bwmorph(BW_canny2,'close',Inf);

fprintf('%.2f seconds for closing\n',toc);



%% Filling Holes
waitbar(0.8,h2w,'Filling holes');
tic
BW_sobelf=imfill(BW_sobelc,'holes');
% BW_cannym=imfill(BW_cannym,'holes');

BW_sobel2f=imfill(BW_sobel2c,'holes');
% BW_canny2m=imfill(BW_canny2m,'holes');

fprintf('%.2f seconds for filling\n',toc);

%% Size filter
waitbar(0.9,h2w,'Opening');
tic
min_cell_radius=10; %minimum cell radius
max_cell_radius=25;
mic_resolution=1.60; %(micron per pixel);
min_radius=min_cell_radius/mic_resolution;
max_radius=max_cell_radius/mic_resolution;%transform to pixels
min_area=round((min_radius/2)^2 * pi);
max_area=round((max_radius/2)^2 * pi);
BW_sobels=bwareafilt(BW_sobelf,[min_area max_area]);
% BW_cannym=bwareaopen(BW_cannym,min_area);
BW_sobel2s=bwareafilt(BW_sobel2f,[min_area max_area]);
% BW_sobel2s=bwareaopen(BW_sobel2f,min_area);
% BW_canny2m=bwareaopen(BW_canny2m,min_area);

fprintf('%.2f seconds for opening\n',toc);

%% Property filter
waitbar(0.95,h2w,'Property Filter');
tic

BW_sobelfs=bwpropfilt(BW_sobels,'Solidity',[0.4 1]);
BW_sobelfe=bwpropfilt(BW_sobelfs,'Eccentricity', [0 0.88]);

% BW_cannym=bwpropfilt(BW_cannym,'Eccentricity', [0 0.88]);
% BW_cannym=bwpropfilt(BW_cannym,'Solidity',[0.4 1]);


BW_sobel2fs=bwpropfilt(BW_sobel2s,'Solidity',[0.4 1]);
BW_sobel2fe=bwpropfilt(BW_sobel2fs,'Eccentricity', [0 0.88]);

% BW_canny2m=bwpropfilt(BW_canny2m,'Eccentricity', [0 0.88]);
% BW_canny2m=bwpropfilt(BW_canny2m,'Solidity',[0.4 1]);

fprintf('%.2f seconds for property filtering\n',toc);

delete(h2w);

%% Plot outlines
close all
BW_outlines=bwperim(BW_sobelfe);
Segout=Ic;
Segout(BW_outlines)=255;
f1=figure('Name','Original Image');
uip1=uipanel; h1=axes('Parent',uip1);
im1=imshow(Segout,'Parent',h1);
hSp1=imscrollpanel(uip1,im1);

%% Scroll Panels!
close all
% Make IMscrollpnales
f1=figure('Name','Original Image');
uip1=uipanel; h1=axes('Parent',uip1);
im1=imshow(Ic,'Parent',h1); 

f2=figure('Name','Close'); 
uip2=uipanel; h2=axes('Parent',uip2);
im2=imshow(BW_sobelc,'Parent',h2);

f3=figure('Name','Fill'); 
uip3=uipanel; h3=axes('Parent',uip3);
im3=imshow(BW_sobelf,'Parent',h3); 

f4=figure('Name','Size');
uip4=uipanel; h4=axes('Parent',uip4);
im4=imshow(BW_sobels,'Parent',h4);

f5=figure('Name','Filter Solidity'); 
uip5=uipanel; h5=axes('Parent',uip5);
im5=imshow(BW_sobelfs,'Parent',h5);

f6=figure('Name','Filter Eccentricity'); 
uip6=uipanel; h6=axes('Parent',uip6);
im6=imshow(BW_sobelfe,'Parent',h6);

hSp1=imscrollpanel(uip1,im1);
hSp2=imscrollpanel(uip2,im2);
hSp3=imscrollpanel(uip3,im3);
hSp4=imscrollpanel(uip4,im4);
hSp5=imscrollpanel(uip5,im5);
hSp6=imscrollpanel(uip6,im6);
%Set positions
set(f1,'Units','normalized','OuterPosition',[0 1/2 1/2 1/2]);
set(f2,'Units','normalized','OuterPosition',[0 0 1/2 1/2]);
set(f3,'Units','normalized','OuterPosition',[1/2 1/2 1/2 1/2]);
set(f4,'Units','normalized','OuterPosition',[1/2 0 1/2 1/2]);
set(f5,'Units','normalized','OuterPosition',[1/2 1/2 1/2 1/2]);
set(f6,'Units','normalized','OuterPosition',[1/2 0 1/2 1/2]);
% Get APIs from the scroll panels 
api1 = iptgetapi(hSp1);
api2 = iptgetapi(hSp2);
api3 = iptgetapi(hSp3);
api4 = iptgetapi(hSp4);
api5 = iptgetapi(hSp5);
api6 = iptgetapi(hSp6);
% Synchronize left and right scroll panels
api2.setMagnification(1.5);
api1.setMagnification(api2.getMagnification())
api1.setVisibleLocation(api2.getVisibleLocation())
api3.setMagnification(api2.getMagnification())
api3.setVisibleLocation(api2.getVisibleLocation())
api4.setMagnification(api2.getMagnification())
api4.setVisibleLocation(api2.getVisibleLocation()) 
api5.setMagnification(api2.getMagnification())
api5.setVisibleLocation(api2.getVisibleLocation())
api6.setMagnification(api2.getMagnification())
api6.setVisibleLocation(api2.getVisibleLocation())
% When magnification changes on left scroll panel, 
% tell right scroll panel
api1.addNewMagnificationCallback(api2.setMagnification);
api1.addNewMagnificationCallback(api3.setMagnification);
api1.addNewMagnificationCallback(api4.setMagnification);
api1.addNewMagnificationCallback(api5.setMagnification);
api1.addNewMagnificationCallback(api6.setMagnification);
% When magnification changes on right scroll panel, 
% tell left scroll panel
api2.addNewMagnificationCallback(api1.setMagnification);
api2.addNewMagnificationCallback(api3.setMagnification);
% When location changes on left scroll panel, 
% tell right scroll panel
api1.addNewLocationCallback(api2.setVisibleLocation);
api1.addNewLocationCallback(api3.setVisibleLocation);
api1.addNewLocationCallback(api4.setVisibleLocation);
api1.addNewLocationCallback(api5.setVisibleLocation);
api1.addNewLocationCallback(api6.setVisibleLocation);
% When location changes on right scroll panel, 
% tell left scroll panel
api2.addNewLocationCallback(api1.setVisibleLocation);
api2.addNewLocationCallback(api3.setVisibleLocation);

%% Normal plotting
% close all; 
% monitor_pos=get(0,'MonitorPositions');
% num_monitors=size(monitor_pos);
% if num_monitors(1)==1
%     fig_pos1=monitor_pos;
%     fig_pos1(3)=fig_pos1(3)/2;
%     fig_pos2=fig_pos1;
%     fig_pos2(1)=fig_pos2(3)+1;
% elseif num_monitors(1)==2;
%     fig_pos=monitor_pos(2,:);
%     
% end
% close all;
% figure('Position',fig_pos2);
% h1=subplot(2,2,2); imshow(BW_sobelm), title('Sobel final');
% h2=subplot(2,2,4); imshow(BW_cannym), title('Canny final');
% 
% h3=subplot(2,2,2); imshow(BW_sobel2m), title('Sobel2 final');
% h4=subplot(2,2,4); imshow(BW_canny2m), title('Canny2 final');
% 
% figure('Position',fig_pos1); 
% h5=subplot(1,2,1); imshow(Ic); title('Oblique');
% h6=subplot(1,2,2); imshow(I3); title('Oblique Background Corrected');
% 
% figure('Position',fig_pos2);
% h7=subplot(2,2,1); imshow(BW_sobel), title('Sobel');
% h8=subplot(2,2,3); imshow(BW_canny), title('Canny');
% 
% h9=subplot(2,2,2); imshow(BW_sobel2), title('Sobel2');
% h10=subplot(2,2,4); imshow(BW_canny2), title('Canny2');
% 
% 
% % figure;
% % h7=subplot(2,2,1); imshow(BW_sobeldil), title('Sobel dilated');
% % h8=subplot(2,2,3); imshow(BW_cannydil), title('Canny dilated');
% % 
% % h9=subplot(2,2,2); imshow(BW_sobel2dil), title('Sobel2 dilated');
% % h10=subplot(2,2,4); imshow(BW_canny2dil), title('Canny2 dilated');
% linkaxes([h1 h2 h3 h4 h5 h6 h7 h8 h9 h10]);


end

