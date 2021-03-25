clc
clear all
close all

q1 = 16;                                                        % Uniform quantization step size
func(q1);

clear all

q2 = 32;                                                        % Uniform quantization step size
func(q2);

function func(q)
    global quantsubs;                                           % All quantized subblocks (used for part2)
    img_orig= imread("lena512.bmp");                            % Read image
    row = size(img_orig,1);                                     % Row number of img
    col = size(img_orig,2);                                     % Col number of img
    reconstructed_img = zeros(row,col);                         % Preallocate
    sub_no=1;                                                   % Subblock number
    for r=1:8:row                                               % For each 8 row
        for c=1:8:col                                           % For each 8 col
            sub = img_orig(r:r+7,c:c+7);                        % 8x8 subblocks    
            dctcoefs = dct2(sub);                               % DCT coefficients
            quant=round(dctcoefs/q)*q;                          % Uniform quantization with step size q
            quantsubs(:,:,sub_no) = quant;
            sub_no = sub_no+1;                                  
            invdct = idct2(quant);                              % Inverse of DCT
            reconstructed_img(r:r+7, c:c+7) = invdct();         % Combine sub blocks
        end
    end
    reconstructed_img = uint8(reconstructed_img);               % Convert double to int
    figure
    imshowpair(img_orig,reconstructed_img,"montage");           % Combining the original image and reconstructed image next to each other
    title("Original Image (Left) and Reconstructed DCT Image (Right) with " + q + " step size ");

    peaksnr = psnr(reconstructed_img,img_orig);                 % Calculate psnr between images
    fprintf('\n The PSNR value is %0.4f \n', peaksnr);

    error_img = img_orig - reconstructed_img;                   % Error image
    error_img = rescale(error_img);
    figure
    imshow(error_img);
    title("Error Image with " + q + " step size");


    % The quality of the reconstructed image was close to the original image.
    % There was some blocking artifact on the image. When we increase the step
    % size this will became more clear to see, As a result the dct
    % algortihm is an effective algorithm to compress an image without losing
    % not very much quality.

    global x;                                                               % row index
    global y;                                                               % col index
    global ac_no;                                                           % current AC coefficient number
    global run_len_no;                                                      % run length number until nonzero AC coefficient
    global run_value_pairs;                                                 % (run-length,value) pairs

    for i=1:size(quantsubs,3)                                               % For all quantized subblocks
        x=1; y=1;
        ac_no = 1;
        run_len_no = 0;
        matrow = size(quant,1);
        matcol = size(quant,2);
                                                                            % Zig zag scanning
        y=y+1;                                                              % Starting point, go right
        while true                                                          % Visit all index
            while true                                                      % Go down-left until there is no left (or) no bottom
                is_value(i)
                if(y-1)~=0 && (x+1)~=(matrow+1) 
                    x=x+1; y=y-1;                                           % Go down-left
                else
                    break;
                end
            end

            if (x+1)~=(matrow+1)                                            % Go down, if there is no down go right
                x=x+1;
            else
                y=y+1;
                if(x==matrow && y==matcol)                                  % If it is last index stop
                    is_value(i);
                    break;
                end
            end

            while true                                                      % Go up-right until there is no up (or) no right
                is_value(i)
                if (y+1)~=(matcol+1) && (x-1)~=0 
                    x=x-1; y=y+1;
                else
                    break;
                end
            end

            if (y+1)~=(matcol+1)                                            % Go right if there is no right go down                    
                y=y+1;
            else
                x=x+1;
            end
        end
    end

    global histogram;                                                       % histogram of (run-length,value) pair
    hist_size = 1;       
    for i=1:size(run_value_pairs.value,1)                                   % For all (run-length,value) pairs
        for j=1:size(run_value_pairs.value,2)
            r=run_value_pairs.run_len(i,j);
            v=run_value_pairs.value(i,j);
            if v==0                                                         
                break;
            end

            if find(r,v)==-1                                                % If (run-length,value) pair not found add to histogram
                histogram(hist_size).run_len = r;                           % Add run-length to histogram
                histogram(hist_size).value = v;                             % Add value to histogram
                histogram(hist_size).freq = 1;                              % Start with 1 frequency
                hist_size = hist_size + 1;                                  % Increase histogram size by one
            else
               index = find(r,v);                                           % If (run-length,value) pair found increase its frequency
               histogram(index).freq = histogram(index).freq + 1;           
            end

        end
    end

    hist_size = size(histogram,2);                                          % Final histogram size

    total_freq = 0;
    for i=1:hist_size
        total_freq = total_freq + histogram(i).freq;                        % Total frequency 
    end
    eob = size(quantsubs,3);                                                % eob = subblocks number
    total_freq = total_freq + eob;                                          % Added eob frequency to total frequncy

    for i=1:hist_size
        histogram(i).probability = histogram(i).freq/total_freq;            % Calculate the probability of pairs or symbols.
    end

    entropy = 0;
    for i=1:hist_size
    entropy = entropy + -1*histogram(i).probability*log2(histogram(i).probability);           % Calculate entropy
    end
    eob_prob = eob/total_freq;
    entropy = entropy + -1*(eob_prob)*log2(eob_prob);                                         % eob symbol added to entropy

    estimated_bitrate = entropy*(hist_size +  1);                                             % Estimated bitrate = entropy*(histogram size or symbol size + eob) 
    fprintf("\n Estimated bitrate is " + estimated_bitrate + "\n");
end
function is_value(i)                                                % Checks whether it is AC value or not if it is AC value add the pairs
    global x;                                                       % row index
    global y;                                                       % col index
    global ac_no;                                                   % current AC coefficient number
    global run_len_no;                                              % run length number until nonzero AC coefficient
    global run_value_pairs;                                         % (run-length,value) pairs
    global quantsubs;                                               % All quantized subblocks
    if  quantsubs(x,y,i)~=0                                         % If the AC value is not zero
        run_value_pairs.value(i,ac_no) = quantsubs(x,y,i);          % Add value
        run_value_pairs.run_len(i,ac_no) = run_len_no;              % Add run-length
        ac_no = ac_no + 1;                                          % Increase the size of the non-zero AC value
        run_len_no = 0;                                             % Reset the length of zeros
    else
       run_len_no=run_len_no+1;                                     % If the AC value is zero then increase the length of zeros
    end
end   

function output = find(r,v)                                         % Search the given run-length, value pair in the histogram

    global histogram;

    try                                                             % If histogram empty not found
        size(histogram,2);  
    catch
        output = -1;
        return
    end
    for i=1:size(histogram,2)                                           
        if histogram(i).value == v && histogram(i).run_len == r     % Return index if it is found
            output = i;
            return;
        end
    end
    output = -1;                                                    % Return -1 meaning not found

end

% When we increase the q step size the PSNR value is decreasing this is
% because the quality decreases so reconstructed image is less similar to
% original image and for the estimated bitrate, it is also decreasing this
% is because we get rid of more coefficients because of that we have less
% symbols. Hence the entropy decreases and also bitrate is decreasing.

% The value of q step size depend on the application. If you want low
% quality images and low memory size you can select a higher q step size
% but if you want good looking quality and medium memory then you can
% select the q step size at medium values.
