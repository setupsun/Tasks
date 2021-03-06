format long
%% Начальные условия
% географические координаты цели
B_target = 45;
L_target = 45;
H_target = 100;
% углы направления оптической станции (направление вектора дальности)
phi1 = 0;
phi2 = 90;
D = [2000; 0; 0]
% Начальные углы ЛА
roll = 0;
pitch = 0;
yaw = 0;

%% Получаем координаты цели в прямоугольных пространственных
[X_target, Y_target, Z_target] = blh2xyz(B_target, L_target, H_target)

D = R_opt(D, deg2rad(phi1), deg2rad(phi2))

D = R_la(D, deg2rad(yaw), deg2rad(roll), deg2rad(pitch))

D = R_g(D, deg2rad(B_target), deg2rad(L_target))

X_la = X_target + D(1)
Y_la = Y_target + D(2)
Z_la = Z_target + D(3)

[B_la, L_la, H_la] = xyz2blh(X_la, Y_la, Z_la);
B_la = rad2deg(B_la)
L_la = rad2deg(L_la)
H_la = H_la

plot3([X_target, X_la], [Y_target, Y_la], [Z_target, Z_la]);
grid on
xlabel('X')
ylabel('Y')
zlabel('Z')

%% Перевод из пространственной прямоугольной СК в географической СК
function [X,Y,Z] = blh2xyz(lat,long, h)
  % Convert lat, long, height in WGS84 to ECEF X,Y,Z
  % lat and long given in decimal degrees.
  % altitude should be given in meters
  lat = lat/180*pi; %converting to radians
  long = long/180*pi; %converting to radians
  a = 6378137.0; % earth semimajor axis in meters
  f = 1/298.257223563; % reciprocal flattening
  e2 = 2*f -f^2; % eccentricity squared
 
  chi = sqrt(1-e2*(sin(lat)).^2);
  X = (a./chi +h).*cos(lat).*cos(long);
  Y = (a./chi +h).*cos(lat).*sin(long);
  Z = (a*(1-e2)./chi + h).*sin(lat);
end

%% Матрица поворотов оптической станции
function f = R_opt(D, phi1, phi2)
    R_opt = [cos(phi2) -sin(phi2) * cos(phi1) sin(phi2) * sin(phi1);
             sin(phi2) cos(phi1) * cos(phi2) -cos(phi1) * sin(phi2);
             0 sin(phi1) cos(phi1)]
    f = R_opt * D;
end

%% Матрица перехода из связной в Земную
function f = R_la(D, psi, v, gamma)
    R = [cos(psi) * cos(v) sin(gamma) * sin(psi) - cos(psi) * cos(gamma) * sin(v) cos(gamma) * sin(psi) + cos(psi) * sin(gamma) * sin(v);
         sin(v) cos(gamma) * cos(v) -sin(gamma) * cos(v);
         -sin(psi) * cos(v) sin(gamma) * cos(psi) + sin(psi) * sin(v) * cos(gamma) cos(gamma) * cos(psi) - sin(psi) * sin(v) * sin(gamma)];
     f = R * D;
end

%% Матрица поворотов углов относительно Земли
function f = R_g(D, B, L)
    R = [-cos(L) * sin(L) cos(L) * cos(B) -sin(L);
         -sin(L) * sin(L) cos(B) * sin(L) cos(L);
         cos(B) * cos(L) sin(B) 0];
%     R = [-sin(B) * sin(L) cos(B) cos(B) * sin(L);
%          -cos(B) * sin(L) -sin(B) cos(B) * cos(L);
%          cos(L) 0 sin(L)];
    f = R * D;
end

%% Перевод из пространственных координат в географические
function [phi, lambda, h] = xyz2blh(X,Y,Z)
  a = 6378137.0 % earth semimajor axis in meters
  f = 1/298.257223563 % reciprocal flattening
  b = a*(1-f)% semi-minor axis
 
  e2 = 2*f-f^2% first eccentricity squared
  ep2 = f*(2-f)/((1-f)^2) % second eccentricity squared
 
  r2 = X.^2+Y.^2
  r = sqrt(r2)
  E2 = a^2 - b^2
  F = 54*b^2*Z.^2
  G = r2 + (1-e2)*Z.^2 - e2*E2
  c = (e2*e2*F.*r2)./(G.*G.*G)
  s = ( 1 + c + sqrt(c.*c + 2*c) ).^(1/3)
  P = F./(3*(s+1./s+1).^2.*G.*G)
  Q = sqrt(1+2*e2*e2*P)
  ro = -(e2*P.*r)./(1+Q) + sqrt((a*a/2)*(1+1./Q) - ((1-e2)*P.*Z.^2)./(Q.*(1+Q)) - P.*r2/2)
  tmp = (r - e2*ro).^2
  U = sqrt( tmp + Z.^2 )
  V = sqrt( tmp + (1-e2)*Z.^2 )
  zo = (b^2*Z)./(a*V)
 
  h = U.*( 1 - (b^2)./(a*V))
  phi = atan( (Z + ep2*zo)./r )
  lambda = atan2(Y,X)
end