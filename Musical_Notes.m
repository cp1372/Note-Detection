%%
% Machine Vision Project
%
% Author: Colin Power
% Email: cp1372@mun.ca
% Description: Main script used to convert simple sheet music
% into a MIDI file.
% Limited to 4/4 with no sharps or flat.

% REMEMBER TO ADD matlab-midi-master AND SUBFOLDERS TO PROJECT PATH
close all
clear all

%Best 3 test cases
%filename = 'twinkle simplified.png';
%filename = 'self made2.png';
filename = 'C Major.png';

%filename = 'twinkle long.png';
%filename = 'dog simplified.png';
%filename = 'note types.png';
%filename = 'greyscale notes.png';
%filename = 'Blacksheep.png';
%filename = 'ode to joy.png';
%filename = 'prelude.png';
%filename = 'self made.png';

info = imfinfo(filename);
height = info.Width;
width = info.Height;
size = width*height;

input = imread(filename);
I = rgb2gray(input);

% T=imcrop(I);
% pause;
% figure, imshow(T);

% Collect horizontal lines
SE=strel('line', 30, 0);
horizontals = imdilate(I, SE);
horizontals = (255-horizontals) > 100;
figure,
    imshow(horizontals), 
    title('Horizontal Lines','fontweight','bold', 'fontsize', 14), 
    xlabel(filename,'fontweight', 'bold', 'fontsize', 14);

% Collect vertical lines
SE=strel('line', 10, 90); %10 usually works well
verticals = imdilate(I, SE);
verticals = 255-verticals;
figure, 
    imshow(verticals), 
    title('Vertical Lines', 'fontweight', 'bold', 'fontsize', 14), 
    xlabel(filename, 'fontweight', 'bold', 'fontsize', 14);

% Isolate the notes
SE=strel('disk', 2); %2 for C major 4 for twinkle
dots = imdilate(I, SE);
dots = dots + verticals;

dots = imerode(dots, SE);
dots = (255-dots);

dots = imdilate(dots, SE);
dots = dots > 10; %%Non-circular elements will have smaller values. Threshold them out

figure,
    imshow(dots), 
    title('Isolated Dots', 'fontweight', 'bold', 'fontsize', 14), 
    xlabel(filename, 'fontweight', 'bold', 'fontsize', 14);

% Set of morpological operators for testing
% dilate = imdilate(I,SE);
% erode = imerode(I,SE);
% opened = imopen(I,SE);
% closed = imclose(I,SE);
% 
% figure, imshow(dilate), title('Dilated');
% figure, imshow(erode), title('Eroded');
% figure, imshow(opened), title('Opened');
% figure, imshow(closed), title('Closed');

%Collect blobs for the isolated dots
[L, num] = bwlabel(dots, 8);
dataset = regionprops(L);
areas = [dataset(:).Area];
mean_area = mean(areas);
median_area = median(areas);

RGB = label2rgb(L);
figure, 
    imshow(RGB),
    title('Labeled Blobs', 'fontweight', 'bold', 'fontsize', 14),
    xlabel(filename, 'fontweight', 'bold', 'fontsize', 14);

%Plot the valid centroids
centroids = zeros(width, height);
for n=1:num
    if ( (dataset(n).Area < 1.3*median_area) && (dataset(n).Area > 0.7*median_area) )
        i=round( dataset(n).Centroid(1) );
        k=round( dataset(n).Centroid(2) );
        centroids(k,i) =  1;
    end
end

% Code to remove blobs based upon their areas. Might be useful.
% BW = L;
% BW2 = bwareaopen(BW, round(median_area));
% figure, imshow(BW2);
% Replace all values in A that are greater than 10 with the number 10.
% A(A>10) = 10
    
%Isolate the centroid pixels
[notes, num] = bwlabel(centroids, 8);
notes_dataset = regionprops(notes);
delta_time = zeros(num-1, 1);
delta_pitch = zeros(num-1, 1);

