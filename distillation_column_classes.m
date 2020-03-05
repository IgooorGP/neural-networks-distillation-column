% ********************** Classe e Suas Definições ************************** %
% ** EQ050: Operação e Simulação de uma Coluna de Redestilação de Cachaça ** %
% ******************* Ígor Grillo Peternella R.A.: 106717 ****************** %
% ************ Faculdade de Engenharia Química - Unicamp ******************* %

classdef tray < handle

	
    properties % ****** Variáveis de instância dos objetos ****** %

        % --- Constantes --- %

        P = 760; % mmHg (Pressão atmosférica)

        MW_w = 18.015; % Massa molar água g/mol

        MW_et = 46.068; % Massa molar etanol g/mol

        Ap = 39.2 % Área dos pratos cm^2

        V_boiler % Volume da mistura do refervedor (cm^3)

        Hw = 0 % cm (Altura do vertedouro)

        Em % Eficiência de Murphree

        R % Razão de refluxo

        % --- Constantes --- %

        % --- Valores das redes neurais --- %

        x_et; % Fração molar líquida de etanol

        x_w; % Fração molar líquida de água

        y_et; % Fração molar gasosa de etanol

        y_w; % Fração molar gasosa de água

        trayT;

        % --- Valores das redes neurais --- %

        % --- Molar Holdup e nível de líquido nos pratos --- %

        Mn; % Hold-up molar

        ln; % Nível de líquido

        % --- Molar Holdup e nível de líquido nos pratos --- %

        % --- Propriedades de mistura --- %

        phi; % Volume molar

        dens_w; % Densidade água pura

        dens_tray; % Densidade da mistura

        h_tray; % Entalpia fase liquida

        H_tray; % Entalpia fase gasosa

        % --- Propriedades de mistura --- %


        % --- Escoamentos internos --- %

        D % Vazão de destilado (mol/s)

        Ln % Vazão liquida molar (mol/s) 

        Vn % Volume gasosa molar (mol/s)

        Qn % Taxa de calor (J/s)

        % --- Escoamentos internos --- %


    end

    methods % ***** Métodos ***** %

	% Cálculo da densidade

        function densityCalc(obj)

	   % Equação 3.1.9

            obj.phi = (5.1214 * 10^-2) + (6.549 * 10^-3) * obj.x_et + (7.406 * 10^-5) * obj.trayT; % L/mol
	
           % Equação 3.1.10

            obj.dens_w = 1000*(1 - (obj.trayT + 288.9414)/(508929.2 * (obj.trayT + 68.12963)) *(obj.trayT - 3.9863)^2); % g/L = Kg/m^3 

	   % Equação 3.1.8

            obj.dens_tray = ((obj.x_et) * (obj.MW_et) + (1 - obj.x_et) * obj.MW_w )* 10^-3/(obj.phi * obj.x_et + (1 - obj.x_et) * (obj.MW_w)/(obj.dens_w)); % g/cm^3

            % Mensagem de erro caso alguma variável não seja calculada

%             if ( isempty(obj.phi) || isempty(obj.dens_w) || isempty(obj.dens_tray) )
%
%                 error('ERROR 1: System failed to execute phiCalc() method due to the lack of one or more variables.')
%
%             end

        end

	% Cálculo das entalpias

        function enthalpyCalc(obj)

	    % Equação 3.1.6

            obj.h_tray = (55.678*obj.x_et + 75.425)*obj.trayT - 0.0057 * obj.x_et - 0.00125;

	    % Equação 3.1.7

            obj.H_tray = 44765.71 - 6171.03 * obj.y_et + (31.46 - 11.98 * obj.y_et) * obj.trayT + (4.063*10^-4 + 0.073 * obj.y_et) * obj.trayT;

            % Mensagem de erro caso alguma variável não seja calculada

%             if ( isempty(obj.h_tray) || isempty(obj.H_tray)  )
%
%                 error('ERROR 1: System failed to execute entalphyLiq() method due to the lack of one or more variables.')
%
%             end

        end

	% Cálculo da vazão de líquido dos pratos

        function liquidFlow(obj)

	    % Cálculo de Ln pela Equação 3.1.18 modificada

            obj.ln = (obj.Mn * (obj.x_et * obj.MW_et + (1 - obj.x_et) * obj.MW_w))/(obj.dens_tray * obj.Ap);

	  % Mensagem de erro caso haja erro nos cálculos do nível de cada prato

           if ( isnan(obj.ln) )

                error('ERROR 3: Mass balance convergence error.');

            end

	    % Equação 3.1.18
	
            obj.Ln = 0.5 * (obj.ln)^(1.5);

        end


        % ~~ Usado para estimar o hold-up inicial do refervedor ~~ %

        function boilerEstimate(obj)

            obj.Mn = obj.V_boiler * obj.dens_tray/(obj.x_et * obj.MW_et + obj.x_w * obj.MW_w);

	 % Mensagem de erro caso alguma variável não seja calculada

%         if ( isempty(obj.Mn) )
%
%             error('ERROR 1: System failed to execute liquidFlow() method due to the lack of one or more variables.')
%       end

        end

        % ~~ Usado para estimar o hold-up inicial dos pratos ~~ %

        function trayEstimate(obj)

            obj.Mn = obj.ln * obj.Ap * obj.dens_tray/(obj.x_et * obj.MW_et + obj.x_w * obj.MW_w);

	 % Mensagem de erro caso alguma variável não seja calculada

