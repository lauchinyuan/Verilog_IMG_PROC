clc
close all
%% 读取mem格式的图像文件
fid_rgb_large = fopen("C:/Users/Lau Chinyuan/Desktop/mem/rgb_large.mem",'r');
mem = fscanf(fid_rgb_large,'%02x');
fclose(fid_rgb_large);

%% 灰度化处理
gray_r = zeros((length(mem)/3),1);
for i = 0:(length(mem)/3)-1   %读取rgb数据值并进行灰度化处理
    gray = 0.3*mem(i*3+1)+0.59*mem(i*3+2)+0.11*mem(i*3+3);
    gray_r(i+1) = round(gray);
end

%% HSV转换
hsv = zeros(length(mem),1);
for i = 1:3:length(mem)
    r = mem(i);
    g = mem(i+1);
    b = mem(i+2);
    rgb_max = max(mem(i:i+2));
    rgb_min = min(mem(i:i+2));
    max_min = rgb_max-rgb_min;
    if rgb_max == r && g >= b
        H_ang = (60.*(g-b))./max_min;
    elseif rgb_max == mem(i) && mem(i+1)<mem(i+2)
        H_ang = (60.*(g-b))./max_min+360;
    elseif rgb_max == g
        H_ang = 60.*(b-r)./max_min+120;
    elseif rgb_max == b
        H_ang = 60.*(r-g)./max_min+240;
    end
    hsv(i) = round(H_ang*(255/360)); %H
    if rgb_max ~= 0
        hsv(i+1) = round((max_min./rgb_max)*255);
    else
        hsv(i+1) = 0;
    end
    hsv(i+2) = rgb_max;
end
%% 将MATLAB处理后的数据写入mem文件
%灰度变换
fid = fopen("C:/Users/Lau Chinyuan/Desktop/mem/matlab_gary_result_large.mem",'w');
fprintf(fid,"%02x\n",gray_r);
fclose(fid);

fid = fopen("C:/Users/Lau Chinyuan/Desktop/mem/matlab_gary_result_large.mem",'w');
fprintf(fid,"%02x",hsv);

%% 读取Verilog处理后的数据
%灰度化处理结果
fid_verilog = fopen("C:/Users/Lau Chinyuan/Desktop/mem/gray_result_large.mem",'r');
gray_result_large = fscanf(fid_verilog,"%02x");
fclose(fid_verilog);

%HSV计算结果
fid_verilog = fopen("C:/Users/Lau Chinyuan/Desktop/mem/hsv_result_large.mem",'r');
hsv_result_large = fscanf(fid_verilog,"%02x");
fclose(fid_verilog);
%% 比较Verilog和MATLAB计算结果之间的误差
gray_error = gray_result_large - gray_r; %灰度变换误差
gray_error_ave = mean(gray_error);  %灰度变换平均误差
hsv_error = hsv_result_large - hsv; %hsv变换误差
hsv_error_ave = mean(hsv_error);    %hsv变换误差的平均值

%% 按条件查找可能出错的数据的索引和值
%err_ind = find(abs(hsv_error) > 50); %查找出错的索引
%err_array = hsv_error(err_ind);    %出错的值
%err_table = [err_ind,err_array];   %排成两列构成错误表

%% 图像显示
mem_r = mem(1:3:end);  % 图像文件r分量
mem_g = mem(2:3:end);  % 图像文件g分量
mem_b = mem(3:3:end);  % 图像文件b分量
% 图像像素矩阵大小调整
img_r = reshape(mem_r,132,200);
img_g = reshape(mem_g,132,200);
img_b = reshape(mem_b,132,200);
img_rgb = zeros(132,200,3);    %整合成三原色图像
img_rgb(:,:,1) = img_r;
img_rgb(:,:,2) = img_g;
img_rgb(:,:,3) = img_b;
img_rgb = img_rgb./255;
figure,imshow(img_rgb),title("原始RGB图像");

% 灰度图像
gray_img = reshape(gray_r,132,200);
gray_img = gray_img./255;
figure,imshow(gray_img),title("ASIC处理后的灰度图像");