Z=label2rgb(centroids); %Used to plot centroids against black background
figure, 
    imshow(input), 
    title('Original', 'fontweight', 'bold', 'fontsize', 14),
    xlabel(filename, 'fontweight', 'bold', 'fontsize', 14);
figure, 
    imshow(255-Z), 
    title('Centroids', 'fontweight', 'bold', 'fontsize', 14), 
    xlabel(filename, 'fontweight', 'bold', 'fontsize', 14);
    
%Find the differences between each centroid in both dimensions
for n=1:num-1
    X1=notes_dataset(n).Centroid(1);
    X2=notes_dataset(n+1).Centroid(1);  
    Y1=notes_dataset(n).Centroid(2);
    Y2=notes_dataset(n+1).Centroid(2);
    delta_time(n) = X2-X1;
    delta_pitch(n) = Y2-Y1;
end

%base_pitch = 55; %G use for Twinkle
base_pitch = 60; %C use for C Major

end_length = 2; %Set to length of final note

 %The notes should be spaced in some ratio with respect to the smallest non-zero change
norm_delta_time = (delta_time / min(delta_time) );
quantLevels = [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0]; %Levels can be extended past 6.0 if needed.
quantTime = interp1(quantLevels, quantLevels, norm_delta_time, 'nearest');
%Values near 1.5 indicate section breaks so remove by taking the floor.
norm_delta_time = floor(quantTime);


quantPitches = round(-10*normc(delta_pitch) ) / 10.0 ; %Round to nearest 0.1
a = abs(quantPitches) ; %Remove negative values
b = a(a~=0); %Remove zero pitch shifts

ratio = max(b)/min(b); %Find ratio of smallest change and 1. Works for Twinkle
if (ratio == 1)
    ratio = 1/min(b); %Find ratio of smallest change and 1. Works for C major scale
end
norm_delta_pitch = round(ratio*quantPitches);
backup_pitches = norm_delta_pitch;

%Create summation vectors
for i=2:n
    norm_delta_time(i) = norm_delta_time(i) + norm_delta_time(i-1);
    norm_delta_pitch(i) = norm_delta_pitch(i) + norm_delta_pitch(i-1);
end

norm_delta_time = norm_delta_time-norm_delta_time(1); %%Shift everything so it starts at time 0.
norm_delta_time = [norm_delta_time; end_length+max(norm_delta_time) ]; %Cannot calculate the final note length so we must do it manually


norm_delta_pitch=base_pitch+norm_delta_pitch; %But everything relative to the 1st note value

%Error correction to filter out any sharp/flat notes.
%Resrach details of MIDI notes for more detail.
error_notes = [1:12:121; 3:12:123; 6:12:126; 8:12:128; 10:12:132]';
error_table = ismember(norm_delta_pitch, error_notes);
for m=1:length(norm_delta_pitch)
   if (error_table(m) == true)
       if (backup_pitches(m) < 0) 
           norm_delta_pitch(m)=norm_delta_pitch(m)-1;
       else
           norm_delta_pitch(m)=norm_delta_pitch(m)+1;
       end
   end
end
norm_delta_pitch=[base_pitch;norm_delta_pitch]; %Need to set 1st note pitch manually

%Create the midi file using the M matrix
M = zeros(n+1, 6);
M(:,1) = 1;                    % all in track 1
M(:,2) = 1;                    % all in channel 1
M(:,3) = norm_delta_pitch;     % note numbers: one ocatave starting at middle C (60)
M(:,4) = 50;                   % volume level
M(:,5) = norm_delta_time;      % note on: notes start at every delta time
M(:,6) = [M(2:n+1, 5); M(n+1, 5)+end_length]; %note off: notes end at the next delta time

new_midi = matrix2midi(M);
writemidi(new_midi, 'output.mid');
Fs = 44160;

y = midi2audio('output.mid', Fs, 'sine');
soundsc(y,Fs);