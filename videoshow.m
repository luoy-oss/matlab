

warning('off');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
global ipts0
global ipts1
global ipts0_num
global ipts1_num
global rpts0
global rpts1
global rpts0_num
global rpts1_num
global rpts0b
global rpts1b
global rpts0b_num
global rpts1b_num
global rpts0s
global rpts1s
global rpts0s_num
global rpts1s_num
global rpts0a
global rpts1a
global rpts0a_num
global rpts1a_num
global rpts0an
global rpts1an
global rpts0an_num
global rpts1an_num
global rptsc0
global rptsc1
global rptsc0_num
global rptsc1_num
% float(*rpts)[2];
global rpts_num
global rptsn
global rptsn_num
global Ypt0_rpts0s_id
global Ypt1_rpts1s_id
global Ypt0_found
global Ypt1_found
global Lpt0_rpts0s_id
global Lpt1_rpts1s_id
global Lpt0_found
global Lpt1_found
global is_straight0
global is_straight1

global ROAD_WIDTH
global ROWSIMAGE
global COLSIMAGE

global thres
global block_size
global clip_value

global begin_x
global begin_y

global line_blur_kernel
global pixel_per_meter
global sample_dist
global angle_dist
global far_rate
global aim_distance
global adc_cross

global dir_front
global dir_frontleft
global dir_frontright
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 


change_un_Mat = [   0.659895,-0.583090,63.912258;
                    0.040383,0.100722,4.954539;
                    0.000448,-0.003773,1.017603];
change_un_Mat = inv(change_un_Mat);

% 结果图行列
RESULT_COL = 320;
RESULT_ROW = 240;

global mapx
global mapy

mapx = [];
mapy = [];
tempx = [];
tempy = [];
for c=1:RESULT_COL
    for r=1:RESULT_ROW
        j = r;
        i = c;
        uwv = [i,j,1];
        local_x = fix(dot(uwv,change_un_Mat(1,:))/dot(uwv,change_un_Mat(3,:)));
        local_y = fix(dot(uwv,change_un_Mat(2,:))/dot(uwv,change_un_Mat(3,:)));
        tempx = [tempx,local_x];
        tempy = [tempy,local_y];
    end
    mapx(:,c) = [tempx];
    mapy(:,c) = [tempy];
    
    tempx = [];
    tempy = [];
end

ROWSIMAGE = 240;
COLSIMAGE = 320;
% 变量初始化
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  原图左右边线
ipts0 = zeros(ROWSIMAGE, 2);
ipts1 = zeros(ROWSIMAGE, 2);
ipts0_num = 0;
ipts1_num = 0;
%  变换后左右边线
rpts0 = zeros(ROWSIMAGE, 2);
rpts1 = zeros(ROWSIMAGE, 2);
rpts0_num = 0;
rpts1_num = 0;
%  变换后左右边线+滤波
rpts0b = zeros(ROWSIMAGE, 2);
rpts1b = zeros(ROWSIMAGE, 2);
rpts0b_num = 0;
rpts1b_num = 0;
% 变换后左右边线+等距采样
rpts0s = zeros(ROWSIMAGE, 2);
rpts1s = zeros(ROWSIMAGE, 2);
rpts0s_num = 0;
rpts1s_num = 0;
% 左右边线局部角度变化率
rpts0a = [];
rpts1a = [];
rpts0a_num = 0;
rpts1a_num = 0;
% 左右边线局部角度变化率+非极大抑制
rpts0an = [];
rpts1an = [];
rpts0an_num = 0;
rpts1an_num = 0;
% 左/右中线
rptsc0 = zeros(ROWSIMAGE, 2);
rptsc1 = zeros(ROWSIMAGE, 2);
rptsc0_num = 0;
rptsc1_num = 0;
% 中线
% float(*rpts)[2];
rpts_num = 0;
% 归一化中线
rptsn = zeros(ROWSIMAGE, 2);
rptsn_num = 0;
% Y角点
Ypt0_rpts0s_id = 0;
Ypt1_rpts1s_id = 0;
Ypt0_found = 0;
Ypt1_found = 0;
% L角点
Lpt0_rpts0s_id = 0;
Lpt1_rpts1s_id = 0;
Lpt0_found = 0;
Lpt1_found = 0;
% 长直道
is_straight0 = 0;
is_straight1 = 0;


dir_front = [   0 , -1;
                1 ,  0;
                0 ,  1;
                -1,  0;];
dir_frontleft = [   -1, -1;
                    1,  -1;
                    1,  1;
                    -1, 1;];
dir_frontright = [  1,  -1;
                    1,  1;
                    -1, 1;
                    -1, -1;];
