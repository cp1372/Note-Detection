%%
% Machine Vision Project
%
% Author: Colin Power
% Email: cp1372@mun.ca
% 
% Script for slicing an image into evenly segmented strips
% Select a bar of sheet music and half the whitespace to the closest lines
% above and below to evenly segment the sheet music.

clear all
close all
I=imread('twinkle.png');
info = imfinfo('twinkle.png');

X = info.Height;
Y = info.Width;
area = X*Y;

I=rgb2gray(I);
figure, imshow(I);
T=imcrop(I);
pause;

[x,y]=size(T);
segments=round(X/x);

for (n=0:segments-1)
    %imcrop uses spatial dimensions which differ from pixel dimensions
    %IS = imcrop(I, [1, x*n, Y, x] );
    IS = imcrop(I, [y, x*n, Y, x] );
    figure, imshow(IS);
end
