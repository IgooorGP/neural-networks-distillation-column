% ********************** Algoritmo de Inicialização ************************ %
% ** EQ050: Operação e Simulação de uma Coluna de Redestilação de Cachaça ** %
% ******************* Ígor Grillo Peternella R.A.: 106717 ****************** %
% ************ Faculdade de Engenharia Química - Unicamp ******************* %

% Carregamento da rede neural treinada com os dados do algoritmo de pré-resolução do ELV (Apêndice D) 

load('trNet.mat') 

% Criação de um vetor contendo 14 objetos criados a partir da classe prato (ver algoritmo de classe no Apêndice F) 

tray(14) = tray();

% Requisição ao usuário sobre as frações molares iniciais no refervedor da coluna

x_et_initial = input('Please insert the molar fraction of ethanol in the reboiler:\n');

x_w_initial = input('Please insert the molar fraction of water in the reboiler:\n');

% Criação de vetores para enviar e receber dados da rede neural treinada (trNet.mat)

input_NN = [0, 0];

output_NN = [0; 0; 0];

% Requisição ao usuário sobre a carga térmica do refervedor, razão de refluxo, volume de líquido no refervedor para estimar o Hold-up neste estágio e a eficiência de Murphree da coluna

boilerHeatDuty_userInput = input('Please insert the heat duty of the boiler in Watts:\n');

R_userInput = input('Please insert the Reflux Ratio for the column:\n');

Vboiler_userInput = input('Please insert the initial volume of liquid in the boiler in ml\n');

Em_userInput = input('Please insert the overall Murphree efficieny:\n ');

% Loop para fornecer aos objetos (pratos) suas frações molares iniciais. i = 1 refere-se ao condensador e i = 14 refere-se ao refervedor

for i = 14:-1:1 

     tray(i).x_et = x_et_initial;

     tray(i).x_w = x_w_initial;


     

    % Armazenamento de dados em vetores para criação de gráficos

     X_w(i, 1) = tray(i).x_w;

     X_et(i, 1) = tray(i).x_et;

     if i == 14 % para o refervedor 

	% Inserção da fração molar de etanol e de água do refervedor na rede neural

        input_NN(1, 1) = tray(i).x_w;

        input_NN(1, 2) = tray(i).x_et;

        % Saída da rede neural para o refervedor: y_et, y_w, Tn

        output_NN = trNet(input_NN');

	% Atribuição da temperatura de equilíbrio ao objeto (refervedor)

        tray(i).trayT = output_NN(1, 1);

      	% Armazenamento da temperatura para criação de gráficos

        T_trays(i, 1) = tray(i).trayT;

        % Atribuição das frações molares gasosas ao objeto (refervedor)

        tray(i).y_w = output_NN(2, 1);

        tray(i).y_et = output_NN(3, 1);

	% Cálculo da densidade inicial do líquido do refervedor

        tray(i).densityCalc();

	% Atribuição ao objeto refervedor do volume inicial, da carga térmica

        tray(i).V_boiler = Vboiler_userInput; % cm^3

        tray(i).Qn = boilerHeatDuty_userInput; % W (Reboiler Duty)

	% Estimativa do hold-up inicial do refervedor

        tray(i).boilerEstimate(); % initial molar hold up for the boiler

	% Vetor de gráficos de hold-up
	
        Mn_plot(i, 1) = tray(i).Mn;

        % Atribuição da eficiência de murphree ao refervedor (ideal)

        tray(i).Em = 1;


     elseif i ~= 1 && i ~= 14   % Procedimento análogo para todos os pratos (menos  condensador)


	% Inserção da fração molar de etanol e de água na rede neural
	
	input_NN(1, 1) = tray(i).x_w;

        input_NN(1, 2) = tray(i).x_et;

        % Saída da rede neural para o refervedor: y_et, y_w, Tn

        output_NN = trNet(input_NN');
	
	% Atribuição da temperatura de equilíbrio ao objeto (prato)

        tray(i).trayT = output_NN(1, 1);

        % Armazenamento da temperatura para criação de gráficos

        T_trays(i, 1) = tray(i).trayT;

        % Atribuição das frações molares gasosas ao objeto (prato)

        tray(i).y_w = output_NN(2, 1);

        tray(i).y_et = output_NN(3, 1);

	% Cálculo da densidade inicial do líquido nos pratos

        tray(i).densityCalc();
	
	% Atribuição da eficiência de murphree ao refervedor (ideal)
	
        tray(i).Em = Em_userInput;

	% Estimativa do nível inicial em cada prato (2 mm)

        tray(i).ln = 0.2; % cm

	% Estimativa do hold-up inicial dos pratos baseado no nível de 2 mm.

        tray(i).trayEstimate(); 

	% Vetor de gráficos de hold-up
	
        Mn_plot(i, 1) = tray(i).Mn;


     elseif i == 1  % Procedimento análogo para o condensador

            tray(i).ln = 0.2; % nível inicial do condensador

            tray(i).x_et = x_et_initial; % Frações molares iniciais do líquido

            tray(i).x_w = x_w_initial;

            tray(i).y_et = 0; % Frações molares inicias gasosas (condensador total)

            tray(i).y_w = 0;

	   % Temperatura do condensador fixa em 25 oC

            tray(i).trayT = 25;

            % Armazenamento da temperatura para criação de gráficos

            T_trays(i, 1) = tray(i).trayT;

	   % Cálculo da densidade

            tray(i).densityCalc();

	   % Estimativa inicial do hold-up do condensador

            tray(i).trayEstimate();

            % Gráfico de hold-up

            Mn_plot(i, 1) = tray(i).Mn;

            % Atribuição da razão de refluxo do usuário

            tray(i).R = R_userInput; 

     end

end