ROAD_WIDTH = 0.45;

% 相关寻线参数
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
thres = 140;
block_size = 7;
clip_value = 2;

begin_x = 15;
begin_y = 162; 

line_blur_kernel = 7;
pixel_per_meter = 94;% 平移像素，拟合中线

sample_dist = 0.02;
angle_dist = 0.2;
far_rate = 0.5;
aim_distance = 0.68;
adc_cross = false;
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
fileName = 'sample.mp4'; 
obj = VideoReader(fileName);
numFrames = obj.NumFrames;% 帧的总数
for k = 1 : numFrames 			% 读取数据
 	init();
    frame = read(obj,k);
    frame = rgb2gray(frame);
    img_raw = fix(imbinarize(frame));
    img_raw(img_raw > 0) = 255;
    frame_nitoushi = ones(ROWSIMAGE,COLSIMAGE);
%     imshow(img_raw);title('bi_frame')
    for c=1:COLSIMAGE
        for r=1:ROWSIMAGE
            uwv = [i,j,1];
            local_x = fix(mapx(r, c));
            local_y = fix(mapy(r, c));
            if local_x > 0 && local_y > 0 && local_x <= COLSIMAGE && local_y <= ROWSIMAGE
                if img_raw(r,c) > 0
                    frame_nitoushi(local_y,local_x) = 255;
                else
                    frame_nitoushi(local_y,local_x) = 0;
                end
            end
        end
    end
    hold off;
    imshow(frame_nitoushi,[]);title('透视变换后')
    hold on;
    process_image(img_raw)
    
    % 变换后左右边线+等距采样
    plot(rpts0s(1:rpts0s_num,1),rpts0s(1:rpts0s_num,2),'or');
    plot(rpts1s(1:rpts1s_num,1),rpts1s(1:rpts1s_num,2),'ob');

    % 中线拟合
    plot(rptsc0(1:rptsc0_num,1),rptsc0(1:rptsc0_num,2),'or');
    plot(rptsc1(1:rptsc1_num,1),rptsc1(1:rptsc1_num,2),'ob');

%  	imshow(img_raw); 		%显示帧
    pause(0.001);
end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 


function process_image(img_raw)
global begin_x
global begin_y

global thres
global block_size
global clip_value

global ROWSIMAGE
global COLSIMAGE

global ipts0
global ipts1
global ipts0_num
global ipts1_num

x1 = COLSIMAGE / 2 - begin_x;
y1 = begin_y;
ipts0_num = ROWSIMAGE;

% for (; x1 > 0; x1--) if (AT_IMAGE(&img_raw, x1 - 1, y1) < thres) break;
for i = x1:-1:1
    if img_raw(y1,x1-1) < thres
        break
    end
    x1 = i;
end


if img_raw(y1,x1) >= thres
%     findline_lefthand_adaptive(&img_raw, block_size, clip_value, x1, y1, ipts0, &ipts0_num);
    [ipts0, ipts0_num] = findline_lefthand_adaptive(img_raw, block_size, clip_value, x1, y1, ipts0, ipts0_num);
else
    ipts0_num = 0;
end


x2 = COLSIMAGE / 2 + begin_x;
y2 = begin_y;
ipts1_num = ROWSIMAGE;

% for (; x1 > 0; x1--) if (AT_IMAGE(&img_raw, x1 - 1, y1) < thres) break;
for i = x2:1:COLSIMAGE - 1
    if img_raw(y2,x2+1) < thres
        break
    end
    x2 = i;
end

if img_raw(y2,x2) >= thres
    [ipts1, ipts1_num] = findline_righthand_adaptive(img_raw, block_size, clip_value, x2, y2, ipts1, ipts1_num);
else
    ipts1_num = 0;
end

global mapx
global mapy
plot(mapx(begin_y, COLSIMAGE / 2 - begin_x),mapy(begin_y, COLSIMAGE / 2 - begin_x),"xr");
plot(mapx(begin_y, COLSIMAGE / 2 + begin_x),mapy(begin_y, COLSIMAGE / 2 + begin_x),"xb");

global rpts0
global rpts0_num
for i = 1:1:ipts0_num
    rpts0(i,1) = mapx(ipts0(i,2),ipts0(i,1));
    rpts0(i,2) = mapy(ipts0(i,2),ipts0(i,1));
end
rpts0_num = ipts0_num;

global rpts1
global rpts1_num
for i = 1:1:ipts1_num
    rpts1(i,1) = mapx(ipts1(i,2),ipts1(i,1));
    rpts1(i,2) = mapy(ipts1(i,2),ipts1(i,1));
