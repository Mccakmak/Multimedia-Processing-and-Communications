clc
clear all
close all

orig_input = [1 1 1 0  1 1 0 1  1 1 0 1  1 1 1 0  1 1 0 1  1 1 0 1  1 1 1 0  1 1 0 1]; 
gen_poly1 = [1 0 1 0 1]; 
gen_poly2 = [1 1 0 0  0 1 0 1]; 

error_bit_2 = 2;
error_bit_4 = 4;

main(orig_input, gen_poly1, error_bit_2);
main(orig_input, gen_poly1, error_bit_4);
main(orig_input, gen_poly2, error_bit_2);
main(orig_input, gen_poly2, error_bit_4);

function main(orig_input, gen_poly, error_bit)

    global current_input_bit;                                             
                      
    input = orig_input;                                                     % input signal bitwise
    last_bit = length(input);                                               % last_bit index number
    
    gen_poly_len = length(gen_poly);                                        % bit length of the generator polynomial

    for i=1:gen_poly_len-1                                                  % add zeros to the input as nth order
        input(last_bit + 1) = 0;
        last_bit = last_bit + 1;
    end

    current_input_bit = gen_poly_len;
    sub_input=input(1:gen_poly_len);                                        % take sub input which is equal to the generator polynomial length

    res = divide(sub_input, gen_poly, input);    
    
    orig_trans = cat(2,orig_input,res);                                     % concanate the remainder to the input
    trans_len = length(orig_trans);

    error_no = 0;                                                           
    test_size = 10000;                                                      % testing the error detection of generator polynomial
    for i=1:test_size
        res = create_error_messages(orig_trans, trans_len, gen_poly, gen_poly_len, error_bit);
        error = check_error(res);

        if error == 1
            error_no = error_no+1;
        end
    end

    error_rate = (error_no/test_size * 100);
    error_miss = 100-(error_no/test_size * 100);
    disp("Generator polynomial: ");
    disp(gen_poly);
    disp("Error bit: " + error_bit);
    disp(error_rate + "% error found " + error_miss + "% error missed" );
                                                              
    error_gen_poly = gen_poly;                                              % undetected error input generation                        
    error_gen_poly(gen_poly_len+1) = 0;
    shifted = zeros(1,length(orig_trans)-length(error_gen_poly));
    error_input = bitxor(orig_trans,cat(2,shifted,error_gen_poly));

    current_input_bit = gen_poly_len;
    sub_error=error_input(1:gen_poly_len); 
    res = divide(sub_error,gen_poly,error_input);
end

function res = create_error_messages(orig_trans, trans_len, gen_poly, gen_poly_len, error_bit)
    
    global current_input_bit

    trans = add_error(orig_trans,trans_len,error_bit);                      % add bit error

    sub_trans=trans(1:gen_poly_len);                                        % take sub trans which is equal to the generator polynomial length

    current_input_bit = gen_poly_len;

    res = divide(sub_trans, gen_poly, trans);
end

function out = check_error(res)
    if mean(res) ~= 0                                                       % if mean error not zero there is error
        out = 1;
    else
        out = 0;
    end    
end

function res = divide(sub_input, gen_poly, input)

global current_input_bit;
gen_poly_len = length(gen_poly);

res=sub_divide(sub_input, gen_poly, input);
    while true
        res = sub_divide(res, gen_poly, input);
        if current_input_bit == length(input)                                   % if it is last divide operation
            if length(res) < gen_poly_len
                break;
            else
                res=bitxor(res,gen_poly);
                res=res( (length(res)-(gen_poly_len-1) + 1):length(res));       % take last nth order bit
                break;
            end
        end
    end

end

function trans = add_error(trans,trans_len,no_bit)                       % add error bits to the transmitted message
    random_index = randperm(trans_len,no_bit);                           % random index chosen for error index
    for i=1:no_bit
        if trans(random_index(i)) == 1                                   % if bit is 1 change it to 0
            trans(random_index(i)) = 0;
        else
            trans(random_index(i)) = 1;                                  % if bit is 0 change it to 1
        end
    end
end

function result = sub_divide(sub_input, gen_poly, input)

    global current_input_bit;

    gen_poly_len = length(gen_poly);
    result = bitxor(sub_input,gen_poly);  % xor operation between sub input and generator polynomial

    for i = 1:gen_poly_len                % for all the bits in the sub input
        j=1;
        if result(j) == 0                 % if it start with 0 bit remove the 0 bit
            result(j) = [];
        else
            break;
        end
    end

    result_len = length(result);

    while true                                                      % add bits to the right of the result until equals to generator polynomial
        if result_len < gen_poly_len
            if current_input_bit == length(input)
                break;
            end
            result(result_len + 1) = input(current_input_bit + 1); 
            result_len = result_len + 1;
            current_input_bit = current_input_bit + 1;
        else
            break;
        end 
    end
end

% The 7th order polynomial is better than 4th order polynomial. This is
% because the longer the generator polynomial is less probability to have
% undetected errors. But there is more redundant information we transmit in
% the transmitted message.
    
        
