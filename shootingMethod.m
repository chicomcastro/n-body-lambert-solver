%% script shootingMethod
% Performs shooting method to find a solution for orbit from given initial
% conditions

%clear;

% Do not change this (see showResults.m)
global shouldPlot;
shouldPlot = 0;

theta = 0;
tolerance = .1;
t = [];
scale_factor = 1;

%% Pr� declarations and calculations
% This is the section that can be security changed to fit your problem
% Others section can cause problems to change, then it's your risk
loadData;

t_voo = pi;   % Simulation time [ut]
initial_velocity_guess = V_hohmann_earth_venus;	% [km/s]

initial_pos = (R_earth_sun * [1 0 0] + altitude_from_earth * [1 0 0]);	% [m]

%% Initial state struct
initial_state.t_voo = t_voo;                % [ut] (not [s], see normalization.m)
initial_state.initial_pos = initial_pos;    % [m]
initial_state.v0 = initial_velocity_guess * Rz(theta) * scale_factor;  % [km/s]

x = initial_state;

%% Main loop
itr = 1;
delta = .1;
error = [];
erro_dist = ones(1,3)*ud;
disp("Iniciando busca de uma solu��o...");
tic
while norm(erro_dist)/ud > tolerance
    
    if mod(itr, 10) == 0
        disp("---");
        disp("Itera��o: " + itr);
        disp("Error: " + norm(erro_dist)/ud);
    end
    
    itr = itr + 1;
    x1 = x;
    result = simulate(x1);
    
    % vx variation
    xx = x;
    xx.v0 = xx.v0 + delta*[1,0,0];
    result_dx = simulate(xx);
    dxdvx = (result_dx.x_t2 - result.x_t2)/delta;
    
    % vy variation
    xy = x;
    xy.v0 = xy.v0 + delta*[0,1,0];
    result_dy = simulate(xy);
    dxdvy = (result_dy.x_t2 - result.x_t2)/delta;
    
    % vz variation
    xz = x;
    xz.v0 = xz.v0 + delta*[0,0,1];
    result_dz = simulate(xz);
    dxdvz = (result_dz.x_t2 - result.x_t2)/delta;
    
    % variation matrix
    dXdV = [dxdvx; dxdvy; dxdvz]';                  % [s]
    
    % velocity correction
    erro_dist = result.error;                       % [m]
    if erro_dist < Inf
        delta_velocidade = -1*dXdV\erro_dist(:);        % [m/s]
        x.v0 = x.v0 + delta_velocidade(:)'/1000;        % [km/s]
    else
        disp("Bad initial conditions, giving up due to ode time limit (see runIntegration.m)");
        break;
    end
end
t(end+1) = toc
%%
if erro_dist < Inf
    disp("Solu��o encontrada!");
    disp(x);
    disp("Custo de sa�da: " + norm(x.v0 - V_earth_sun*[0,1,0]/1000) + " km/s");
    
    V_sai_terra = x.v0;
    v_inf = (V_sai_terra*1000 - V_earth_sun*[0,1,0]);   % V_saida em rela��o � Terra[m/s]
    v_saida = sqrt(norm(v_inf)^2 + 2*G_metric*M_earth/(altitude_from_earth + R_earth)); % V_p que vai dar V_inf na sa�da hiperb�lica
    delta_v_saida_terra_2B = norm(v_saida - V_oe_earth)/1000;   % delta V de sa�da por 2B [km/s]
    disp("Custo de sa�da 2B: " + delta_v_saida_terra_2B + " km/s");
    
    shouldPlot = 1;
    simulate(x);
    shouldPlot = 0;
    fig_title = replace(...
        "t-"+x.t_voo+"-v0-"+x.v0(1)+"-"+x.v0(2)+"-tol-"+tolerance,...
        '.',...
        'd'...
    );
    saveas(gcf,fig_title+".png")
end
