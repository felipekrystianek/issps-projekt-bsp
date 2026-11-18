function [phi_ref, theta_ref] = xy_na_katy(ux, uy, psi) %#codegen
% Zamienia wyjscia regulatorow X, Y (uklad ziemski) na zadane katy roll i pitch.
% Najpierw obrot o kat yaw do ukladu BSP, potem: zeby leciec do przodu (+x) BSP pochyla nos w dol
% (theta < 0), a zeby leciec w prawo (+y) przechyla sie w prawo (phi > 0).
kat_max = pi/8;                          % ograniczenie przechylenia
ub = cos(psi)*ux + sin(psi)*uy;          % do przodu w ukladzie BSP
vb = -sin(psi)*ux + cos(psi)*uy;         % w prawo w ukladzie BSP
theta_ref = min(max(-ub, -kat_max), kat_max);
phi_ref = min(max(vb, -kat_max), kat_max);
end
