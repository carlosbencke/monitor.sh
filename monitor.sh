#!/bin/bash 
#
# monitor.ricohpel.sh - Realiza validações de disponibilidade de dispositivos da Ricohpel.
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
# O comando notify-send depende do pacote ruby-notify ou libnotify-bin

#
# ------------------------------------------------------------------- #

# --------------------------VARIÁVEIS-------------------------------- #

#Configuráveis
lista_hosts=hosts.lst 	# Arquivo de configuração dos hosts.
lista_sites=sites.lst 	# Arquivo de configuração dos sites.
arquivo_temporario=/tmp/monitor.temp.txt	# Arquivo temporário.
numero_pings=15	 # Número de pings de teste.
tempo_de_espera=5	# Tempo de espera até a próxima verificação.
inicio_notificacao=08
fim_notificacao=18

#Não alterar
cursor_y_inicial_cabecalho=8 # Posição inicial do cabeçalho
cursor_y_inicial=9 # Posição inicial da lista após cabeçalho.
host_on=0	# Quantidade de hosts online
host_off=0	# Quantidade de hosts offline
site_on=0	# Quantidade de sites online
site_off=0	# Quantidade de sites offline

#Variáveis de texto.
vermelho='\e[1;31m' # vermelho negrito
verde='\e[1;32m'	# verde negrito
normal='\e[1;97m'	# branco negrito

# ------------------------------------------------------------------- #

# --------------------------FUNÇÕES---------------------------------- #
titulo(){
	clear
	tput bold #Deixa tudo em negrito
	echo "   __  __             _ _             ____  _           _                _ "
	echo "  |  \/  | ___  _ __ (_) |_ ___  _ __|  _ \(_) ___ ___ | |__  _ __   ___| |"
	echo "  | |\/| |/ _ \| '_ \| | __/ _ \| '__| |_) | |/ __/ _ \| '_ \| '_ \ / _ \ |"
	echo "  | |  | | (_) | | | | | || (_) | | _|  _ <| | (_| (_) | | | | |_) |  __/ |"
	echo "  |_|  |_|\___/|_| |_|_|\__\___/|_|(_)_| \_\_|\___\___/|_| |_| .__/ \___|_|"
	echo "                                                             |_|           "
}
cabecalho_ping(){
	echo -e " //$vermelho Monitorando os equipamentos da Ricohpel $normal // $verde $(date +%c)$normal //"
	tput bold
	# Move o cursor para a posição x do terminal e imprime o nome da coluna
	tput cup $cursor_y_inicial_cabecalho 1
	echo -n "Host"

	tput cup $cursor_y_inicial_cabecalho 12
	echo -n "local"

	tput cup $cursor_y_inicial_cabecalho 28
	echo -n "Endereço"

	tput cup $cursor_y_inicial_cabecalho 48
	echo -n "Ping"

	tput cup $cursor_y_inicial_cabecalho 60
	echo -n "Perda"

	tput cup $cursor_y_inicial_cabecalho 68
	echo "Status"

	echo -e "$vermelho --------------------------------------------------------------------------$normal"
}

cabecalho_site(){
	echo -e " //$vermelho Monitorando todos os sites da Ricohpel $normal//$verde $(date +%c)$normal //"
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

ping_host(){
	numero_hosts=$(cat $lista_hosts | wc -l) # lê o número de hosts
	host="1"	# Qual linha ler primeiro?
	while [[ $host -lt $numero_hosts || $host -eq $numero_hosts ]]; # Enquanto a linha atual for menor ou igual a quantidade todal de linhas.
	do
		cursor_y=$[$cursor_y_inicial+$host] # Configura a posição da linha onde será printado as informações
		nome=$(sed -n $host\p $lista_hosts | cut -f 1) # Pega o nome no arquivo de configuração
		local=$(sed -n $host\p $lista_hosts | cut -f 2)	# Pega o local no arquivo de configuração
		ip=$(sed -n $host\p $lista_hosts | cut -f 3) # Pega o endereço ip no arquivo de configuração
		
		ping -q -n -i 0.2 -c $numero_pings $ip > $arquivo_temporario # Testa a comunicação e joga o resultado em um arquivo.

		if [ $? -eq 0 ] # Se o ping deu certo
		then
			tempo_ping=$(tail -n 1 $arquivo_temporario| cut -d "/" -f 5) # Pega o tempo de ping no arquivo.
			perda=$(tail -n 2 $arquivo_temporario | head -n 1| cut -d " " -f 6) # 
			status=$(echo -e "$verde ONLINE $normal")
			((host_on++))
		else
			status=$(echo -e "$vermelho OFFLINE $normal")
			tempo_ping="ERRO"
			perda=$(tail -n 2 $arquivo_temporario | head -n 1| cut -d " " -f 6)	
			((host_off++))
			hora=$(date +%H) # Hora atual
#			if [[ $hora > $inicio_notificacao && $hora < $fim_notificacao ]] # Se hora maior que inicio e hora menor que fim
#			then 
#				notify-send $nome "O dispositivo $nome está OFFLINE" # Manda notificação
#			fi
		fi
		
		tput bold
		tput cup $cursor_y 1
		echo -n $nome

		tput cup $cursor_y 12
		echo -n $local

		tput cup $cursor_y 28
		echo -n $ip

		tput cup $cursor_y 48
		echo -n $tempo_ping

		tput cup $cursor_y 60
		echo -n $perda

		tput cup $cursor_y 68
		echo $status

		((host++))
	done
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

		# Para toubleshoot usar o comando curl -s -m 10 -L -o /dev/null -w "%{http_code}\n " google.com

		
		if [ $codigo -eq 200 ] # Se o ping deu certo
		then
			status=$(echo -e "$verde[ OK ]$normal")
			((site_on++))
		else
			status=$(echo -e "$vermelho[ERRO]$normal")
			((site_off++))
			hora=$(date +%H) # Hora atual
#			if [[ $hora > $inicio_notificacao && $hora < $fim_notificacao ]] # Se hora maior que inicio e hora menor que fim
#			then
#				notify-send $endereco "O site $endereco está inacessível" # Envia notificação
#			fi
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

resumo_ping(){
	echo -e "$vermelho---------------------------------------------------------------------------$normal"
	echo -e " // Resumo: $vermelho $host_off $normal hosts de $numero_hosts $normal estão $vermelho OFFLINE $normal"
	echo -e -n " Próxima verificação em $verde $tempo_de_espera $normal segundos."
	echo -e "    Precione $verde[CRTL+C] $normal para sair..."
	host_on=0
	host_off=0
}

 resumo_site(){
	echo -e "$vermelho ---------------------------------------------------------------------------$normal"
	echo -e " // Resumo: $vermelho $site_off $normal sites de $numero_sites $normal estão $vermelho OFFLINE $normal"
	echo -e -n " Próxima verificação em $verde $tempo_de_espera $normal segundos."
	echo -e "    Precione $verde[CRTL+C] $normal para sair..."
	site_on=0
	site_off=0
}

# ------------------------------------------------------------------- #

# --------------------------EXECUÇÃO--------------------------------- #

while true
do
	# Testa hosts
	titulo
	cabecalho_ping
	ping_host
	resumo_ping
	sleep $tempo_de_espera\s
	clear
	#Testa sites
	titulo
	cabecalho_site
	testa_site
	resumo_site
	sleep $tempo_de_espera\s
	clear
done

# ------------------------------------------------------------------- #
