% *************************** Programa Principal *************************** %
% ** EQ050: Operação e Simulação de uma Coluna de Redestilação de Cachaça ** %
% ******************* Ígor Grillo Peternella R.A.: 106717 ****************** %
% ************ Faculdade de Engenharia Química - Unicamp ******************* %

% Função do matlab para gravar o tempo total de simulação requerido (termina com toc;)

tic;

% Mensagem de inicialização do programa para o usuário

fprintf('Welcome to the Batch Distillation Simulator (BatchSim) v1.0.\nThis program belongs to the School Of Chemical Engineering - UNICAMP.\n');

% Passo fixo de integração

step = 0.5; % s

% Requisição ao usuário sobre o tempo total de simulação.

simTime = input('Please insert the simulation time in seconds:\n'); % s

% Vetor para gráficos (composição de cada estágio)

STAGES = 1:1:14;

size = simTime/step; % Tamanho dos vetores gráficos

T = 0:step:simTime; % Criação do vetor tempo para gráficos

compoundsNumber = 2; % Número de componentes na simulação (água e etanol)

j = 2; % Contador para gráficos

k = 1; % Contador para gráficos

X_w = zeros(compoundsNumber, size); % Cria vetor para armazenamento de dados (fração molar água)

X_et = zeros(compoundsNumber, size); % Cria vetor para armazenamento de dados (fração molar etanol)

T_trays = zeros(14, size); % Cria vetor para armazenamento de dados (temperatura)

Ln_plot = zeros(15, size); Cria vetor para armazenamento de dados (vazões molares líquidas)


Vn_plot = zeros(14, size); Cria vetor para armazenamento de dados (vazões molares gasosas)


Mn_plot = zeros(14, size); Cria vetor para armazenamento de dados (hold-up’s)

% Invoca o algoritmo de inicialização para fornecer as condições iniciais da coluna

Initialization 

% Início da simulação

