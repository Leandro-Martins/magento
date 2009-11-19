#!/bin/bash

DB_HOST=
DB_USER=
DB_PASS=
DB_NAME=
pasta=
url=
adminuser=
adminpass=
adminfname=
adminlname=
adminemail=
sample=
mgsdversion=
mgversion=

function setup_banco {
    echo
    echo "Ok, agora vamos configurar seu banco de dados."
    echo "Os dados entre parênteses são os dados padrão."

    read -p "- servidor (localhost): " DB_HOST
    read -p "- usuário (magento): " DB_USER
    read -sp "- senha (magento): " DB_PASS
    echo
    read -p "- database (magento): " DB_NAME

    if [ -e $DB_HOST ]; then DB_HOST=localhost; fi
    if [ -e $DB_USER ]; then DB_USER=magento;   fi
    if [ -e $DB_PASS ]; then DB_PASS=magento;   fi
    if [ -e $DB_NAME ]; then DB_NAME=magento;   fi
}


function setup_info {
    echo
    echo Configurando a sua loja...

    read -p "Pasta da instalação (ma.gen.to): " pasta
    read -p "URL da loja (http://ma.gen.to): " url
    read -p "Administrado (admin): " adminuser
    read -p "Senha (mudar123): " adminpass
    read -p "Nome do administrador (Magento): " adminfname
    read -p "Sobrenome (Silva): " adminlname
    read -p "E-mail (mike@visie.com.br): " adminemail

    if [ -e $pasta      ]; then pasta='ma.gen.to'; fi
    if [ -e $url        ]; then url='http://ma.gen.to'; fi
    if [ -e $adminuser  ]; then adminuser=admin; fi
    if [ -e $adminpass  ]; then adminpass=mudar123; fi
    if [ -e $adminfname ]; then adminfname=Magento; fi
    if [ -e $adminlname ]; then adminlname=Silva; fi
    if [ -e $adminemail ]; then adminemail='mike@visie.com.br'; fi
}

function setup_source {
    echo
    echo Configurando o source do magento...

    read -p "Versão do magento (1.3.2.4): " mgversion
    read -p "Gostaria de baixar o banco de dados de exemplo? (s|n) " sample
    if [ "$sample" = "s" ]; then
       read -p "Versão do banco de dados de exemplo (1.2.0): " mgsdversion
    fi

    if [ -e $mgversion   ]; then mgversion='1.3.2.4'; fi
    if [ -e $mgsdversion ]; then mgsdversion='1.2.0'; fi
}

function instalar {
    echo
    echo Destruindo e criando o banco de dados...
    echo drop database if exists $DB_NAME\; create database $DB_NAME | mysql -h$DB_HOST -u$DB_USER -p$DB_PASS

    echo
    echo destruindo e criando pasta de instalação...
    rm -rf $pasta
    mkdir $pasta
    cd $pasta

    echo Baixando os pacotes...
    echo
    wget http://www.magentocommerce.com/downloads/assets/$mgversion/magento-$mgversion.tar.gz \
         -O magento.tar.gz
    cp magento.tar.gz /opt/
    #cp /opt/magento.tar.gz .

    if [ "$sample" = "s" ]; then
        wget http://www.magentocommerce.com/downloads/assets/$mgsdversion/magento-sample-data-$mgsdversion.tar.gz \
             -O magento-sample-data.tar.gz
        cp magento-sample-data.tar.gz /opt/
        #cp /opt/magento-sample-data.tar.gz .
    fi

    echo
    echo Descompactando...

    tar -zxvf magento.tar.gz
    if [ "$sample" = "s" ]; then
        tar -zxvf magento-sample-data.tar.gz
    fi

    echo
    echo Movendo os arquivos...

    if [ "$sample" = "s" ]; then
        mv magento-sample-data-$mgsdversion/media/* magento/media/
        mv magento-sample-data-$mgsdversion/magento_sample_data_for_$mgsdversion.sql magento/data.sql
    fi
    mv magento/* .
    mv magento/.htaccess .
   
    echo
    echo Permissoes...
   
    chmod o+w var var/.htaccess app/etc
    chmod -R o+w media
   
    if [ "$sample" = "s" ]; then
        echo
        echo Importando produtos de exemplo...
        mysql -h$DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME < data.sql
    fi

    #echo Inicializando o PEAR...
    # ./pear mage-setup .

    #echo Baixando pacotes...
    # ./pear install magento-core/Mage_All_Latest

    echo Limpando as pastas e arquivos desnecessários...
    rm -rf downloader/pearlib/cache/* downloader/pearlib/download/*
    rm -rf magento/ magento-sample-data-$mgsdversion/
    rm -rf magento.tar.gz magento-sample-data.tar.gz
    rm -rf index.php.sample .htaccess.sample php.ini.sample LICENSE.txt STATUS.txt data.sql

    echo Instalando o magento...

    php -f install.php -- \
        --license_agreement_accepted "yes" \
        --locale "en_US" \
        --timezone "America/Los_Angeles" \
        --default_currency "USD" \
        --db_host "$DB_HOST" \
        --db_name "$DB_NAME" \
        --db_user "$DB_USER" \
        --db_pass "$DB_PASS" \
        --url "$url" \
        --use_rewrites "yes" \
        --use_secure "no" \
        --secure_base_url "" \
        --use_secure_admin "no" \
        --admin_firstname "$adminfname" \
        --admin_lastname "$adminlname" \
        --admin_email "$adminemail" \
        --admin_username "$adminuser" \
        --admin_password "$adminpass"

}

clear

echo "Bem-vindo ao programa de instalação do magento"
echo "ATENÇÃO! Este programa criará a pasta de destino da instalação."
echo

echo "Você tem os dados do banco de dados? (s|n)"
read DB_INFO

if [ "$DB_INFO" = "s" ]; then
    setup_banco
    setup_info
    setup_source
    instalar
    exit
else
    echo "Por favor, crie o banco de dados antes de tudo"
    exit
fi

