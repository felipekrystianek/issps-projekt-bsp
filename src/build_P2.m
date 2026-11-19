% Buduje quad_P2.slx - model BSP z LAB5 + system sterowania z LAB6, parametry sekcji P2
% Przelacznik 'regulator': 1 - stale RotorSpeed (badania dynamiki, zad. 1), 2 - uklad sterowania (zad. 2).
% Parametry sa w plikach parametry_REF.m i parametry_P2.m (workspace MATLAB-a).
here = fileparts(mfilename('fullpath')); cd(here);
mdl = 'quad_P2';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); load_system('aerolibrotordyn'); load_system('aerolib6dof2');

%% Parametry: bloki maja nazwy zmiennych, a wartosci sa w workspace (parametry_P2.m / parametry_REF.m)
parametry_P2;
% przy otwarciu modelu wczytuje sie P2, chyba ze w workspace jest juz jakas konfiguracja
set_param(mdl, 'PreLoadFcn', 'if ~exist(''konfiguracja'', ''var''), parametry_P2; end');

%% Model BSP (jak w LAB5, tylko z nazwami zmiennych zamiast liczb)
dof = '6DOF (Quaternion)';
add_block('aerolibrotordyn/Multirotor', [mdl '/DJIF450Rotors'], 'units', 'Metric (MKS)', ...
    'modelMode', 'Without flap effects', 'config', 'Quadcopter +', 'armLength', 'd', 'rotorHeight', 'H', ...
    'CTCQMode', 'Dialog', 'CT', 'CT', 'CQ', 'CQ', 'radius', 'R');
add_block('aerolib6dof2/6DOF (Quaternion)', [mdl '/' dof], 'units', 'Metric (MKS)', 'mtype', 'Fixed', ...
    'xme_0', 'InitialPosition', 'Vm_0', '[0 0 0]', 'eul_0', '[0 0 0]', 'pm_0', '[0 0 0]', ...
    'mass_0', 'm', 'inertia', 'I', 'mass_flag', 'on');
add_block('simulink/Sources/Constant', [mdl '/AirDensity'], 'Value', 'rho');
add_block('simulink/Sources/Constant', [mdl '/Gravity'], 'Value', 'g');
add_block('simulink/Sources/Constant', [mdl '/CDxS'], 'Value', 'CDxS');
add_block('simulink/Sources/Constant', [mdl '/Wind'], 'Value', 'Wind');
add_block('simulink/Sources/Step', [mdl '/Podmuch start'], 'Time', 't_gust', 'Before', '[0 0 0]', 'After', 'Gust');
add_block('simulink/Sources/Step', [mdl '/Podmuch koniec'], 'Time', 't_gust + 2', 'Before', '[0 0 0]', 'After', '-Gust');
add_block('simulink/Math Operations/Sum', [mdl '/Wiatr'], 'Inputs', '+++', 'IconShape', 'round');
add_block('simulink/Math Operations/Sum', [mdl '/Sum'], 'Inputs', '+++', 'IconShape', 'round');
add_block('simulink/Math Operations/Product', [mdl '/Matrix Multiply'], 'Multiplication', 'Matrix(*)');
add_block('simulink/Math Operations/Product', [mdl '/x'], 'Inputs', '2');
add_block('simulink/Math Operations/Product', [mdl '/Matrix Multiply1'], 'Multiplication', 'Matrix(*)');
add_block('simulink/User-Defined Functions/MATLAB Function', [mdl '/bodyDrag']);
ch = sfroot().find('-isa', 'Stateflow.EMChart', 'Path', [mdl '/bodyDrag']);
ch.Script = fileread(fullfile(here, 'bodyDrag.m'));

%% Pomiary: wysokosc, polozenie, katy
add_block('simulink/Math Operations/Gain', [mdl '/[1;1;-1]'], 'Gain', '[1 1 -1]');   % Xe -> [x y h]
add_block('simulink/Signal Routing/Demux', [mdl '/Demux XYZ'], 'Outputs', '3');
add_block('simulink/Signal Routing/Demux', [mdl '/Demux katy'], 'Outputs', '3');
add_block('simulink/Signal Routing/Demux', [mdl '/Demux w_b'], 'Outputs', '3');   % predkosci katowe p, q, r

