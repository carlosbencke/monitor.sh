#!/bin/bash 
#
# monitor.ricohpel.sh - Realiza validações de disponibilidade dos sites da Ricohpel.
#
# AUTOR:        Carlos Alexandre Bencke
#
# ------------------------------------------------------------------- #
#
# O QUE FAZ ?
#
#
# CONFIGURAÇÃO?
# É recomendado criar um link simbólico do arquivo para algum local disponível na variável $PATH.
# $ ln -s /home/crls/scripts/monitor.ricohpel.sh /usr/local/bin
#
# COMO USAR?
# Esse script pode ser chamado utilizando  o "./"  ou agendando sua execução via Cron.
# Examples:
# $ ./monitor.ricohpel.sh
#
# or
#
# 30 07 * * * root monitor.ricohpel.sh 1> /dev/null 2>&1
# ------------------------------------------------------------------- #

# ------------------------DEPENDÊNCIAS------------------------------- #
#
# O comando notify-send pode ser instalado com o pacote ruby-notify
#
# ------------------------------------------------------------------- #

# --------------------------VARIÁVEIS-------------------------------- #

#Configuráveis
lista_sites=/home/crls/Dropbox/9_scripts/monitor.ricohpel/sites.lst 	# Arquivo de configuração.
tempo_de_espera=5	# Tempo de espera até a próxima verificação.

#Não alterar
cursor_y_inicial=9 # Posição inicial da lista após cabeçalho.
loop=true
site_on=0	# Quantidade de Hosts online
site_off=0	# Quantidade de Hosts offline

#Variáveis de texto.
vermelho='\e[1;31m' # vermelho negrito
verde='\e[1;32m'	# verde negrito
normal='\e[1;97m'	# branco negrito

# ------------------------------------------------------------------- #

# --------------------------FUNÇÕES---------------------------------- #
cabecalho(){
	cursor_y_inicial_cabecalho=8 # Posição inicial do cabeçalho
	clear
	tput bold #Deixa tudo em negrito
	echo "   __  __             _ _             ____  _           _                _ "
	echo "  |  \/  | ___  _ __ (_) |_ ___  _ __|  _ \(_) ___ ___ | |__  _ __   ___| |"
	echo "  | |\/| |/ _ \| '_ \| | __/ _ \| '__| |_) | |/ __/ _ \| '_ \| '_ \ / _ \ |"
	echo "  | |  | | (_) | | | | | || (_) | | _|  _ <| | (_| (_) | | | | |_) |  __/ |"
	echo "  |_|  |_|\___/|_| |_|_|\__\___/|_|(_)_| \_\_|\___\___/|_| |_| .__/ \___|_|"
	echo "                                                             |_|           "
	echo -e " //$vermelho Monitorando todos os sites da Ricohpel $normal// //$verde $(date +%c)$normal //"
	tput bold
	# Move o cursor para a posição x do terminal e imprime o nome da coluna
	tput cup $cursor_y_inicial_cabecalho 1
	echo -n "Site"

	tput cup $cursor_y_inicial_cabecalho 40
	echo -n "IP"

	tput cup $cursor_y_inicial_cabecalho 56
	echo -n "Tempo"

	tput cup $cursor_y_inicial_cabecalho 63
	echo -n "Código"

	tput cup $cursor_y_inicial_cabecalho 70
	echo "Status"

	echo -e "$vermelho ---------------------------------------------------------------------------$normal"
}
 testa_site(){
	numero_sites=$(cat $lista_sites | wc -l) # lê o número de hosts
	site="1"	# Qual linha ler primeiro?
	while [[ $site -lt $numero_sites || $site -eq $numero_sites ]]; # Enquanto a linha atual for menor ou igual a quantidade todal de linhas.
	do
		cursor_y=$[$cursor_y_inicial+$site] # Configura a posição da linha onde será printado as informações
		endereco=$(sed -n $site\p $lista_sites) # Pega o endereço do site no arquivo de configuração
		ip=$(curl -s -m 10 -L -o /dev/null -w "%{remote_ip}\n" $endereco) # Pega ip do site
		tempo=$(curl -s -m 10 -L -o /dev/null -w "%{time_total}\n" $endereco | sed 's/\(....\).*/\1/') # Pega o tempo total para o acesso.
		codigo=$(curl -s -m 10 -L -o /dev/null -w "%{http_code}\n" $endereco) # Pega o status http da conexão.
		
		if [ $codigo -eq 200 ] # Se o ping deu certo
		then
			status=$(echo -e "$verde[ OK ]$normal")
			((site_on++))
		else
			status=$(echo -e "$vermelho[ERRO]$normal")
			((site_off++))
			notify-send $nome "O site $endereco está inacessível"

		fi

		tput bold
		tput cup $cursor_y 1
		echo -n $endereco

		tput cup $cursor_y 40
		echo -n $ip

		tput cup $cursor_y 56
		echo -n $tempo

		tput cup $cursor_y 63
		echo -n $codigo

		tput cup $cursor_y 70
		echo $status

		((site++))
	done
}
 resumo(){
	echo -e "$vermelho ---------------------------------------------------------------------------$normal"
	echo -e " // Resumo: $vermelho $site_off $normal sites de $numero_sites $normal estão $vermelho OFFLINE $normal"
	echo -e -n " Próxima verificação em $verde $tempo_de_espera $normal segundos."
	echo -e "    Precione $verde[CRTL+C] $normal para sair..."
	site_on=0
	site_off=0
}

#netcat_site(){}
#registra_log(){}
#manda_email(){}


# ------------------------------------------------------------------- #

# --------------------------TESTES----------------------------------- #
# Qual o sistema operacional?
# Dependência já instalada?
# Habilitar notificações?
# Precisa de ajuda?


# ------------------------------------------------------------------- #

# --------------------------EXECUÇÃO--------------------------------- #

while [[ $loop == true ]]
do
	cabecalho
	testa_site
	resumo
	sleep $tempo_de_espera\s
	clear
done

# ------------------------------------------------------------------- #
