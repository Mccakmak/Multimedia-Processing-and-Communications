clc
clear all
close all

img_orig= imread("lena512.bmp"); % Read image
imshow(img_orig);                 % Show image
title("Original Image");

img_scaled = double(img_orig) / 256;   % Pixels are scaled between 0 and 1

row = size(img_scaled,1);           % row number of img
col = size(img_scaled,2);           % col number of img

for x=1:row                         % For all row
    for y=1:col                     % For all column
        if(img_scaled(x,y) <0.5)  
            img_thresh=0;         %Below 0.5 is replaced 0
        else
            
            img_thresh=1;         %Above 0.5 is replaced 1
        end     
        pixel_error = img_scaled(x,y) - img_thresh; % Error computed between pixels
        img_scaled(x,y) = img_thresh;               % 1 bit given
        
        %if x,y is at the bottom skip left-bottom, bottom, right-bottom propagation
        if x==row && y~=col
          img_scaled(x,y+1) = img_scaled(x,y+1) + (5/16)*pixel_error;          % do right propagation
          
        %if x,y is at the left skip left-bottom propagation
        elseif y==1
          img_scaled(x,y+1) = img_scaled(x,y+1) + (5/16)*pixel_error;        % do right, bottom, bottom-right propagation
          img_scaled(x+1,y) = img_scaled(x+1,y) + (7/16)*pixel_error;
          img_scaled(x+1,y+1) = img_scaled(x+1,y+1) + (1/16)*pixel_error;
          
        %if x,y is at the right skip right, right-bottom propagation
        elseif y==col && x~=row
          img_scaled(x+1,y-1) = img_scaled(x+1,y-1) + (3/16)*pixel_error;          % do left-bottom, bottom propagation
          img_scaled(x+1,y) = img_scaled(x+1,y) + (7/16)*pixel_error;
        else
            if(x~=row && y~=col)                                                          % skip all propagation for bottom right pixel
                img_scaled(x,y+1) = img_scaled(x,y+1) + (5/16)*pixel_error;
                img_scaled(x+1,y-1) = img_scaled(x+1,y-1) + (3/16)*pixel_error;
                img_scaled(x+1,y) = img_scaled(x+1,y) + (7/16)*pixel_error;
                img_scaled(x+1,y+1) = img_scaled(x+1,y+1) + (1/16)*pixel_error; 
            end
        end
    end
end

figure
imshow(img_scaled);                                            % Show the dithered image
title("Dithered Image");


img_scaled = double(img_orig) / 256;                           % Pixels are scaled between 0 and 1
img_no_dither= zeros(row,col);
for x=1:row                         % For all row
    for y=1:col                     % For all column
        if(img_scaled(x,y) <0.5)  
            img_no_dither(x,y)=0;         %Below 0.5 is replaced 0
        else
            img_no_dither(x,y)=1;         %Above 0.5 is replaced 1
        end     
    end
end
figure
imshow(img_no_dither);
title("No Dithered Image");


% The quality of the dithered image close to the original one but 
% it is a little bit noisy, we use only black and white dots for 
% the dithered image so it is 1 bit and when we compare with 8 bit original
% image it is very close to original image quality.

%The idea behind error diffusion is to compute the error caused by thresholding
%a given pixel and propagate it to neighbour pixels, in order to compensate 
%for the average intensity loss or gain.
