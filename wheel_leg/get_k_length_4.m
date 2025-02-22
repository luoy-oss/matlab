function K = get_k_length_4(leg_length, Q_mat, R_mat)
       
    %theta : 摆杆与竖直方向夹角             R   ：驱动轮半径
    %x     : 驱动轮位移                    L   : 摆杆重心到驱动轮轴距离
    %Lm  : 摆杆重心到其转轴距离             l   : 机体重心到其转轴距离
    %T     ：驱动轮输出力矩                 mw  : 驱动轮转子质量
    %N     ：驱动轮对摆杆力的水平分量        mp  : 摆杆质量
    %P     ：驱动轮对摆杆力的竖直分量        M   : 机体质量
    %Nm    ：摆杆对机体力水平方向分量        Iw  : 驱动轮转子转动惯量
    %Pm    ：摆杆对机体力竖直方向分量        Ip  : 摆杆绕质心转动惯量
    %Nf    : 地面对驱动轮摩擦力             Im  : 机体绕质心转动惯量
    
    syms x(t) T R Iw mw M L Lm theta(t) l mp g Ip IM
    syms f1 f2 f3 d_theta d_x theta0 x0 phi0 
    % leg_length =0.01;
    R1=0.0185;                  %驱动轮半径
    L1=leg_length/2;            %摆杆重心到驱动轮轴距离
    Lm1=leg_length/2;           %摆杆重心到其转轴距离
    l1=0.00399959;              %机体质心距离转轴距离
    mw1=0.041 + 0.0052728;      %驱动轮质量
    mp1=0.0198168;              %杆质量
    M1=0.086755991;             %机体质量
    Iw1=mw1*R1^2;               %驱动轮转动惯量
    Ip1=mp1*((L1+Lm1)^2 + 0.01^2)/12.0; %摆杆转动惯量(长方体 m(a^2 + b^2)/12)
    Im1=M1*(0.029525^2+0.01885^2)/12.0; %机体绕质心转动惯量(长方体 m(a^2 + b^2)/12)
    
    Nm = M*diff(x + (L + Lm )*sin(theta),t,2);   % 对机体 水平方向
    N = Nm + mp*diff(x + L*sin(theta),t,2);                 % 对摆杆 水平方向
    Pm = M*g + M*diff((L+Lm)*cos(theta)+l,t,2);    % 对机体 竖直方向
    P = Pm +mp*g+mp*diff(L*cos(theta),t,2);                 % 对摆杆 竖直方向
    
    eqn1 = diff(x,t,2) == (T -N*R)/(Iw/R + mw*R);           % 驱动轮加速度表达式
    eqn2 = Ip*diff(theta,t,2) == (P*L + Pm*Lm)*sin(theta)-(N*L+Nm*Lm)*cos(theta)-T; % 摆杆力矩平衡
    % eqn3 = Tp == -Nm*l; % 机体力矩平衡
    
    % subs(  ,diff(theta,t,2),f1)   f1 角加速度
    % subs(  ,diff(x,t,2),f2)       f2 驱动轮加速度
    % subs(  ,diff(theta,t),d_theta)    d_theta 角速度
    % subs(  ,diff(x,t),d_x)            d_x     驱动轮速度
    % theta -> theta0 x -> x0
    eqn10 = subs(subs(subs(subs(subs(subs(eqn1,diff(theta,t,2),f1),diff(x,t,2),f2),diff(theta,t),d_theta),diff(x,t),d_x),theta,theta0),x,x0);
    eqn20 = subs(subs(subs(subs(subs(subs(eqn2,diff(theta,t,2),f1),diff(x,t,2),f2),diff(theta,t),d_theta),diff(x,t),d_x),theta,theta0),x,x0);
    % eqn30 = subs(subs(subs(subs(subs(subs(eqn3,diff(theta,t,2),f1),diff(x,t,2),f2),diff(theta,t),d_theta),diff(x,t),d_x),theta,theta0),x,x0);
    
    % 对3个加速度求解
    [f1,f2] = solve(eqn10,eqn20,f1,f2);
    
    
    xx = [theta0,d_theta,x0,d_x];
    uu = [T];
    % 雅可比矩阵
    %  [theta0,d_theta,d_x,T,Tp]为0
    % 即x,u为系统平衡点 f(x,u) = 0时的解x = [0;0;x;0] u = [0]
    A=subs(jacobian([d_theta,f1,d_x,f2],xx),[theta0,d_theta,d_x,T],[0,0,0,0]);
    % 带入物理参数数据
    A=subs(A,[R,L,Lm,l,mw,mp,M,Iw,Ip,IM,g],[R1,L1,Lm1,l1,mw1,mp1,M1,Iw1,Ip1,Im1,9.8]);
    A=double(A);
    
    % 同理[theta0,d_theta,d_x,T]为0
    B=subs(jacobian([d_theta,f1,d_x,f2],uu),[theta0,d_theta,d_x,T],[0,0,0,0]);
    % 带入物理参数数据
    B=subs(B,[R,L,Lm,l,mw,mp,M,Iw,Ip,IM,g],[R1,L1,Lm1,l1,mw1,mp1,M1,Iw1,Ip1,Im1,9.8]);
    B=double(B);
    
    % Q_mat=diag([100 1 500 100 5000 1]);%theta d_theta x d_x phi d_phi%700 1 600 200 1000 1
    % R_mat=[240 0;0 25];                %T Tp
    
    K=lqr(A,B,Q_mat,R_mat);
end