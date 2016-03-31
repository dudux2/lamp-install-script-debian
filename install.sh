# ------------------------------------------------------------------------------------------------------------------------
# Script d'installation des éléments de base:  
# Apache2 | PHP | MYSQL | PhpMyadmin
#
# Auteur: Mickaël DURJEAU
# Date:	15-04-2016
# 
# Prérequis:
# sudo chmod +x install.sh
# sudo ./install.sh
#-------------------------------------------------------------------------------------------------------------------------


#!/bin/sh

# Le script doit être lancer avec l'utilisateur root via sudo
if [ `id -u` -ne '0' ]; then
  echo "Le script doit être lancer avec un utilisateur système avec la commande sudo ./install.sh" >&2
  exit 1
fi


# Variable de couleur shell
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RESET='\033[0m' 


baseDirectory=$(dirname $0)
configFilesDirectory=$baseDirectory/configFiles


# Récupère l'IP du serveur
SERVER_IP=`/bin/hostname -I`
echo $SERVER_IP


# Contrôle si whiptail est installé
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' whiptail|grep "install ok installed")
echo "${BLUE}=> Contrôle si whiptail est installé: ${GREEN} $PKG_OK ${RESET}"

if [ "install ok installed" != "$PKG_OK" ]; then
  echo "${GREEN} whiptail non installé. Installation de whiptail ${RESET}"
  sudo apt-get update
  sudo apt-get --force-yes --yes install whiptail
fi


# Titre général utiliser pour whiptail
back_title="Installation automatisée du serveur"

selections()
{ 
    whiptail --title "Sélection des actions" --backtitle "$back_title" --checklist --separate-output \
    "Sélectionner/Déselectionner avec la barre d'espace les actions à éffectuer:" 20 85 12 \
    "UPDATE_SOURCE_LIST" "Mise à jour du source.list" OFF \
    "UPDATE_SYSTEM" "Mise à jour des packets système" OFF \
    "UPDATE_DISTRIBUTION" "Mise à jour de la distribution" OFF \
    "UPDATE_HOSTNAME" "Mise à jour du nom de la machine" OFF \
    "UPDATE_HOSTS" "Mise à jour du fichier hosts" OFF \
    "INSTALL_NTP" "Mise à jour de l'heure système automatiquement" OFF \
    "MAIL_SYSTEM" "Rediriger les emails ROOT vers une adresse email" OFF \
    "INSTALL_SSH" "Installation\Configuration de SSH" OFF \
    "UPDATE_PASSWORD_MYSQL" "Mise à jour du mot de passe root MYSQL" OFF \
    2>results
    
    userSystem
    
    while read choice
    do
        case $choice in
            UPDATE_HOSTNAME) serverName 
            ;;
            UPDATE_HOSTS) domainName 
            ;;
            MAIL_SYSTEM) mailSystem 
            ;;
            INSTALL_SSH) sshPort
            ;;
            UPDATE_PASSWORD_MYSQL) passwordRootMysql
            ;;
            *)
            ;;
        esac
    done < results
}





serverName()
{
    while [ "x$SERVER_NAME" = "x" ]
    do
        SERVER_NAME=$(whiptail --title "Nom du serveur" --backtitle "$back_title" --inputbox "Veuillez saisir le nom du serveur" 10 50 "debian" "(default)" 3>&1 1>&2 2>&3)
    done
}

domainName()
{
    while [ "x$DOMAIN_NAME" = "x" ]
    do
        DOMAIN_NAME=$(whiptail --title "Nom du domaine" --backtitle "$back_title" --inputbox "Veuillez saisir le nom du domaine" 10 50 "debianserver.no-ip.org" "(default)" 3>&1 1>&2 2>&3)
    done
}

mailSystem()
{
    while [ "x$MAIL_SYSTEM" = "x" ]
    do
        MAIL_SYSTEM=$(whiptail --title "Gestion des Emails du système" --backtitle "$back_title" --inputbox "Veuillez saisir l'adresse email de l'administrateur du système" 10 50 "mickaeldurjeau@hotmail.com" "(default)" 3>&1 1>&2 2>&3)
    done
}

userSystem()
{
    while [ "x$USER_SYSTEM" = "x" ]
    do
        USER_SYSTEM=$(whiptail --title "Nom d'utilisateur système" --backtitle "$back_title" --inputbox "Veuillez saisir le nom d'utilisateur du sytème\n Cette utilisateur doit être existant, il permettra la connexion SSH" 10 50 "dudu" "(default)" 3>&1 1>&2 2>&3)
    done
}