for t = 0:step:simTime 

    % t > 0 é uma condição que garante que esta parte do algoritmo não será executada em t = 0, tempo no qual o algoritmo de inicialização realiza tais cálculos.
	
    if t > 0

	% Loop para cálculo das temperaturas de equilíbrio, frações molares gasosas
	% Densidades, entalpias e vazões molares LÍQUIDAS

        for i = 14:-1:1 

            
             if i == 14 % Inserção das frações molars líquidas na rede neural

                input_NN(1, 1) = tray(i).x_w;

                input_NN(1, 2) = tray(i).x_et;

                % Saída da rede neural treinada trNet: frações molares gasosas e 
                % temperatura de equilíbrio

                output_NN = trNet(input_NN');

	        % Atribuição da temperatura da rede neural para o refervedor 

                tray(i).trayT = output_NN(1, 1);

                % Armazenamento da temperatura para gráficos

                if t ~= simTime

                    T_trays(i, k) = tray(i).trayT;

                End

		% Atribuição das frações molares gasosas da rede neural para o  
		% refervedor

                tray(i).y_w = output_NN(2, 1);

                tray(i).y_et = output_NN(3, 1);

		% Cálculo das densidades e entalpias líquidas e gasosas

                 tray(i).densityCalc();

                 tray(i).enthalpyCalc();

             elseif i ~= 1 && i ~= 14   % Procedimento análogo para os pratos

		% Inserção das frações molars líquidas na rede neural

                input_NN(1, 1) = tray(i).x_w;

                input_NN(1, 2) = tray(i).x_et;

                % Saída da rede neural treinada trNet: frações molares gasosas e 
                % temperatura de equilíbrio

                output_NN = trNet(input_NN');

                % Atribuição da temperatura da rede neural para cada prato

                tray(i).trayT = output_NN(1, 1);

                % graph T

                T_trays(i, k) = tray(i).trayT;

                % Atribuição das frações molares gasosas ideais para cada prato 

                tray(i).y_w = output_NN(2, 1);

                tray(i).y_et = output_NN(3, 1);

                % Cálculo da eficiência de Murphree para os pratos

                tray(i).murphreeEfficiency(tray(i+1).y_et, tray(i+1).y_w);

                % Cálculos de densidade, entalpias líquidas e gasosas

                tray(i).densityCalc();

                tray(i).enthalpyCalc();

		% Cálculo da vazão molar líquida de cada prato

                tray(i).liquidFlow();

                % Armazenamento da vazão molar líquida para gráficos

                Ln_plot(i, k) = tray(i).Ln; % does not execute for t = 0;

             elseif i == 1 % Procedimento análogo para o condensador

   		% Cálculos de densidade e entalpia líquida (condensador total)

                tray(i).densityCalc();

                tray(i).enthalpyCalc();

             end

        end

    end

    if t == 0 % Algoritmo para t = 0, após o algoritmo de inicialização ser executado 
    % para computar as eficiências de murphree e cálculos de densidade, entalpia, etc.
    % que não são executados no algoritmo de inicialização.

        for i = 14:-1:1 

            if i ~= 1 && i ~= 14 % Eficiências de Murphree para os pratos

                tray(i).murphreeEfficiency(tray(i+1).y_et, tray(i+1).y_w);

            end

	   % Cálculo das densidades e entalpias líquidas e gasosas

            tray(i).densityCalc();

            tray(i).enthalpyCalc();

            % Cálculo das vazões molars líquidas (exceto para refervedor e condensador)

            if i ~= 1 && i ~= 14 

                tray(i).liquidFlow();

                % Armazenamento das vazões líquidas molars para gráficos 

                Ln_plot(i, k) = tray(i).Ln;

            end

        end

    end

    % Loop para cálculo das vazões molares GASOSAS

    for i = 14:-1:1 

        if i == 14  % Reboiler

           tray(i).vaporFlowReboiler(tray(i-1).x_et, tray(i-1).h_tray, tray(i-1).Ln)

	   % Armazenamento das vazões gasosas molares para gráficos

             Vn_plot(i, k) = tray(i).Vn;


        elseif i ~= 1 && i ~= 2 && i ~= 14 % Vazões molares gasosas para todos os pratos exceto o primeiro e o condensador


            tray(i).vaporFlow(tray(i-1).x_et, tray(i+1).y_et, tray(i-1).h_tray, tray(i+1).H_tray, tray(i-1).Ln, tray(i+1).Vn)

            % Armazenamento das vazões gasosas molares para gráficos

             Vn_plot(i, k) = tray(i).Vn;

        elseif i == 2 % Vazão molar gasosa do primeiro prato (com refluxo)

            tray(i).vaporFlowSecTray(tray(i-1).x_et, tray(i+1).y_et, tray(i-1).h_tray, tray(i+1).H_tray, tray(i+1).Vn, tray(i-1).R) % for V2

             % Armazenamento das vazões gasosas molares para gráficos

             Vn_plot(i, k) = tray(i).Vn;

	% Balanço de massa TOTAL para o condensador: % Obtenção de L0 e D pois V1 é
        % conhecido.

        elseif i == 1 

	    % Balanço de massa total para o condensador: obtenção de L0

            tray(i).Ln = tray(i).R * tray(i+1).Vn/(tray(i).R + 1); 

            % Armazenamento das vazões líquidas molares para gráficos

             Ln_plot(i, k) = tray(i).Ln;

	    % Balanço de massa total para o condensador: obtenção de D

             tray(i).D = tray(i+1).Vn/(tray(i).R + 1 ); 

            % Armazenamento das vazões líquidas molares para gráficos

            Ln_plot(15, k) = tray(i).D;

        end

    end

    % Loop para Balanços de massa total e por componentes de toda coluna


    for i = 14:-1:1

	% Balanço de massa do refervedor

        if i == 14

            tray(i).reboilerMassBalance(tray(i-1).x_et, tray(i-1).Ln, step);

	   % Armazenamento das frações molares líquidas para gráficos

            if t ~= simTime

                X_w(i, j) = tray(i).x_w;

                X_et(i ,j) = tray(i).x_et;

                %% Armazenamento dos hold-up’s molares para gráficos

                Mn_plot(i ,j) = tray(i).Mn;

            end

	% Balanço de massa para os pratos

        elseif i ~= 1 && i ~= 14

            tray(i).trayMassBalance(tray(i-1).x_et, tray(i+1).y_et, tray(i+1).Vn, tray(i-1).Ln, step);

            if t ~= simTime

	        % Armazenamento das frações molares líquidas para gráficos

                X_w(i, j) = tray(i).x_w;

                X_et(i ,j) = tray(i).x_et;

                % Armazenamento dos hold-up’s para gráficos

                Mn_plot(i ,j) = tray(i).Mn;

            end



        elseif i == 1

	    % Balanço de massa por componente para o condensador

            tray(i).condenserMassEnergyBalance(tray(i+1).y_et, tray(i+1).Vn, tray(i+1).H_tray, step);

            if t ~= simTime

	       % Armazenamento das frações molares líquidas para gráficos

                X_w(i, j) = tray(i).x_w;

                X_et(i ,j) = tray(i).x_et;

                % Armazenamento dos hold-up’s para gráficos

                Mn_plot(i ,j) = tray(i).Mn;

                % Armazenamento da temperatura constante do condensador (25 oC)

                T_trays(i, j) = tray(i).trayT;

            end

        end

    end

    j = j + 1; % Atualização dos índices das matrizes de gráficos

    k = k + 1; % Atualização dos índices das matrizes de gráficos
end
% Criação de gráficos da temperatura dos estágios vs tempo e composição do destilado
% vs tempo
figure; 

graph1 = subplot(1, 2, 1); 

plot(graph1, T, T_trays, 'b-', T, T_trays), 'g-'); % Temperatura vs tempo

title(graph1, 'Temperatura vs time');

ylabel(graph1, 'Temperatura (oC));

xlabel(graph1, 'Time (s)');

legend('Condenser','Stage 1', 'Stage2', 'Stage 3', 'Stage 4' ,'Stage 5', 'Stage 6', 'Stage 7', 'Stage 8', 'Stage 9', 'Stage 10', 'Stage 11', 'Stage 12', 'Reboiler');

axis([1, 14, 0, 1]);

graph2 = subplot(1, 2, 2);

plot(graph2, T, X_et(1,:), 'b-', T, X_w(1,:), 'g-'); % composição do destilado vs tempo

title(graph2, 'Ethanol composition over time for the distillate');

ylabel(graph2, 'Molar fraction of Ethanol');

xlabel(graph2, 'Time (s)');legend('Ethanol','Water');

totalTime = toc; % Fim da contagem de tempo da simulação.   