%         if ( isempty(obj.Mn) )
%
%             error('ERROR 1: System failed to execute liquidFlow() method due to the lack of one or more variables.')
%
%         end

        end

        % Cálculo das vazões molares de vapor para os pratos

        function  vaporFlow(obj, x_up, y_down, h_up, H_down, L_up, V_down)

            % Equação 4.2.2

            diff_h = -126005 * obj.x_et^4 + 298928 * obj.x_et^3 - 249321 * obj.x_et^2 + 86604 * obj.x_et - 6829.5;

            % Equação 3.1.24

            obj.Vn = ( L_up * (h_up - obj.h_tray - diff_h * (x_up - obj.x_et)) + V_down * (H_down - obj.h_tray - diff_h * (y_down - obj.x_et)) )/(obj.H_tray - obj.h_tray - diff_h*(obj.y_et - obj.x_et));

        end

	% Cálculo da vazão molar de vapor do refervedor

        function vaporFlowReboiler(obj, x_up, h_up, L_up )

           % Equação 4.2.2

          diff_h = -126005 * obj.x_et^4 + 298928 * obj.x_et^3 - 249321 * obj.x_et^2 + 86604 * obj.x_et - 6829.5;

	    % Equação 3.1.32

           obj.Vn = ( L_up * (h_up - obj.h_tray - diff_h*(x_up - obj.x_et)) + obj.Qn )/(obj.H_tray - obj.h_tray - diff_h*(obj.y_et - obj.x_et));

        end

        function vaporFlowSecTray(obj, x_up, y_down, h_up, H_down, V_down, R)

            % Equação 4.2.2

            diff_h = -126005 * obj.x_et^4 + 298928 * obj.x_et^3 - 249321 * obj.x_et^2 + 86604 * obj.x_et - 6829.5;

	    % Equação 3.1.24 para o prato 1 que recebe o refluxo

            obj.Vn = ( V_down * (H_down - obj.h_tray - diff_h * (y_down - obj.x_et)) )/(obj.H_tray - obj.h_tray - diff_h * (obj.y_et - obj.x_et) - (R * (h_up - obj.h_tray - diff_h * (x_up - obj.x_et)))/(R+1));

        end

	% Balanços de massa para o refervedor

        function reboilerMassBalance(obj, x_up, L_up, step)

            % Balanço de massa por componente: etanol. Equação 3.1.4

            obj.x_et = obj.x_et + step * ((L_up * (x_up - obj.x_et) - obj.Vn * (obj.y_et - obj.x_et))/(obj.Mn));

            % Equação 3.1.2B

            obj.x_w = 1 - obj.x_et;

            % Balanço de massa total. Equação 3.1.1

            obj.Mn = obj.Mn + step * (L_up - obj.Vn);

	    % Término da simulação caso o refervedor seque.

            if ( obj.Mn < 0.0005 )

                error('Simulation is over: The Boiler has dried up!');

            end

%             if ( isnan(obj.Mn) )
%
%                 error('ERROR 3: Mass balance convergence error. (Boiler)');
%
%             end
        end

	% Balanços de massa para os pratos

        function trayMassBalance(obj, x_up, y_down, V_down, L_up, step)

             % Balanço de massa por componente: etanol. Equação 3.1.4

            obj.x_et = obj.x_et + step * ((L_up *(x_up - obj.x_et) - obj.Vn *(obj.y_et - obj.x_et) + V_down * (y_down - obj.x_et))/(obj.Mn));

            % Equação 3.1.2B

            obj.x_w = 1 - obj.x_et;

            % Balanço de massa total. Equação 3.1.1

            obj.Mn = obj.Mn + step * (V_down + L_up - obj.Vn - obj.Ln);

	   % Mensagem de erro caso algum prato seque.

%             if ( obj.Mn < 0.001 ) % 0.0005 b4
%
%                 obj.Mn = 0.001;
%
%                 % error('ERROR 2: System failed to execute liquidFlow(). Tray has dried up!');
%
%             end

	   % Mensagem de erro caso haja algum erro no balanço de massa.

            if ( isnan(obj.Mn) )

                error('ERROR 3: Mass balance convergence error. (Trays)');

            end


        end

	% Balanços de massa e energia para o condensador

        function condenserMassEnergyBalance(obj, y_down, V_down, H_down, step)

            % Balanço de massa por componente: etanol. Equação 3.1.2

            obj.x_et = obj.x_et + step * (V_down * (y_down - obj.x_et));

            % Equação 3.1.2B

            obj.x_w = 1 - obj.x_et;

            % Balanço de energia para o condensador.

	    % Equação 4.2.2

            diff_h = -126005 * obj.x_et^4 + 298928 * obj.x_et^3 - 249321 * obj.x_et^2 + 86604 * obj.x_et - 6829.5;

	    % Equação 3.1.29

            obj.Qn = -V_down * (H_down - obj.h_tray - diff_h * (y_down - obj.x_et) );

        end

	    % Eficiências de Murphree: equação 3.1.14

        function murphreeEfficiency(obj, y_down_et, y_down_w)

            obj.y_et = y_down_et + obj.Em * (obj.y_et - y_down_et);

            obj.y_w = y_down_w + obj.Em * (obj.y_w - y_down_w);

        end
    end
end