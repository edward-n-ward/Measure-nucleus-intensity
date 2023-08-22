clear all
close all
% Input parameters

maskChannel = 2;
intensityChannel = 1;

pixel_size = 0.076; % image pixel size
min_nucleus_size = 7.6; % minimum expected radius of nucleus in um
max_nucleus_size = 34; % maximum expected radius of nucleus in um


% begin code
[images,path] = uigetfile('*.tif','multiselect','on');
figure(); 

nImgs = length(images); % Determine how many images to process
for ii = 1:nImgs


imPath = fullfile(path,images{ii});

DAPI = double(imread(imPath,maskChannel)); % Read the DAPI channel to maske the measurement
mask = DAPI;
intensity = double(imread(imPath,intensityChannel)); % Read the measured channel


mask = imgaussfilt(mask,4); % Denoise the image
mask = mask-mode(mask(:)); % Subtract the background 
mask(mask<0)=0; % Normailse
mask = mask./max(mask(:));

mask = imbinarize(mask.^1.2); % Increase gamma of image and binarise
mask = imfill(mask, 'holes');

% Erode mask with disk
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
mask = imerode(mask, se);

% Plot intermediate results
subplot (1,3,1)
imagesc(mask); axis square; axis off;
subplot(1,3,2)
imagesc(imadjust(intensity.*mask)); axis off; axis square;
subplot(1,3,3);
imagesc(intensity); colormap hot; axis square; axis off; 
hold on

% Read properties of masked areas
stats = regionprops('table',mask,intensity,{'Centroid','MeanIntensity','MajorAxisLength','MinorAxisLength','Area'});

% Remove masks not corresponding to nuclei 
toDelete = stats.MajorAxisLength > (max_nucleus_size/pixel_size);
stats(toDelete,:) = [];
toDelete = stats.MinorAxisLength < (min_nucleus_size/pixel_size);
stats(toDelete,:) = [];

% Display identified nuclei
plot(stats.Centroid(:,1),stats.Centroid(:,2),'g*');
stats.MajorAxisLength = [];
stats.MinorAxisLength = [];
drawnow
hold off

% Write the nuclei properties to spreadsheet
warning('off','MATLAB:xlswrite:AddSheet'); 
writetable(stats,strcat(path,'results.xlsx'),'Sheet',images{ii}(1:end-4));
end