sshPort()
{
    while [ "x$SSH_PORT" = "x" ]
    do
        SSH_PORT=$(whiptail --title "Nom du port SSH" --backtitle "$back_title" --inputbox "Veuillez saisir le numéro du port SSH" 10 50 "22" "(default)" 3>&1 1>&2 2>&3)
    done
}

passwordRootMysql()
{
    while [ "x$PASSWORD_ROOT_MYSQL" = "x" ]
    do
        PASSWORD_ROOT_MYSQL=$(whiptail --title "Mot de passe root MYSQL" --backtitle "$back_title" --passwordbox "Veuillez saisir le mot de passe root de MYSQL" 10 50 "admin" "(default)" 3>&1 1>&2 2>&3)
    done
}






updateSourcesList()
{ 
    # Mise à jour des dépots
    echo "${BLUE}=> Mise à jour des dépots${RESET}"
    sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo cp $configFilesDirectory/sources.list /etc/apt/sources.list
}

updateSystem()
{ 
    # Mise a jour du système
    echo "${BLUE}=> Mise à jour des packets${RESET}"
    sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove && sudo apt-get -y clean
}

updateDistribution()
{ 
    # Mise a jour de la distribution
    echo "${BLUE}=> Mise à jour de la dsitribution${RESET}"
    sudo apt-get -y update && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove && sudo apt-get -y clean
}

updateHostname()
{ 
    # Mise a jour du nom de la machine
    echo "${BLUE}=> Mise à jour du nom de la machine${RESET}"
    sudo cp /etc/hostname /etc/hostname.bak
    echo "$SERVER_NAME" > /etc/hostname
    hostname $SERVER_NAME
}

updateHosts()
{ 
    # Mise a jour du fichier hosts
    echo "${BLUE}=> Mise à jour du nom du fichier host FQDN${RESET}"
    sudo cp /etc/hosts /etc/hosts.bak
    HOSTNAME="$(cat /etc/hostname)"
    echo "
127.0.0.1   localhost.localdomain   localhost
$SERVER_IP	$HOSTNAME.$DOMAIN_NAME   $HOSTNAME
" > /etc/hosts
}

installNtp()
{ 
    # Installation/configuration de la mise à l'heure automatique du serveur
    echo "${BLUE}=> Installation/configuration de la mise à l'heure automatique du serveur FQDN${RESET}"
    sudo apt-get -y install ntp
    # Mise à jour des serveur de synchro
    sudo cp /etc/ntp.conf /etc/ntp.conf.bak
    
    OLD_SERVER_0="server 0.debian.pool.ntp.org iburst"
    OLD_SERVER_1="server 1.debian.pool.ntp.org iburst" 
    OLD_SERVER_2="server 2.debian.pool.ntp.org iburst" 
    OLD_SERVER_3="server 3.debian.pool.ntp.org iburst" 
    NEW_SERVER_0="server 0.fr.pool.ntp.org iburst"
    NEW_SERVER_1="server 1.fr.pool.ntp.org iburst" 
    NEW_SERVER_2="server 2.fr.pool.ntp.org iburst" 
    NEW_SERVER_3="server 3.fr.pool.ntp.org iburst" 

    sed -i.bak "s/${OLD_SERVER_0}/${NEW_SERVER_0}/" /etc/ntp.conf
    sed -i.bak "s/${OLD_SERVER_1}/${NEW_SERVER_1}/" /etc/ntp.conf
    sed -i.bak "s/${OLD_SERVER_2}/${NEW_SERVER_2}/" /etc/ntp.conf
    sed -i.bak "s/${OLD_SERVER_3}/${NEW_SERVER_3}/" /etc/ntp.conf
}