end
rpts1_num = ipts1_num;

% 边线滤波
% blur_points(rpts0, rpts0_num, rpts0b, (int)round(line_blur_kernel));
global line_blur_kernel
global rpts0b
global rpts0b_num
global rpts1b
global rpts1b_num

rpts0b = blur_points(rpts0, rpts0_num, rpts0b, fix(round(line_blur_kernel)));
rpts0b_num = rpts0_num;

rpts1b = blur_points(rpts1, rpts1_num, rpts1b, fix(round(line_blur_kernel)));
rpts1b_num = rpts1_num;

% 边线等距采样
global rpts0s
global rpts0s_num
global rpts1s
global rpts1s_num
global sample_dist
global pixel_per_meter

rpts0s_num = ROWSIMAGE;
[rpts0s, rpts0s_num] = resample_points(rpts0b, rpts0b_num, rpts0s, rpts0s_num, sample_dist * pixel_per_meter);
rpts1s_num = ROWSIMAGE;
[rpts1s, rpts1s_num] = resample_points(rpts1b, rpts1b_num, rpts1s, rpts1s_num, sample_dist * pixel_per_meter);


% 边线局部角度变化率
global rpts0a
global rpts0a_num
global rpts1a
global rpts1a_num
global angle_dist

rpts0a = local_angle_points(rpts0s, rpts0s_num, rpts0a, fix(round(angle_dist / sample_dist)));
rpts0a_num = rpts0s_num;
rpts1a = local_angle_points(rpts1s, rpts1s_num, rpts1a, fix(round(angle_dist / sample_dist)));
rpts1a_num = rpts1s_num;
 
% 角度变化率非极大抑制
global rpts0an
global rpts0an_num
global rpts1an
global rpts1an_num

rpts0an = nms_angle(rpts0a, rpts0a_num, rpts0an, fix(round(angle_dist / sample_dist)) * 2 + 1);
rpts0an_num = rpts0a_num;
rpts1an = nms_angle(rpts1a, rpts1a_num, rpts1an, fix(round(angle_dist / sample_dist)) * 2 + 1);
rpts1an_num = rpts1a_num;

% 左右中线跟踪
global rptsc0
global rptsc0_num
global rptsc1
global rptsc1_num

global ROAD_WIDTH
rptsc0 = track_leftline(rpts0s, rpts0s_num, rptsc0, fix(round(angle_dist / sample_dist)), pixel_per_meter * ROAD_WIDTH / 2);
rptsc0_num = rpts0s_num;
rptsc1 = track_rightline(rpts1s, rpts1s_num, rptsc1, fix(round(angle_dist / sample_dist)), pixel_per_meter * ROAD_WIDTH / 2);
rptsc1_num = rpts1s_num;

end

% 左边线跟踪中线
function pts_out = track_leftline(pts_in, num, pts_out, approx_num, dist)
    for i = 1:1:num
        dx = pts_in(clip(i + approx_num, 1, num), 1) - pts_in(clip(i - approx_num, 1, num), 1);
        dy = pts_in(clip(i + approx_num, 1, num), 2) - pts_in(clip(i - approx_num, 1, num), 2);
        dn = sqrt(dx * dx + dy * dy);
        dx = dx / dn;% sin
        dy = dy / dn;% cos
        pts_out(i, 1) = pts_in(i, 1) - dy * dist;
        pts_out(i, 2) = pts_in(i, 2) + dx * dist;
    end
end

% 右边线跟踪中线
function pts_out = track_rightline(pts_in, num, pts_out, approx_num, dist)
    for i = 1:1:num
        dx = pts_in(clip(i + approx_num, 1, num), 1) - pts_in(clip(i - approx_num, 1, num), 1);
        dy = pts_in(clip(i + approx_num, 1, num), 2) - pts_in(clip(i - approx_num, 1, num), 2);
        dn = sqrt(dx * dx + dy * dy);
        dx = dx / dn;% sin
        dy = dy / dn;% cos
        pts_out(i, 1) = pts_in(i, 1) + dy * dist;
        pts_out(i, 2) = pts_in(i, 2) - dx * dist;
    end
end

function angle_out = nms_angle(angle_in, num, angle_out, kernel)
    half = fix(kernel / 2);
    for i = 1:1:num
        angle_out(i) = angle_in(i);
        for j = -half:1:half
            if abs(angle_in(clip(i + j, 1, num)))> abs(angle_out(i))
                angle_out(i) = 0;
                break;
            end
        end
    end
end

