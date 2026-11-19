%% parametry_REF.m - parametry konfiguracji referencyjnej (jak w LAB5 i LAB6)
% Model quad_P2.slx czyta te zmienne z workspace. Po zmianie wartosci wystarczy kliknac Run.
konfiguracja = 'REF';

% BSP i otoczenie (tab. 1 i 3 zadania projektowego)
m    = 1.50;                              % masa [kg]
I    = diag([0.0111 0.0070 0.0080]);      % momenty bezwladnosci Jxx, Jyy, Jzz [kg m^2]
CDxS = [0.0390 0.0455 0.0900];            % opor aerodynamiczny CD*S w osiach x, y, z [m^2]
rho  = 1.225;                             % gestosc powietrza [kg/m^3]
d    = 0.225;                             % dlugosc ramienia (Arm length) [m]
H    = -0.035;                            % polozenie srodka masy (Height) [m]
CT   = 0.0142;                            % wspolczynnik ciagu smigla [-]
CQ   = 0.00206;                           % wspolczynnik momentu aerodynamicznego smigla [-]
R    = 0.127;                             % promien smigla [m]
g    = [0; 0; 9.81];                      % przyspieszenie ziemskie (os z w dol) [m/s^2]
InitialPosition = [0 0 -10];              % start [x y z], z w dol, czyli 10 m nad ziemia [m]

% wiatr
Wind   = [0 0 0];                         % staly wiatr [m/s]
Gust   = [0 0 0];                         % podmuch trwajacy 2 s [m/s]
t_gust = 20;                              % chwila podmuchu [s]

% zad. 1 - stale predkosci wirnikow (regulator = 1), domyslnie zawis
regulator  = 1;                           % 1 - stale RotorSpeed (LAB5), 2 - uklad sterowania (LAB6)
Om_min     = sqrt(m*g(3)/(4*CT*rho*pi*R^4));   % predkosc wirnikow w zawisie [rad/s]
RotorSpeed = Om_min*[1 -1 1 -1];          % znaki = kierunki obrotu wirnikow

% zad. 2 - wartosci zadane (regulator = 2)
tryb      = 1;                            % 1 - skoki, 2 - suwaki, 3 - lot do punktu
t_skok    = 1;                            % chwila skoku [s]
z_cel     = 10;                           % wysokosc [m]
phi_cel   = 0;                            % kat roll [rad]
theta_cel = 0;                            % kat pitch [rad]
r_cel     = 0;                            % predkosc obrotu yaw [rad/s]
x_cel     = 0;  y_cel = 0;                % punkt docelowy [m]
psi_cel   = 0;                            % kat yaw w locie do punktu [rad]
v_xy      = 0.5;                          % predkosc rampy x, y [m/s]
Wmax      = 1000;                         % maksymalna predkosc wirnika [rad/s]