installSsh()
{ 
    # Installation/configuration de ssh
    echo "${BLUE}=> Installation/configuration de SSH${RESET}"
    sudo apt-get -y install ssh
    
    # Securiser
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    # On crée un répertoire .ssh dans notre HOME
    sudo mkdir /home/$USER_SYSTEM/.ssh
    # Ensuite on lui change ses droits d'accès
    sudo chmod 0700 /home/$USER_SYSTEM/.ssh
    # Puis on génère les clés.
    ssh-keygen -q -t dsa -f /home/$USER_SYSTEM/.ssh/id_dsa
    # La clef publique .pub reste sur le serveur, on la renomme seulement
    sudo mv  /home/$USER_SYSTEM/.ssh/id_dsa.pub /home/$USER_SYSTEM/.ssh/authorized_keys
    # On crée le groupe sshusers
    sudo groupadd sshusers
    # Et on ajouter l'utilisateur à ce groupe
    sudo usermod -a -G sshusers $USER_SYSTEM
    
    # On recharge ssh
    sudo /etc/init.d/ssh restart
    
    # Se connecter en ssh avec le client pour télécharger la clef
    whiptail --title "Configuration SSH" --msgbox "Se connecter en SSH via user et port definit ou par SCP pour télécharger la privé." 10 75

    # Et on supprime cette clé privé parce qu'on n'en a plus besoin
    sudo rm -f /home/$USER_SYSTEM/.ssh/id_dsa
    # On rechange les droits sur le répertoire qui contient les clés

    # Décommenter ou ajouter la ligne suivante. Cela permet que le serveur donne son empreinte DSA en cas de connexion ssh.
    #sed -i.bak -e "s/.*HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/" /etc/ssh/sshd_config
    
    sed -i.bak "s/.*Port.*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
    sed -i.bak "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
    # Metter la durée pendant laquelle une connexion sans être loggée sera ouverte.
    sed -i.bak "s/.*LoginGraceTime.*/LoginGraceTime 20/" /etc/ssh/sshd_config
    
    # Le nombre maximum d'essais avant de se faire jeter par le serveur...
    # Vu qu'avec la clé, pas d'erreur possible, vous pouvez le mettre à 1 essai possible.
    #sed -i.bak "s/.*MaxAuthTries.*/MaxAuthTries 1/" /etc/ssh/
    echo "MaxAuthTries 1" >> /etc/ssh/sshd_config
    
    # Ensuite, on va indiquer au serveur SSH où se trouvent les clés et lui dire qu'on va les utiliser comme méthode d'authentification
    sed -i.bak "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config    
    sed -i.bak "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile \%h\/.ssh\/authorized_keys/" /etc/ssh/sshd_config
    
    # Et bien sûr, on va désactiver toutes les autres méthodes d'authentification
    sed -i.bak "s/RSAAuthentication.*/RSAAuthentication no/" /etc/ssh/sshd_config    
    sed -i.bak "s/.*UsePAM.*/UsePAM no/" /etc/ssh/sshd_config 
    sed -i.bak "s/.*KerberosAuthentication.*/KerberosAuthentication no/" /etc/ssh/sshd_config 
    sed -i.bak "s/.*GSSAPIAuthentication.*/GSSAPIAuthentication no/" /etc/ssh/sshd_config 
    
    #sed -i.bak "s/.*PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config    
    
    # Ensuite, on va lui dire qu'on autorise uniquement les utilisateurs du groupe sshusers (pour plus de sécurité)
    sed -i.bak "s/.*AllowGroups.*/AllowGroups sshusers/" /etc/ssh/sshd_config

    # Le paramètre MaxStartups indique le nombre de connexions ssh non authentifiées que vous pouvez lancer en même temps.
    # 2 c'est largement suffisant sachant qu'avec les clés, c'est instantané.
    sed -i.bak "s/.*MaxStartups.*/MaxStartups 2/" /etc/ssh/sshd_config
    
    # Maintenant que tout est paramétré, on va redémarrer le serveur ssh
    sudo /etc/init.d/ssh restart    
}

configMailSystem()
{
    # installation de postfix
    # echo "${BLUE}=> Installation de postfix pour les redirection des mail système${RESET}"
    # sudo apt-get update && sudo apt-get -y install postfix && sudo apt-get -y install mutt
    # echo "root: $MAIL_SYSTEM" >> /etc/aliases
    # sudo newaliases 
    # mynetworks = 
    #sed -i.bak "s/relayhost = .*/relayhost = $SMTP_FAI/" /etc/postfix/main.cf


    # sudo /etc/init.d/postfix restart
    sudo apt-get install mailutils
    echo "Mail envoyé le $(date)" | mail -s "Test envoi de mail depuis $HOST" mickaeldurjeau@hotmail.com
    
    
    touch /home/$USER_SYSTEM/.muttrc
    echo "${BLUE}=> Test envois de mail${RESET}"
    echo "Corp du message" | mutt -s "Ma voiture" -- $MAIL_SYSTEM
}
    
    #echo "Corp du message" | mutt -s "Ma voiture" -a test.txt test2.txt -- mickaeldurjeau@hotmail.com




# EXECUTION DES FONCTIONS
if [ -f /etc/debian_version ]; then 
    selections
    while read choice
    do
        case $choice in
            UPDATE_SOURCE_LIST) updateSourcesList
            ;;
            UPDATE_SYSTEM) updateSystem
            ;;
            UPDATE_DISTRIBUTION) updateDistribution
            ;;
            UPDATE_HOSTNAME) updateHostname
            ;;
            UPDATE_HOSTS) updateHosts
            ;;
            MAIL_SYSTEM) configMailSystem
            ;;
            INSTALL_NTP) installNtp
            ;;
            INSTALL_SSH) installSsh
            ;;
            *)
            ;;
        esac
    done < results
    
sudo rm results
#sudo rm -r install-debian    
    
fi


