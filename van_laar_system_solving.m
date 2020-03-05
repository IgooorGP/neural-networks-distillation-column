% ***************************** Resolução ELV ****************************** %
% ** EQ050: Operação e Simulação de uma Coluna de Redestilação de Cachaça ** %
% ******************* Ígor Grillo Peternella R.A.: 106717 ****************** %
% ************ Faculdade de Engenharia Química - Unicamp ******************* %

storer = zeros(40, 5);
i = 1;
syms T;

P = 760; % mmHg

% Constantes de Van Laar (ag = água; et = etanol)

Kag = 0.952;

Ket = 1.689;

% Constantes de Antoine

A_ag = 8.07;

B_ag = 1730.63;

C_ag = 233.43;

A_et = 8.21;

B_et = 1652.05;

C_et = 231.4;

% Início da rotina com fração molar de etanol = 0.01

x_et = 0.01;

while x_et <= 1

% Fração molar de água

x_ag = 1 - x_et;

% Modelo de Van Laar: equações 3.1.15 e 3.1.16

coefAtv_ag = exp(Kag * ((Ket * x_et)/(Kag * x_ag + Ket * x_et))^2);

coefAtv_et = exp(Ket * ((Kag * x_ag)/(Kag * x_ag + Ket * x_et))^2);

% Resolução da equação 3.1.13A

T = solve(1 - (1/P)*(coefAtv_ag * x_ag * (10^(A_ag - B_ag/(T + C_ag))) + coefAtv_et * x_et * (10^(A_et - B_et/(T + C_et)))) == 0, T);

% Obtenção da fração molar da fase gasosa através da equação 3.1.13C

y_ag = coefAtv_ag * x_ag * 10^(A_ag - B_ag/(T + C_ag))/P;

y_et = coefAtv_et * x_et * 10^(A_et - B_et/(T + C_et))/P;

% Matriz para armazenamento de dados

storer(i,1) = x_ag;

storer(i,2) = x_et;

storer(i,3) = T;

storer(i,4) = y_ag;

storer(i,5) = y_et;

% Incremento na fração molar de etanol para posterior decremento da fração molar de água

x_et = x_et + 0.01;

i = i + 1;

T = 0;

syms T


end