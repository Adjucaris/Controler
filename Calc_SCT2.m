clear;
clc;
%% Especifications
s = tf('s');

% Planta Teórica
% Componentes
R  =  10*(10^3);    R1 =  68*(10^3);    R2 =  13*(10^3);
C  = 180*(10^-9);   C1 = 100*(10^-9);   C2 = 680*(10^-9);

% Função de Transferencia Simulada
num = 1;    
den1 = [(R*C) 1];   
den2 = [(C1*C2*R1*R2) ((C1*R2)+(C1*R1)) 1];

Blc1 = tf(num, den1);   % Bloco 1 (Primeira Ordem)
Blc2 = tf(num, den2);   % Bloco 2 (Segunda Ordem)

Trf = Blc1*Blc2;        % Terceira Ordem
Trf = minreal(Trf);

% Especificações da planta prática
ts1 = 5.2e-3;   %Tempo de subida de primeira ordem
Mp = 0.32/1.88;  %Sobresinal
tp = 27.8e-3;    %Tempo de pico (segunda ordem)

% Bloco primeira ordem
tau = (0.95*ts1)/3;
G1 = 1/(tau*s+1);

% Bloco segunda ordem
zeta = fzero(@(x) ((log(Mp)/pi) + (x/sqrt(1-x^2))), 0.5);
wn = pi/(tp*sqrt(1-zeta^2));
G2 = (wn^2)/(s^2 + 2*zeta*wn*s + wn^2);
ts2 = 3/(zeta*wn);

% Planta Prática Contínua
G = G1*G2;
G = minreal(G);

% % Mostrar localização dos polos dominantes
%{
pzmap(G);
xlim([-75 -50]);
%}

%% Controlador
% Requisitos
Mp = Mp/2;
ts = ts2/2;
zeta = fzero(@(x) ((log(Mp)/pi) + (x/sqrt(1-x^2))), 0.5);
wn = 3/(ts*zeta);
Fs_required = (10*wn*sqrt(1-zeta^2))/(2*pi);
Fs = 258;
Ts = 1/Fs;
z = tf('z',Ts);

wd = wn*sqrt(1-(zeta^2));
ws = (2*pi)/Ts;

mod_z = exp(((-2*pi*zeta)/(sqrt(1-(zeta^2))))*(wd/ws));
ang_g = 2*pi*(wd/ws);

[zx, zy] = pol2cart(ang_g, mod_z);
z1 = complex(zx, zy);

%z1 = 0.228 + 0.08i; % ponto z que deseja ser parte do lugar das raízes
% Planta Prática Discreta
Gz = c2d(G,Ts);

% Mostrar Requisitos
%{
figure;
pzmap(Gz,(1/((z-z1)*(z-z1'))));
zgrid(zeta,wn*Ts);
legend('Planta','Desejado')
%}

angle_required = -(angle(evalfr(Gz,z1)) - pi);
% O controlador anula os polos complexos da planta e contém um integrador,
% portanto só precisamos encontrar o valor de um pólo para satisfazer a
% condição de ângulo
zeros_planta = pole(Gz);
angulo_polo = angle(z1 - zeros_planta(1)) + angle(z1 - zeros_planta(2)) - angle(z1 - 1) - angle_required;
polo_desejado = real(z1) - imag(z1)/tan(angulo_polo);
Cz_semK = ((z-zeros_planta(1))*(z-zeros_planta(2)))/((z-polo_desejado)*(z-1));
K = abs(1/(evalfr(minreal(Cz_semK*Gz), z1)));
Cz = K*Cz_semK;
FTMA = minreal(Cz*Gz);
FTMF = minreal(feedback(FTMA,1));
[numg, deng] = tfdata(G, 'v');
[numgz, dengz] = tfdata(Gz,'v');
[numc, denc] = tfdata(Cz,'v');

%Polos apos correção
%{
pzmap(Gz*Cz,(1/((z-z1)*(z-z1'))));
%}

%{
angulo = (180/(pi*angle(z1+zeros_planta(1)))) + (180/(pi*angle(z1+zeros_planta(2)))) + (180/(pi*angle(z1+zeros_planta(3))));
zup = zero(Gz);
zeros = (180/(pi*angle(z1+zup(1)))) + (180/(pi*angle(z1+zup(2))));
retailer = angulo + zeros
%}

%Comparação de resposta ao degrau do circuito calculado vs  medido
%{
hold on
step(G)
step(Trf, '*')
hold off
legend('Pratico','Ideal')
%}