% 点集局部角度变化率  距离为dist
function angle_out = local_angle_points(pts_in, num, angle_out, dist)
    for i = 1:1:num
        if i <= 1 || i >= num
            angle_out(i) = 0;
            continue
        end
        dx1 = pts_in(i, 1) - pts_in(clip(i - dist, 1, num), 1);%往前方找十个距离  //clip相当于传进一个x进行限幅
        dy1 = pts_in(i, 2) - pts_in(clip(i - dist, 1, num), 2);
        dn1 = sqrt(dx1 * dx1 + dy1 * dy1);
        dx2 = pts_in(clip(i + dist, 1, num), 1) - pts_in(i, 1);%后方十个距离
        dy2 = pts_in(clip(i + dist, 1, num), 2) - pts_in(i, 2);
        dn2 = sqrt(dx2 * dx2 + dy2 * dy2);
        c1 = dx1 / dn1;% cos
        s1 = dy1 / dn1;% sin
        c2 = dx2 / dn2;
        s2 = dy2 / dn2;
        angle_out(i) = atan2(c1 * s2 - c2 * s1, c2 * c1 + s2 * s1);%arctan算出角度
    end

end

% 点集等距采样  使走过的采样前折线段的距离为`dist`
function [pts_out, len] = resample_points(pts_in, num1, pts_out, num2, dist)
    remain = 0;
    len = 0;
    for i = 1:1:num1 - 1
        if len >= num2
            break
        end
        x0 = pts_in(i, 1);
        y0 = pts_in(i, 2);
        dx = pts_in(i + 1, 1) - x0;
        dy = pts_in(i + 1, 2) - y0;
        dn = sqrt(dx * dx + dy * dy);
        dx = dx / dn;
        dy = dy / dn;
        
        while remain < dn && len < num2
            x0 = x0 + dx * remain;
            pts_out(len + 1, 1) = x0;
            y0 = y0 + dy * remain;
            pts_out(len + 1, 2) = y0;
            len = len + 1;
            dn = dn - remain;
            remain = dist;
        end
        remain = remain - dn;
    end
end

function r=clip(x, low, up)
    if x > up
        r = up;
    elseif x < low
        r = low;
    else
        r = x;
    end
end

% 点集三角滤波
function pts_out=blur_points(pts_in, num, pts_out, kernel)
    half = fix(kernel / 2);
    for i = 1:1:num
        pts_out(i, 1) = 0;
        pts_out(i, 2) = 0;
        for j = -half:1:half
            pts_out(i, 1) = pts_out(i, 1) + pts_in(clip(i + j, 1, num), 1) * (half + 1 - abs(j));
            pts_out(i, 2) = pts_out(i, 2) + pts_in(clip(i + j, 1, num), 2) * (half + 1 - abs(j));
        end
        pts_out(i, 1) = pts_out(i, 1) / ((2 * half + 2) * (half + 1) / 2);
        pts_out(i, 2) = pts_out(i, 2) / ((2 * half + 2) * (half + 1) / 2);
    end
end


% 左手迷宫巡线
function [pts, step] = findline_lefthand_adaptive(img, block_size, clip_value, x, y, pts, num)
global dir_front
global dir_frontleft
global ROWSIMAGE
global COLSIMAGE
global thres

half = fix(block_size / 2) + 1;
step = 0;
dir = 0;
turn = 0;
% while (step < *num && 0 < x && x < img->width - 1 && 0 < y && y < img->height - 1 && turn < 4) 
while step < num && half < x && x < COLSIMAGE - half && half < y && y < ROWSIMAGE - half && turn < 4
    % int current_value = AT(img, x, y);
    % int front_value = AT(img, x + dir_front[dir][0], y + dir_front[dir][1]);
    % int frontleft_value = AT(img, x + dir_frontleft[dir][0], y + dir_frontleft[dir][1]);
    current_value = img(y, x);
    front_value = img(y + dir_front(dir + 1, 2), x + dir_front(dir + 1, 1));
    frontleft_value = img(y + dir_frontleft(dir + 1, 2), x + dir_frontleft(dir + 1, 1)); 

    if front_value < thres
        dir = rem((dir + 1),4);
        turn = turn + 1;
    elseif frontleft_value < thres
        x = x + dir_front(dir + 1, 1);
        y = y + dir_front(dir + 1, 2);
        pts(step + 1, 1) = x;
        pts(step + 1, 2) = y;
        step = step + 1;
        turn = 0;
    else
        x = x + dir_frontleft(dir + 1, 1);
        y = y + dir_frontleft(dir + 1, 2);
        dir = rem((dir + 3),4);
        pts(step + 1, 1) = x;
        pts(step + 1, 2) = y;
        step = step + 1;
        turn = 0;
    end