%% Wartosci zadane: tryb 1 - skoki, 2 - suwaki (jak na wykladzie), 3 - polozenie XYZ
add_block('simulink/Sources/Constant', [mdl '/tryb'], 'Value', 'tryb');
add_block('simulink/Sources/Step', [mdl '/z skok'], 'Time', 't_skok', 'Before', '-InitialPosition(3)', 'After', 'z_cel');
add_block('simulink/Sources/Step', [mdl '/phi skok'], 'Time', 't_skok', 'Before', '0', 'After', 'phi_cel');
add_block('simulink/Sources/Step', [mdl '/theta skok'], 'Time', 't_skok', 'Before', '0', 'After', 'theta_cel');
add_block('simulink/Sources/Step', [mdl '/r skok'], 'Time', 't_skok', 'Before', '0', 'After', 'r_cel');
add_block('simulink/Sources/Step', [mdl '/psi skok'], 'Time', 't_skok', 'Before', '0', 'After', 'psi_cel');
add_block('simulink/Sources/Step', [mdl '/x skok'], 'Time', 't_skok', 'Before', '0', 'After', 'x_cel');
add_block('simulink/Sources/Step', [mdl '/y skok'], 'Time', 't_skok', 'Before', '0', 'After', 'y_cel');
% rampa zamiast skoku dla X i Y (predkosc v_xy), zeby czlon I nie narastal przy dlugim przelocie
add_block('simulink/Discontinuities/Rate Limiter', [mdl '/rampa x'], 'RisingSlewLimit', 'v_xy', 'FallingSlewLimit', '-v_xy');
add_block('simulink/Discontinuities/Rate Limiter', [mdl '/rampa y'], 'RisingSlewLimit', 'v_xy', 'FallingSlewLimit', '-v_xy');
% suwaki jak na slajdach 28 i 32: dla z predkosc zmian (1 -> suwak -> 1/s), roll i pitch pi/8, predkosc yaw pi/12
add_block('simulink/Sources/Constant', [mdl '/1'], 'Value', '1');
add_block('simulink/Math Operations/Slider Gain', [mdl '/suwak z'], 'gain', '0', 'low', '-1', 'high', '1');
add_block('simulink/Continuous/Integrator', [mdl '/1//s'], 'InitialCondition', '-InitialPosition(3)');
kat = {'phi', 'pi/8'; 'theta', 'pi/8'; 'r', 'pi/12'};
for i = 1:3
    add_block('simulink/Sources/Constant', [mdl '/' kat{i, 1} ' max'], 'Value', kat{i, 2});
    add_block('simulink/Math Operations/Slider Gain', [mdl '/suwak ' kat{i, 1}], 'gain', '0', 'low', '-1', 'high', '1');
end
for c = {'z', 'phi', 'theta', 'r'}
    add_block('simulink/Signal Routing/Multiport Switch', [mdl '/' c{1} '_ref'], 'Inputs', '3');
end

%% Regulator polozenia X, Y (LAB6 zad. 2): uchyb polozenia -> zadane katy roll i pitch
add_block('simulink/Math Operations/Sum', [mdl '/ex'], 'Inputs', '+-', 'IconShape', 'round');
add_block('simulink/Math Operations/Sum', [mdl '/ey'], 'Inputs', '+-', 'IconShape', 'round');
add_block('simulink/Continuous/PID Controller', [mdl '/PID X'], 'P', '0.06', 'I', '0.01', 'D', '0.3', 'N', '10');
add_block('simulink/Continuous/PID Controller', [mdl '/PID Y'], 'P', '0.06', 'I', '0.01', 'D', '0.3', 'N', '10');
add_block('simulink/User-Defined Functions/MATLAB Function', [mdl '/XY na katy']);
ch = sfroot().find('-isa', 'Stateflow.EMChart', 'Path', [mdl '/XY na katy']);
ch.Script = fileread(fullfile(here, 'xy_na_katy.m'));
% kat yaw (zad. 2): regulator P kata -> zadana predkosc yaw
add_block('simulink/Math Operations/Sum', [mdl '/e_psi'], 'Inputs', '+-', 'IconShape', 'round');
add_block('simulink/Math Operations/Gain', [mdl '/K psi'], 'Gain', '1');
add_block('simulink/Discontinuities/Saturation', [mdl '/limit r'], 'UpperLimit', 'pi/12', 'LowerLimit', '-pi/12');

