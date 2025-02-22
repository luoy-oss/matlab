clear;

% 计算不同腿长下LQR增益K
L_var = 0.01;   % 腿质心到机体转轴距离最短1cm 最长4cm
% % theta theta' x x'
% Q_mat=diag([15.84 0.07 2.1872 0.76]);
% % 驱动 髋关节
% R_mat=diag([13]);

% theta theta' x x'
Q_mat=diag([1200 10 730 50]);
% 驱动 髋关节
R_mat=diag([1000]);

K = zeros(20,4);
leg_len = zeros(20,1);

KK = get_k_length_4(L_var, Q_mat, R_mat);

for i=1:20
    L_var = L_var + 0.0015;
    leg_len(i) = L_var*2;
    KK = get_k_length_4(L_var, Q_mat, R_mat);
    KK_t=KK.';
    K(i,:)=KK_t(:);
end

% 不同腿长下二项式拟合K
K_cons=zeros(4,3);  

for i=1:4
    res=fit(leg_len,K(:,i),"poly2");
    K_cons(i,:)=[res.p1, res.p2, res.p3];
end

for j=1:4
    for i=1:3
        fprintf("%f,",K_cons(j,i));
    end
    fprintf("\n");
end
