# ------------------------------------------------------------------------------------------------------------------------
# Script d'installation des éléments de base:  
# Apache2 | PHP | MYSQL | PhpMyadmin
#
# Auteur: Mickaël DURJEAU
# Date:	15-04-2016
#
#-------------------------------------------------------------------------------------------------------------------------

#!/bin/sh

# Le script doit être lancer avec l'utilisateur root via sudo
if [ `id -u` -ne '0' ]; then
  echo "Le script doit être lancer avec un utilisateur système avec la commande sudo ./install.sh" >&2
  exit 1
fi

# Récupère le nom de la machine
server_name=$1

# Récupère le nom d'utilisateur système
user_system=$2

# Récupère le mot de passe de l'utilisateur système
password=$3

# Récupère le mot de passe root de mysql
pass_mysql_root=$4

# Modification des dépots
wget https://raw.github.com/dudux2/configFiles/master/sources.list
sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
sudo mv sources.list /etc/apt/sources.list


# Mise a jour du système et de la distribution
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove&& sudo apt-get -y clean

# Mise à jour de l'heure automatique de notre serveur
sudo apt-get -y install ntp

# Mise à jour des 
/etc/ntp.conf

server 0.fr.pool.ntp.org iburst
server 1.fr.pool.ntp.org iburst
server 2.fr.pool.ntp.org iburst
server 3.fr.pool.ntp.org iburst

# Redémarrage du démon pour la prise en compte de la configuration
sudo /etc/ini.d/ntp start


# Lamp user creation
if ! id "lamp" > /dev/null 2>&1; then
    echo "Lamp user does not exist - Creating lamp user..."
    (echo "lamp"; echo "lamp"; echo ""; echo ""; echo ""; echo ""; echo ""; echo ""; echo "Y") | adduser -q lamp
    adduser lamp sudo
fi

echo "lamp" > /etc/hostname
hostname lamp

baseDirectory=$(dirname $0)
pluginsDirectory=$baseDirectory/plugins

apt-get update --fix-missing