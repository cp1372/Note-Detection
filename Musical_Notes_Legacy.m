%%
% Machine Vision Project
%
% Author: Colin Power
% Email: cp1372@mun.ca
% Description: Old code that creates some useful figures.
% Limited to 4/4 with no sharps or flat.

close all
clear all

%filename = 'twinkle.png';
filename = 'twinkle simplified.png';

%filename = 'dog.png';
%filename = 'note types.png';
%filename = 'greyscale notes.png';

%       'average'   averaging filter
%       'disk'      circular averaging filter
%       'gaussian'  Gaussian lowpass filter
%       'laplacian' filter approximating the 2-D Laplacian operator
%       'log'       Laplacian of Gaussian filter
%       'motion'    motion filter
%       'prewitt'   Prewitt horizontal edge-emphasizing filter
%       'sobel'     Sobel horizontal edge-emphasizing filter
%       'unsharp'   unsharp contrast enhancement filter

gx=fspecial('sobel');
gy=gx';


info = imfinfo(filename);
height = info.Width;
width = info.Height;
levels = info.BitDepth;
format = info.Format;
filename = info.Filename;
size = width*height;

input = imread(filename);
imshow(input);

I = rgb2gray(input);
BW1 = 255*uint8(edge(I,'prewitt'));
BW2 = 255*uint8(edge(I,'canny'));
figure, imshow(BW1), title('Prewitt Edge Detection');
figure, imshow(BW2), title('Canny Edge Detection');


w1=fspecial('Average', [5 5]);
I_Ave=imfilter(input, w1);

I_dx=imfilter(input, gx);
I_dy=imfilter(input, gy);

I_dxx=imfilter(I_dx, gx);
I_dyy=imfilter(I_dy, gy);

figure,
    subplot(3,2,1),imshow(input), title('Original');
    subplot(3,2,2),imshow(I_Ave), title('Average Filter');
    subplot(3,2,3), imshow(abs(I_dx)), title('1st Derivative Horizonal Lines');
    subplot(3,2,4), imshow(abs(I_dxx)), title('2nd Derivative Horizonal Lines');
    subplot(3,2,5), imshow(abs(I_dy)), title('1nd Derivative Vertical Lines');
    subplot(3,2,6), imshow(abs(I_dyy)), title('2nd Derivative Vertical Lines');
    
x=input+I_dx+I_dxx;
y=input+I_dy+I_dyy;
xy=input+I_dx+I_dxx+I_dy+I_dyy; %Image with 1st and 2nd order derivatives

w1=fspecial('Average', [2 2]);
xy=imfilter(xy, w1);

edge_detection = I+BW1+BW2;

figure
    subplot(4,1,1), imshow(x), title('Horizonal Lines "Removed"');
    subplot(4,1,2), imshow(y), title('Vertical Lines "Removed"');
    subplot(4,1,3), imshow(xy), title('Both Lines "Removed"');
    subplot(4,1,4), imshow(edge_detection), title('Both Lines "Removed" using Canning and Prewitt"');


I=imread(filename);

% collect horizontal lines
SE=strel('line',30,0);
horizontals = imdilate(I,SE);
horizontals = (255-horizontals);
figure, imshow(horizontals), title('Horizontal Lines');

% collect vertical lines
SE=strel('line',10,90);
verticals = imdilate(I,SE);
verticals = 255-verticals;
figure, imshow(verticals), title('Vertical Lines');

SE=strel('disk',4);
dots = imdilate(I, SE);
dots = dots + verticals;
dots = imerode(dots, SE);
dots = (255-dots);
dots = imdilate(dots, SE);
dots = dots > 10; %%Non-circular elements will have smaller values. Threshold then out
figure, imshow(dots), title('Dots');


dilate = imdilate(I,SE);
erode = imerode(I,SE);
opened = imopen(I,SE);
closed = imclose(I,SE);


[L,num]=bwlabel(dots, 8);

dataset=regionprops(L);

areas = cat(2, dataset(:).Area); 
mean_area = mean(areas);

centroids = cat(2, dataset(:).Centroid); 

indices = find(areas>1.30*mean_area);
largeBlobs = dataset(indices);

RGB=label2rgb(L);

figure, imshow(RGB);

%Plot the centroids
Z = zeros(709,1188);
for n=1:num
    if (dataset(n).Area < 1.50*mean_area && dataset(n).Area > 0.5*mean_area)
        i=round( dataset(n).Centroid(1) );
        k=round( dataset(n).Centroid(2) );
        Z(k,i)=1;
    end
end



% figure
    subplot(1,2,1), imshow(RGB), title('Blobs');
    subplot(1,2,2), imshow(Z), title('Centroids');

[notes, num]=bwlabel(Z, 8);
notes_dataset=regionprops(notes);
delta_time = zeros(num-1,1);
delta_pitch = zeros(num,1);

%base_pitch;
%end_duration;

for n=1:num-1
    X1=notes_dataset(n).Centroid(1);
    X2=notes_dataset(n+1).Centroid(1);  
    Y1=notes_dataset(n).Centroid(2);
    Y2=notes_dataset(n+1).Centroid(2);

    delta_time(n) = X2-X1;
    delta_pitch(n) = Y2-Y1;
end

Z=label2rgb(Z);
figure, imshow(255-Z), title('Centroids');
%dataset(14,1).Centroid, dataset(14,1).BoundingBox

figure, imshow(dilate), title('Dilated');
figure, imshow(erode), title('Eroded');
figure, imshow(opened), title('Opened');
figure, imshow(closed), title('Closed');

figure
    subplot(1,3,1), imshow(dilate), title('Dilated');
    subplot(1,3,2), imshow(erode), title('Eroded');
    subplot(1,3,3), imshow(opened), title('Opened');

closed = imclose(I,SE);
figure, imshow(IE), title('closed image');


