function Fd = bodyDrag(Vb, Vw_b, rho, CD_S) %#codegen
% Sila oporu aerodynamicznego w ukladzie zwiazanym z BSP (jak na slajdzie 50 wykladu)
% Vb, Vw_b: [3x1] m/s; rho: kg/m^3; CD_S: [3x1] = [Cd_x*Sx; Cd_y*Sy; Cd_z*Sz] m^2
Vrel = Vb(:) - Vw_b(:);
Fdx = -0.5*rho*CD_S(1)*abs(Vrel(1))*Vrel(1);
Fdy = -0.5*rho*CD_S(2)*abs(Vrel(2))*Vrel(2);
Fdz = -0.5*rho*CD_S(3)*abs(Vrel(3))*Vrel(3);
Fd = [Fdx; Fdy; Fdz];
end
