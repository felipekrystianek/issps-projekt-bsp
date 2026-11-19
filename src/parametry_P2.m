%% parametry_P2.m - konfiguracja sekcji P2: dodatkowy ladunek ok. 0,15 kg blisko srodka masy (np. czujnik)
% Wszystko jak w konfiguracji referencyjnej, zmieniaja sie tylko m, J i CDxS (tab. 1 i 2 zadania projektowego).
parametry_REF;
konfiguracja = 'P2';
m    = 1.65;                              % masa [kg]
I    = diag([0.0114 0.0073 0.0083]);      % momenty bezwladnosci Jxx, Jyy, Jzz [kg m^2]
CDxS = [0.0390 0.0455 0.0900];            % opor jak w REF [m^2]
Om_min     = sqrt(m*g(3)/(4*CT*rho*pi*R^4));   % zawis dla nowej masy [rad/s]
RotorSpeed = Om_min*[1 -1 1 -1];