end

end


% 右手迷宫巡线
function [pts, step] = findline_righthand_adaptive(img, block_size, clip_value, x, y, pts, num)
global dir_front
global dir_frontright
global ROWSIMAGE
global COLSIMAGE
global thres

half = fix(block_size / 2) + 1;
step = 0;
dir = 0;
turn = 0;
% while (step < *num && 0 < x && x < img->width - 1 && 0 < y && y < img->height - 1 && turn < 4) 
while step < num && half < x && x < COLSIMAGE - half && half < y && y < ROWSIMAGE - half && turn < 4
    % int current_value = AT(img, x, y);
    % int front_value = AT(img, x + dir_front[dir][0], y + dir_front[dir][1]);
    % int frontleft_value = AT(img, x + dir_frontleft[dir][0], y + dir_frontleft[dir][1]);
    current_value = img(y, x);
    front_value = img(y + dir_front(dir + 1, 2), x + dir_front(dir + 1, 1));
    frontright_value = img(y + dir_frontright(dir + 1, 2), x + dir_frontright(dir + 1, 1)); 

    if front_value < thres
        dir = rem((dir + 3),4);
        turn = turn + 1;
    elseif frontright_value < thres
        x = x + dir_front(dir + 1, 1);
        y = y + dir_front(dir + 1, 2);
        pts(step + 1, 1) = x;
        pts(step + 1, 2) = y;
        step = step + 1;
        turn = 0;
    else
        x = x + dir_frontright(dir + 1, 1);
        y = y + dir_frontright(dir + 1, 2);
        dir = rem((dir + 1),4);
        pts(step + 1, 1) = x;
        pts(step + 1, 2) = y;
        step = step + 1;
        turn = 0;
    end
end
end


function init()
global ipts0
global ipts1
global ipts0_num
global ipts1_num
global rpts0
global rpts1
global rpts0_num
global rpts1_num
global rpts0b
global rpts1b
global rpts0b_num
global rpts1b_num
global rpts0s
global rpts1s
global rpts0s_num
global rpts1s_num
global rpts0a
global rpts1a
global rpts0a_num
global rpts1a_num
global rpts0an
global rpts1an
global rpts0an_num
global rpts1an_num
global rptsc0
global rptsc1
global rptsc0_num
global rptsc1_num
% float(*rpts)[2];
global rpts_num
global rptsn
global rptsn_num
global Ypt0_rpts0s_id
global Ypt1_rpts1s_id
global Ypt0_found
global Ypt1_found
global Lpt0_rpts0s_id
global Lpt1_rpts1s_id
global Lpt0_found
global Lpt1_found
global is_straight0
global is_straight1

global ROWSIMAGE

% 变量初始化
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  原图左右边线
ipts0 = zeros(ROWSIMAGE, 2);
ipts1 = zeros(ROWSIMAGE, 2);
ipts0_num = 0;
ipts1_num = 0;
%  变换后左右边线
rpts0 = zeros(ROWSIMAGE, 2);
rpts1 = zeros(ROWSIMAGE, 2);
rpts0_num = 0;
rpts1_num = 0;
%  变换后左右边线+滤波
rpts0b = zeros(ROWSIMAGE, 2);
rpts1b = zeros(ROWSIMAGE, 2);
rpts0b_num = 0;
rpts1b_num = 0;
% 变换后左右边线+等距采样
rpts0s = zeros(ROWSIMAGE, 2);
rpts1s = zeros(ROWSIMAGE, 2);
rpts0s_num = 0;
rpts1s_num = 0;
% 左右边线局部角度变化率
rpts0a = [];
rpts1a = [];
rpts0a_num = 0;
rpts1a_num = 0;
% 左右边线局部角度变化率+非极大抑制
rpts0an = [];
rpts1an = [];
rpts0an_num = 0;
rpts1an_num = 0;
% 左/右中线
rptsc0 = zeros(ROWSIMAGE, 2);
rptsc1 = zeros(ROWSIMAGE, 2);
rptsc0_num = 0;
rptsc1_num = 0;
% 中线
% float(*rpts)[2];
rpts_num = 0;
% 归一化中线
rptsn = zeros(ROWSIMAGE, 2);
rptsn_num = 0;
% Y角点
Ypt0_rpts0s_id = 0;
Ypt1_rpts1s_id = 0;
Ypt0_found = 0;
Ypt1_found = 0;
% L角点
Lpt0_rpts0s_id = 0;
Lpt1_rpts1s_id = 0;
Lpt0_found = 0;
Lpt1_found = 0;
% 长直道
is_straight0 = 0;
is_straight1 = 0;

end