%% Regulatory PID z wykladu (slajdy 26, 38-40); PID4 reguluje predkosc yaw r jak na slajdach 32 i 40
pid = {'PID1', 'z', '20', '0.001', '30'; 'PID2', 'phi', '0.00042', '2.87e-6', '0.011'; ...
       'PID3', 'theta', '0.0038', '9.97e-5', '0.026'; 'PID4', 'r', '0.020', '0.0093', '0.0014'};
for i = 1:4
    add_block('simulink/Math Operations/Sum', [mdl '/e_' pid{i, 2}], 'Inputs', '+-', 'IconShape', 'round');
    add_block('simulink/Continuous/PID Controller', [mdl '/' pid{i, 1}], 'P', pid{i, 3}, 'I', pid{i, 4}, ...
        'D', pid{i, 5}, 'N', '10');
end
add_block('simulink/Sources/Constant', [mdl '/m*g(3)'], 'Value', 'm*g(3)');
% ograniczenie dodatkowego ciagu jak na slajdzie 25 (zeby wirniki nie wchodzily w nasycenie przy wznoszeniu)
add_block('simulink/Discontinuities/Saturation', [mdl '/limit dT'], 'UpperLimit', '0.5*m*g(3)', 'LowerLimit', '-0.5*m*g(3)');
add_block('simulink/Math Operations/Sum', [mdl '/Suma ciagu'], 'Inputs', '++', 'IconShape', 'round');
% -1: model ma os z w dol (NED), a macierz A z wykladu zaklada os z w gore,
% wiec momenty roll i pitch maja przeciwny znak
add_block('simulink/Math Operations/Gain', [mdl '/-1 roll'], 'Gain', '-1');
add_block('simulink/Math Operations/Gain', [mdl '/-1 pitch'], 'Gain', '-1');
add_block('simulink/Signal Routing/Mux', [mdl '/Mux U'], 'Inputs', '4');
Ainv = ['[1/(4*pi*CT*R^4*rho), 0, -1/(2*pi*CT*R^4*d*rho), -1/(4*pi*CQ*R^5*rho); ' ...
        '1/(4*pi*CT*R^4*rho), 1/(2*pi*CT*R^4*d*rho), 0, 1/(4*pi*CQ*R^5*rho); ' ...
        '1/(4*pi*CT*R^4*rho), 0, 1/(2*pi*CT*R^4*d*rho), -1/(4*pi*CQ*R^5*rho); ' ...
        '1/(4*pi*CT*R^4*rho), -1/(2*pi*CT*R^4*d*rho), 0, 1/(4*pi*CQ*R^5*rho)]'];
add_block('simulink/Math Operations/Gain', [mdl '/A^{-1}'], 'Gain', Ainv, 'Multiplication', 'Matrix(K*u)');
add_block('simulink/Math Operations/Sqrt', [mdl '/sqrt'], 'Operator', 'signedSqrt');
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturation'], 'UpperLimit', 'Wmax', 'LowerLimit', '0');
add_block('simulink/Math Operations/Gain', [mdl '/kierunki obrotu'], 'Gain', '[1 -1 1 -1]');

%% Przelacznik: stale RotorSpeed (jak w LAB5) albo uklad sterowania (jak w LAB6)
add_block('simulink/Sources/Constant', [mdl '/RotorSpeed'], 'Value', 'RotorSpeed');
add_block('simulink/Sources/Constant', [mdl '/regulator'], 'Value', 'regulator');
add_block('simulink/Signal Routing/Multiport Switch', [mdl '/sterowanie'], 'Inputs', '2');

%% Scope'y jak na slajdzie 32
for c = {'z', 'phi', 'theta', 'r', 'psi'}
    add_block('simulink/Signal Routing/Mux', [mdl '/Mux ' c{1}], 'Inputs', '2');
    add_block('simulink/Sinks/Scope', [mdl '/Scope ' c{1}]);
end
add_block('simulink/Signal Routing/Mux', [mdl '/Mux XY'], 'Inputs', '4');
add_block('simulink/Sinks/Scope', [mdl '/Scope XY']);

%% Rozmieszczenie blokow (jak na slajdzie 32: wartosci zadane -> PID -> mikser -> BSP)
poz = {'tryb', [380 10 40 30]; ...
  'z skok', [200 80 40 30]; '1', [20 130 30 30]; 'suwak z', [80 130 40 30]; '1//s', [150 130 30 30]; ...
  'z_ref', [380 70 50 90]; 'e_z', [470 105 20 20]; 'PID1', [520 100 50 30]; 'limit dT', [600 100 40 30]; ...
  'm*g(3)', [590 150 60 30]; 'Suma ciagu', [690 105 20 20]; ...
  'phi skok', [200 210 40 30]; 'phi max', [20 260 40 30]; 'suwak phi', [80 260 40 30]; 'phi_ref', [380 200 50 90]; ...
  'e_phi', [470 235 20 20]; 'PID2', [520 230 50 30]; '-1 roll', [600 230 40 30]; ...
  'theta skok', [200 340 40 30]; 'theta max', [20 390 40 30]; 'suwak theta', [80 390 40 30]; 'theta_ref', [380 330 50 90]; ...
  'e_theta', [470 365 20 20]; 'PID3', [520 360 50 30]; '-1 pitch', [600 360 40 30]; ...
  'r skok', [200 470 40 30]; 'r max', [20 520 40 30]; 'suwak r', [80 520 40 30]; 'r_ref', [380 460 50 90]; ...
  'e_r', [470 495 20 20]; 'PID4', [520 490 50 30]; ...
  'x skok', [20 640 40 30]; 'rampa x', [90 640 40 30]; 'ex', [160 645 20 20]; 'PID X', [210 640 50 30]; ...
  'y skok', [20 720 40 30]; 'rampa y', [90 720 40 30]; 'ey', [160 725 20 20]; 'PID Y', [210 720 50 30]; ...
  'XY na katy', [290 640 70 110]; ...
  'psi skok', [20 820 40 30]; 'e_psi', [160 825 20 20]; 'K psi', [210 820 40 30]; 'limit r', [280 820 40 30]; ...
  'Mux U', [760 80 8 450]; 'A^{-1}', [800 285 70 40]; 'sqrt', [900 290 40 30]; 'Saturation', [970 290 40 30]; ...
  'kierunki obrotu', [1040 290 60 30]; 'RotorSpeed', [950 200 140 30]; 'regulator', [1050 140 50 30]; ...
  'sterowanie', [1120 220 30 100]; 'DJIF450Rotors', [1180 200 180 220]; 'AirDensity', [1050 380 50 30]; 'Sum', [1400 215 20 20]; ...
  dof, [1470 180 200 260]; ...
  'Gravity', [1700 500 60 30]; 'Matrix Multiply', [1580 490 40 50]; 'x', [1460 490 30 60]; ...
  'Wind', [1780 590 60 30]; 'Podmuch start', [1780 640 40 30]; 'Podmuch koniec', [1780 690 40 30]; ...
  'Wiatr', [1700 640 20 20]; 'Matrix Multiply1', [1580 600 40 50]; 'bodyDrag', [1230 560 110 120]; ...
  'CDxS', [1060 700 120 30]; ...
  '[1;1;-1]', [1720 190 60 30]; 'Demux XYZ', [1810 170 5 70]; 'Demux katy', [1810 260 5 70]; 'Demux w_b', [1810 345 5 70]; ...
  'Mux z', [1900 40 5 40]; 'Scope z', [1940 45 30 30]; 'Mux phi', [1900 100 5 40]; 'Scope phi', [1940 105 30 30]; ...
  'Mux theta', [1900 160 5 40]; 'Scope theta', [1940 165 30 30]; 'Mux r', [1900 220 5 40]; 'Scope r', [1940 225 30 30]; ...
  'Mux psi', [1900 280 5 40]; 'Scope psi', [1940 285 30 30]; 'Mux XY', [1900 340 5 70]; 'Scope XY', [1940 360 30 30]};
for i = 1:size(poz, 1)
    p = poz{i, 2}; set_param([mdl '/' poz{i, 1}], 'Position', [p(1) p(2) p(1) + p(3) p(2) + p(4)]);
end
for b = {'Gravity', 'Matrix Multiply', 'x', 'Wind', 'Podmuch start', 'Podmuch koniec', 'Wiatr', ...
         'Matrix Multiply1', 'bodyDrag', 'CDxS'}
    set_param([mdl '/' b{1}], 'Orientation', 'left');
