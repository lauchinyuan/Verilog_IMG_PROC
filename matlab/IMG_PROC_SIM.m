clc
close all
%% ��ȡmem��ʽ��ͼ���ļ�
fid_rgb_large = fopen("C:/Users/Lau Chinyuan/Desktop/mem/rgb_large.mem",'r');
mem = fscanf(fid_rgb_large,'%02x');
fclose(fid_rgb_large);

%% �ҶȻ�����
gray_r = zeros((length(mem)/3),1);
for i = 0:(length(mem)/3)-1   %��ȡrgb����ֵ�����лҶȻ�����
    gray = 0.3*mem(i*3+1)+0.59*mem(i*3+2)+0.11*mem(i*3+3);
    gray_r(i+1) = round(gray);
end

%% HSVת��
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

%% ��MATLAB����������д��mem�ļ�
%�Ҷȱ任
fid = fopen("C:/Users/Lau Chinyuan/Desktop/mem/matlab_gary_result_large.mem",'w');
fprintf(fid,"%02x\n",gray_r);
fclose(fid);

fid = fopen("C:/Users/Lau Chinyuan/Desktop/mem/matlab_gary_result_large.mem",'w');
fprintf(fid,"%02x",hsv);

%% ��ȡVerilog����������
%�ҶȻ�������
fid_verilog = fopen("C:/Users/Lau Chinyuan/Desktop/mem/gray_result_large.mem",'r');
gray_result_large = fscanf(fid_verilog,"%02x");
fclose(fid_verilog);

%HSV������
fid_verilog = fopen("C:/Users/Lau Chinyuan/Desktop/mem/hsv_result_large.mem",'r');
hsv_result_large = fscanf(fid_verilog,"%02x");
fclose(fid_verilog);
%% �Ƚ�Verilog��MATLAB������֮������
gray_error = gray_result_large - gray_r; %�Ҷȱ任���
gray_error_ave = mean(gray_error);  %�Ҷȱ任ƽ�����
hsv_error = hsv_result_large - hsv; %hsv�任���
hsv_error_ave = mean(hsv_error);    %hsv�任����ƽ��ֵ

%% ���������ҿ��ܳ�������ݵ�������ֵ
%err_ind = find(abs(hsv_error) > 50); %���ҳ��������
%err_array = hsv_error(err_ind);    %�����ֵ
%err_table = [err_ind,err_array];   %�ų����й��ɴ����

