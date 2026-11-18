% Badania do projektu (sekcja P2): zad. 1 (dynamika) i zad. 2 (sterowanie) dla P2 i konfiguracji referencyjnej REF
% Wykresy do ../docs/img, wyniki do ../docs/wyniki.json. Obie konfiguracje licza sie na tym samym modelu quad_P2.slx,
% zmieniaja sie tylko m, I i CDxS (jak w zasadach projektu).
here = fileparts(mfilename('fullpath')); cd(here);
img = fullfile(here, '..', 'docs', 'img'); if ~exist(img, 'dir'), mkdir(img); end
mdl = 'quad_P2';
if ~exist([mdl '.slx'], 'file'), build_P2; end
load_system(mdl);

% konfiguracje (tab. 1 i 2 zadania projektowego)
K.REF = struct('m', 1.50, 'I', diag([0.0111 0.0070 0.0080]), 'CDxS', [0.0390 0.0455 0.0900]);
K.P2  = struct('m', 1.65, 'I', diag([0.0114 0.0073 0.0083]), 'CDxS', [0.0390 0.0455 0.0900]);
nazwy = {'REF', 'P2'};
g = 9.81; rho = 1.225; CT = 0.0142; R_rot = 0.127; dirs = [1 -1 1 -1];
Om_min = @(m, rho_) sqrt(m*g/(4*CT*rho_*pi*R_rot^4));
styl = {'--', '-'};   % REF przerywana, P2 ciagla
R = struct();

%% Zrzut modelu
print(['-s' mdl], '-dpng', '-r200', fullfile(img, 'model.png'));

%% Zadanie 1 - dynamika (regulator = 1, stale RotorSpeed)
H = [10 50 100];
for s = 1:2   % 2.1 bez oporu, 2.2 z oporem
    f = fig(); hold on; kol = lines(3);
    for n = 1:2
        c = K.(nazwy{n}); t_sp = zeros(1, 3); v_k = t_sp;
        for i = 1:3
            a = {'regulator', 1, 'RotorSpeed', [0 0 0 0], 'InitialPosition', [0 0 -H(i)]};
            if s == 1, a = [a {'CDxS', [0 0 0]}]; end
            o = symuluj(mdl, c, a, 10);
            [t, X] = sygnal(o, 'Xe'); [~, V] = sygnal(o, 'Ve'); h = -X(:, 3);
            j = find(h <= 0, 1); jj = [j-1 j];
            t_sp(i) = interp1(h(jj), t(jj), 0); v_k(i) = interp1(t(jj), V(jj, 3), t_sp(i));
            plot([t(1:j-1); t_sp(i)], [h(1:j-1); 0], styl{n}, 'Color', kol(i, :), ...
                'DisplayName', sprintf('%s, h_0 = %d m', nazwy{n}, H(i)));
        end
        R.(nazwy{n}).(sprintf('z2%d', s)) = struct('t', t_sp, 'v', v_k);
    end
    grid on; xlabel('t [s]'); ylabel('h [m]'); ylim([0 105]); legend('Location', 'northeast', 'NumColumns', 2);
    if s == 1
        title('Swobodny spadek bez oporu (\Omega = 0)'); zapisz(f, img, 'z21_spadek');
    else
        title('Swobodny spadek z oporem aerodynamicznym (\Omega = 0)'); zapisz(f, img, 'z22_spadek_opor');
    end
end

% 2.3 i 2.4 - zawis na 10 m dla m i m + 0,5 kg oraz dla dwoch gestosci powietrza
for n = 1:2
    c = K.(nazwy{n}); M = c.m + [0 0.5]; RHO = [1.225 1.0];
    for i = 1:2
        Om = Om_min(M(i), rho);
        o = symuluj(mdl, setfield(c, 'm', M(i)), {'regulator', 1, 'RotorSpeed', Om*dirs}, 20);
        [~, X] = sygnal(o, 'Xe');
        R.(nazwy{n}).z23.m(i) = M(i); R.(nazwy{n}).z23.Om(i) = Om; R.(nazwy{n}).z23.dh(i) = max(abs(-X(:, 3) - 10));
        Om = Om_min(c.m, RHO(i));
        o = symuluj(mdl, c, {'regulator', 1, 'RotorSpeed', Om*dirs, 'rho', RHO(i)}, 20);
        [~, X] = sygnal(o, 'Xe');
        R.(nazwy{n}).z24.rho(i) = RHO(i); R.(nazwy{n}).z24.Om(i) = Om; R.(nazwy{n}).z24.dh(i) = max(abs(-X(:, 3) - 10));
    end
    R.(nazwy{n}).z24.dproc = (R.(nazwy{n}).z24.Om(2) / R.(nazwy{n}).z24.Om(1) - 1) * 100;
end
f = fig(); tiledlayout(1, 2, 'TileSpacing', 'compact');
for p = 1:2
    nexttile; hold on;
    for n = 1:2
        c = K.(nazwy{n});
        if p == 1, Mi = c.m + [0 0.5]; else, Mi = c.m*[1 1]; end
        for i = 1:2
            if p == 1, Om = Om_min(Mi(i), rho); a = {'regulator', 1, 'RotorSpeed', Om*dirs}; cc = setfield(c, 'm', Mi(i));
                opis = sprintf('%s, m = %.2f kg', nazwy{n}, Mi(i));
            else, r_ = [1.225 1.0]; Om = Om_min(c.m, r_(i)); a = {'regulator', 1, 'RotorSpeed', Om*dirs, 'rho', r_(i)}; cc = c;
                opis = sprintf('%s, \\rho = %.3f kg/m^3', nazwy{n}, r_(i));
            end
            o = symuluj(mdl, cc, a, 20); [t, X] = sygnal(o, 'Xe');
            plot(t, -X(:, 3), styl{n}, 'DisplayName', opis);
        end
    end
    grid on; xlabel('t [s]'); ylabel('h [m]'); ylim([0 12]); legend('Location', 'southeast');
    if p == 1, title('Zawis dla m i m + 0,5 kg'); else, title('Zawis dla \rho = 1,225 i 1,0 kg/m^3'); end
end
set(f, 'Position', [0 0 1100 480]); zapisz(f, img, 'z23_z24_zawis');

% 2.5 - wznoszenie przy 1,2 Omega_min (bez oporu)
f = fig(); hold on;
for n = 1:2
    c = K.(nazwy{n}); Om = 1.2*Om_min(c.m, rho);
    o = symuluj(mdl, c, {'regulator', 1, 'RotorSpeed', Om*dirs, 'CDxS', [0 0 0]}, 15);
    [t, V] = sygnal(o, 'Ve'); vz = -V(:, 3);
    R.(nazwy{n}).z25 = struct('Om', Om, 'a', (vz(end) - vz(1))/(t(end) - t(1)), 'v15', interp1(t, vz, 15));
    plot(t, vz, styl{n}, 'DisplayName', sprintf('%s, \\Omega = %.2f rad/s', nazwy{n}, Om));
end
grid on; xlabel('t [s]'); ylabel('V_z [m/s]'); legend('Location', 'northwest');
title('Prędkość wznoszenia dla \Omega = 1,2\Omega_{min} (bez oporu)'); zapisz(f, img, 'z25_wznoszenie');

% 2.6 - wiatr 3 m/s wzdluz osi roll przez 10 s, bez regulatora
f = fig(); hold on;
for n = 1:2
    c = K.(nazwy{n});
    o = symuluj(mdl, c, {'regulator', 1, 'RotorSpeed', Om_min(c.m, rho)*dirs, 'Wind', [3 0 0]}, 10);
    [t, X] = sygnal(o, 'Xe'); [~, V] = sygnal(o, 'Ve');
    R.(nazwy{n}).z26 = struct('x10', X(end, 1), 'v10', V(end, 1));
    plot(t, X(:, 1), styl{n}, 'DisplayName', nazwy{n});
end
grid on; xlabel('t [s]'); ylabel('x [m]'); legend('Location', 'northwest');
title('Przemieszczenie BSP pod wpływem wiatru 3 m/s (bez regulatora)'); zapisz(f, img, 'z26_wiatr');

% 2.7 - wirnik nr 1 szybszy o 5 %
for n = 1:2
    c = K.(nazwy{n}); RS = Om_min(c.m, rho)*dirs; RS(1) = 1.05*RS(1);
    o = symuluj(mdl, c, {'regulator', 1, 'RotorSpeed', RS}, 0.3);
    [~, Mr] = sygnal(o, 'Mrot'); M = Mr(1, :);
    R.(nazwy{n}).z27 = struct('Om1', RS(1), 'M', M, 'dw', M ./ diag(c.I)');
end

%% Zadanie 2 - sterowanie (regulator = 2, nastawy z LAB6)
t0 = 1;
sc = {'z', {'z_cel', 15}, 20; 'phi', {'phi_cel', pi/8}, 20; 'theta', {'theta_cel', pi/8}, 20; 'r', {'r_cel', pi/12}, 20};
opis = {'z', 'z [m]', 'Skok wysokości 10 \rightarrow 15 m'; 'phi', '\phi [°]', 'Skok kąta roll o \pi/8'; ...
        'theta', '\theta [°]', 'Skok kąta pitch o \pi/8'; 'r', 'r [rad/s]', 'Skok prędkości yaw o \pi/12 rad/s'};
for k = 1:4
    f = fig(); hold on;
    for n = 1:2
        o = symuluj(mdl, K.(nazwy{n}), [{'regulator', 2, 'tryb', 1} sc{k, 2}], sc{k, 3});
        switch sc{k, 1}
            case 'z', [t, y] = sygnal(o, 'h'); [~, ref] = sygnal(o, 'z_ref'); y0 = 10; yk = 15; s = 1;
            case 'phi', [t, e] = sygnal(o, 'eul'); y = e(:, 1); [~, ref] = sygnal(o, 'phi_ref'); y0 = 0; yk = pi/8; s = 180/pi;
            case 'theta', [t, e] = sygnal(o, 'eul'); y = e(:, 2); [~, ref] = sygnal(o, 'theta_ref'); y0 = 0; yk = pi/8; s = 180/pi;
            case 'r', [t, w] = sygnal(o, 'wb'); y = w(:, 3); [~, ref] = sygnal(o, 'r_ref'); y0 = 0; yk = pi/12; s = 1;
        end
        R.(nazwy{n}).ster.(sc{k, 1}) = wskazniki(t, y, y0, yk, t0);
        if n == 1, plot(t, ref*s, ':k', 'DisplayName', 'wartość zadana'); end
        plot(t, y*s, styl{n}, 'DisplayName', nazwy{n});
    end
    grid on; xlabel('t [s]'); ylabel(opis{k, 2}); title(opis{k, 3}); legend('Location', 'southeast');
    zapisz(f, img, ['z2_' sc{k, 1}]);
end

% punkt docelowy (5, 5, 15) m i yaw pi/4, bez wiatru i z wiatrem 5 m/s + podmuch 3 m/s
cel = {'regulator', 2, 'tryb', 3, 'x_cel', 5, 'y_cel', 5, 'z_cel', 15, 'psi_cel', pi/4};
war = {'bez_wiatru', {}, 'bez wiatru'; 'wiatr', {'Wind', [5 0 0], 'Gust', [3 0 0], 't_gust', 30}, 'wiatr 5 m/s + podmuch 3 m/s (30-32 s)'};
for k = 1:2
    f = fig(); tiledlayout(3, 1, 'TileSpacing', 'compact'); ax = gobjects(3, 1);
    for a = 1:3, ax(a) = nexttile; hold on; grid on; end
    for n = 1:2
        o = symuluj(mdl, K.(nazwy{n}), [cel war{k, 2}], 50);
        [t, X] = sygnal(o, 'Xe'); [~, xr] = sygnal(o, 'x_ref'); [~, e] = sygnal(o, 'eul'); [~, zr] = sygnal(o, 'z_ref');
        p = true(size(t)); if k == 2, p = t < 30; end
        W = struct('x', wskazniki(t(p), X(p, 1), 0, 5, t0), 'y', wskazniki(t(p), X(p, 2), 0, 5, t0), ...
            'z', wskazniki(t, -X(:, 3), 10, 15, t0), 'psi', wskazniki(t, e(:, 3), 0, pi/4, t0));
        if k == 2
            q = t >= 30; W.podmuch = max(hypot(X(q, 1) - 5, X(q, 2) - 5)); W.uchyb_koniec = hypot(X(end, 1) - 5, X(end, 2) - 5);
        end
        R.(nazwy{n}).ster.(war{k, 1}) = W;
        if n == 1
            plot(ax(1), t, xr, ':k', 'DisplayName', 'x_{ref} = y_{ref}'); plot(ax(2), t, zr, ':k', 'DisplayName', 'z_{ref}');
            plot(ax(3), t, 45*(t >= t0), ':k', 'DisplayName', '\psi_{ref}');
        end
        kol = lines(2);
        plot(ax(1), t, X(:, 1), styl{n}, 'Color', kol(1, :), 'DisplayName', ['x ' nazwy{n}]);
        plot(ax(1), t, X(:, 2), styl{n}, 'Color', kol(2, :), 'DisplayName', ['y ' nazwy{n}]);
        plot(ax(2), t, -X(:, 3), styl{n}, 'Color', kol(1, :), 'DisplayName', nazwy{n});
        plot(ax(3), t, rad2deg(e(:, 3)), styl{n}, 'Color', kol(1, :), 'DisplayName', nazwy{n});
    end
    ylabel(ax(1), 'x, y [m]'); ylabel(ax(2), 'z [m]'); ylabel(ax(3), '\psi [°]'); xlabel(ax(3), 't [s]');
    title(ax(1), ['Lot do punktu (5, 5, 15) m, \psi = 45°, ' war{k, 3}]);
    for a = 1:3, legend(ax(a), 'Location', 'southeast'); if k == 2, xline(ax(a), 30, ':k', 'HandleVisibility', 'off'); end, end
    set(f, 'Position', [0 0 900 760]); zapisz(f, img, ['z2_xyz_' war{k, 1}]);
end

%% Zapis
fid = fopen(fullfile(here, '..', 'docs', 'wyniki.json'), 'w');
fprintf(fid, '%s', jsonencode(R, 'PrettyPrint', true)); fclose(fid);
disp(jsonencode(R, 'PrettyPrint', true));

%% Funkcje pomocnicze
function o = symuluj(mdl, c, a, T)
% ustawia konfiguracje (m, I, CDxS) i pozostale zmienne w Model Workspace, potem puszcza symulacje
in = Simulink.SimulationInput(mdl);
in = in.setVariable('m', c.m, 'Workspace', mdl); in = in.setVariable('I', c.I, 'Workspace', mdl);
in = in.setVariable('CDxS', c.CDxS, 'Workspace', mdl);
for j = 1:2:numel(a), in = in.setVariable(a{j}, a{j + 1}, 'Workspace', mdl); end
o = sim(in.setModelParameter('StopTime', num2str(T)));
end

function [t, d] = sygnal(o, nazwa)
% zapisany sygnal jako czas + macierz (wiersz = chwila czasu)
ts = o.logsout.get(nazwa).Values; d = squeeze(ts.Data); t = ts.Time;
if size(d, 1) ~= numel(t), d = d'; end
end

function w = wskazniki(t, y, y0, yk, t0)
% przeregulowanie [%], czas ustalania (pasmo 2 % i 5 %) liczony od skoku [s], uchyb ustalony
dy = yk - y0; e = (y - yk) / dy;
w.przeregulowanie = max(0, max(e)) * 100;
i = find(abs(e) > 0.02, 1, 'last');
if isempty(i), w.t_ust = 0; else, w.t_ust = t(min(i + 1, end)) - t0; end
i = find(abs(e) > 0.05, 1, 'last');
if isempty(i), w.t_ust5 = 0; else, w.t_ust5 = t(min(i + 1, end)) - t0; end
w.uchyb = abs(y(end) - yk);
end

function f = fig()
% nowe okno wykresu
f = figure('Visible', 'off', 'Units', 'pixels', 'Position', [0 0 900 480], 'Color', 'w');
set(f, 'DefaultAxesFontSize', 11, 'DefaultLineLineWidth', 1.5);
end

function zapisz(f, img, nazwa)
% zapis do png
exportgraphics(f, fullfile(img, [nazwa '.png']), 'Resolution', 200); close(f);
end