end

%% Polaczenia
pn = @(b) get_param([mdl '/' b], 'PortHandles');
con = @(a, ia, b, ib) add_line(mdl, pn(a).Outport(ia), pn(b).Inport(ib), 'autorouting', 'smart');
% model BSP (wyjscia 6DOF: 1 V_e, 2 X_e, 3 katy, 4 q, 5 DCM_be, 6 V_b, 7 w_b, 8 m, 9 I)
con('AirDensity', 1, 'DJIF450Rotors', 2);
con('DJIF450Rotors', 1, 'Sum', 1); con('DJIF450Rotors', 2, dof, 2); con('Sum', 1, dof, 1);
con(dof, 5, 'Matrix Multiply', 1); con('Gravity', 1, 'Matrix Multiply', 2);
con(dof, 8, 'x', 1); con('Matrix Multiply', 1, 'x', 2); con('x', 1, 'Sum', 3);
con('Wind', 1, 'Wiatr', 1); con('Podmuch start', 1, 'Wiatr', 2); con('Podmuch koniec', 1, 'Wiatr', 3);
con(dof, 5, 'Matrix Multiply1', 1); con('Wiatr', 1, 'Matrix Multiply1', 2);
con(dof, 6, 'bodyDrag', 1); con('Matrix Multiply1', 1, 'bodyDrag', 2);
con('AirDensity', 1, 'bodyDrag', 3); con('CDxS', 1, 'bodyDrag', 4); con('bodyDrag', 1, 'Sum', 2);
% pomiary
con(dof, 2, '[1;1;-1]', 1); con('[1;1;-1]', 1, 'Demux XYZ', 1); con(dof, 3, 'Demux katy', 1); con(dof, 7, 'Demux w_b', 1);
% wartosci zadane
con('1', 1, 'suwak z', 1); con('suwak z', 1, '1//s', 1);
for i = 1:3, con([kat{i, 1} ' max'], 1, ['suwak ' kat{i, 1}], 1); end
con('tryb', 1, 'z_ref', 1); con('z skok', 1, 'z_ref', 2); con('1//s', 1, 'z_ref', 3); con('z skok', 1, 'z_ref', 4);
con('tryb', 1, 'r_ref', 1); con('r skok', 1, 'r_ref', 2); con('suwak r', 1, 'r_ref', 3); con('limit r', 1, 'r_ref', 4);
con('psi skok', 1, 'e_psi', 1); con('Demux katy', 3, 'e_psi', 2); con('e_psi', 1, 'K psi', 1); con('K psi', 1, 'limit r', 1);
con('tryb', 1, 'phi_ref', 1); con('phi skok', 1, 'phi_ref', 2); con('suwak phi', 1, 'phi_ref', 3); con('XY na katy', 1, 'phi_ref', 4);
con('tryb', 1, 'theta_ref', 1); con('theta skok', 1, 'theta_ref', 2); con('suwak theta', 1, 'theta_ref', 3); con('XY na katy', 2, 'theta_ref', 4);
% regulator polozenia
con('x skok', 1, 'rampa x', 1); con('rampa x', 1, 'ex', 1); con('Demux XYZ', 1, 'ex', 2); con('ex', 1, 'PID X', 1);
con('y skok', 1, 'rampa y', 1); con('rampa y', 1, 'ey', 1); con('Demux XYZ', 2, 'ey', 2); con('ey', 1, 'PID Y', 1);
con('PID X', 1, 'XY na katy', 1); con('PID Y', 1, 'XY na katy', 2); con('Demux katy', 3, 'XY na katy', 3);
% petle z, roll, pitch, yaw
con('z_ref', 1, 'e_z', 1); con('Demux XYZ', 3, 'e_z', 2);
con('phi_ref', 1, 'e_phi', 1); con('Demux katy', 1, 'e_phi', 2);
con('theta_ref', 1, 'e_theta', 1); con('Demux katy', 2, 'e_theta', 2);
con('r_ref', 1, 'e_r', 1); con('Demux w_b', 3, 'e_r', 2);
for i = 1:4, con(['e_' pid{i, 2}], 1, pid{i, 1}, 1); end
con('PID1', 1, 'limit dT', 1); con('limit dT', 1, 'Suma ciagu', 1); con('m*g(3)', 1, 'Suma ciagu', 2); con('Suma ciagu', 1, 'Mux U', 1);
con('PID2', 1, '-1 roll', 1); con('-1 roll', 1, 'Mux U', 2);
con('PID3', 1, '-1 pitch', 1); con('-1 pitch', 1, 'Mux U', 3);
con('PID4', 1, 'Mux U', 4);
con('Mux U', 1, 'A^{-1}', 1); con('A^{-1}', 1, 'sqrt', 1); con('sqrt', 1, 'Saturation', 1);
con('Saturation', 1, 'kierunki obrotu', 1);
con('regulator', 1, 'sterowanie', 1); con('RotorSpeed', 1, 'sterowanie', 2); con('kierunki obrotu', 1, 'sterowanie', 3);
con('sterowanie', 1, 'DJIF450Rotors', 1);
% scope'y
con('z_ref', 1, 'Mux z', 1); con('Demux XYZ', 3, 'Mux z', 2); con('Mux z', 1, 'Scope z', 1);
con('phi_ref', 1, 'Mux phi', 1); con('Demux katy', 1, 'Mux phi', 2); con('Mux phi', 1, 'Scope phi', 1);
con('theta_ref', 1, 'Mux theta', 1); con('Demux katy', 2, 'Mux theta', 2); con('Mux theta', 1, 'Scope theta', 1);
con('r_ref', 1, 'Mux r', 1); con('Demux w_b', 3, 'Mux r', 2); con('Mux r', 1, 'Scope r', 1);
con('psi skok', 1, 'Mux psi', 1); con('Demux katy', 3, 'Mux psi', 2); con('Mux psi', 1, 'Scope psi', 1);
con('rampa x', 1, 'Mux XY', 1); con('Demux XYZ', 1, 'Mux XY', 2); con('rampa y', 1, 'Mux XY', 3);
con('Demux XYZ', 2, 'Mux XY', 4); con('Mux XY', 1, 'Scope XY', 1);

%% Opisy scope'ow
sc = {'z', 'z [m]', {'z_{ref}', 'z'}; 'phi', '\phi [rad]', {'\phi_{ref}', '\phi'}; ...
      'theta', '\theta [rad]', {'\theta_{ref}', '\theta'}; 'r', 'r [rad/s]', {'r_{ref}', 'r'}; ...
      'psi', '\psi [rad]', {'\psi_{ref}', '\psi'}; ...
      'XY', 'x, y [m]', {'x_{ref}', 'x', 'y_{ref}', 'y'}};
for i = 1:size(sc, 1)
    cfg = get_param([mdl '/Scope ' sc{i, 1}], 'ScopeConfiguration');
    cfg.ShowLegend = true; cfg.ShowGrid = true; cfg.YLabel = sc{i, 2}; cfg.Title = sc{i, 1};
    cfg.TimeSpanOverrunAction = 'Scroll';
end

%% Zapis przebiegow (signal logging)
logs = {'z_ref', 1, 'z_ref'; 'Demux XYZ', 3, 'h'; 'phi_ref', 1, 'phi_ref'; 'theta_ref', 1, 'theta_ref'; ...
        'r_ref', 1, 'r_ref'; 'psi skok', 1, 'psi_ref'; 'rampa x', 1, 'x_ref'; 'rampa y', 1, 'y_ref'; ...
        dof, 2, 'Xe'; dof, 1, 'Ve'; dof, 3, 'eul'; dof, 7, 'wb'; 'sterowanie', 1, 'Omega'; ...
        'DJIF450Rotors', 1, 'Frot'; 'DJIF450Rotors', 2, 'Mrot'};
for i = 1:size(logs, 1)
    set_param(pn(logs{i, 1}).Outport(logs{i, 2}), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', ...
        'DataLoggingName', logs{i, 3});
end

%% Solver
set_param(mdl, 'StopTime', '20', 'Solver', 'ode45', 'MaxStep', '0.01', 'RelTol', '1e-6', ...
    'ReturnWorkspaceOutputs', 'on', 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');
save_system(mdl, fullfile(here, [mdl '.slx']));
fprintf('Zapisano %s.slx\n', mdl);
