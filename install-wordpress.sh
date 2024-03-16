#!/bin/bash

# Autor: Patrick Ataíde
# Contribuição criar senha aleatória do banco de dados MySQL: André Scrivener
# Data de Criação: 31 de julho de 2023
# Descrição: Este script faz...
# 1. Configura o nome dominio do site , como de preferencia, você pode escolhe seu domínio.
# 2. Atualiza o sistema
# 3. Instala o Nginx
# 4. Configura o UFW
# 5. Instala e configurando o MySQL
# 6. Instala o PHP
# 7. Instala o WordPress com Nginx
# 8. Criando arquivo letsencrypt.conf ( Certificado SSL )
# 9. Configurando Nginx para WordPress
# 10. Verificando a sintaxe do Nginx
# 11. Criação de senha aleatória do banco de dados MySQL

#read -p "Digite a senha para o banco de dados MySQL: ( exemplo: 6mFujV7P ): " db_password

# Criar senha aleatória do banco de dados MySQL

db_password=$(date +%s | sha256sum | base64 | head -c 20 ; echo)

echo "Senha aleatória geradado banco de dados MySQL, guarde com cuidado: $db_password"

read -p "Digite o nome do domínio para o WordPress: ( exemplo: patrickataide.com.br ): " domain_name

echo "Passo 1: Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y

echo "Passo 2: Instalando o Nginx..."
sudo apt install nginx -y

echo "Passo 3: (Opcional) Configurando o UFW..."
sudo ufw allow 'Nginx Full'
sudo ufw enable

echo "Passo 4: Instalando e configurando o MySQL..."
sudo apt install mysql-server -y
sudo systemctl status mysql

sudo mysql_secure_installation

sudo mysql -u root -p <<EOF
CREATE DATABASE WordPress CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'WordPressUser'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL ON WordPress.* TO 'WordPressUser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

echo "Passo 5: Instalando o PHP..."
sudo apt install php7.2-cli php7.2-fpm php7.2-mysql php7.2-json php7.2-opcache php7.2-mbstring php7.2-xml php7.2-gd php7.2-curl -y

echo "Passo 6: Instalando o WordPress com Nginx..."
sudo mkdir -p /var/www/html/$domain_name

cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz
sudo mv /tmp/wordpress/* /var/www/html/$domain_name/
sudo chown -R www-data: /var/www/html/$domain_name

echo "Passo 7: Criando arquivo letsencrypt.conf..."
sudo tee /etc/nginx/snippets/letsencrypt.conf >/dev/null <<EOF
location ^~ /.well-known/acme-challenge/ {
    allow all;
    root /var/www/html;
    default_type "text/plain";
    try_files \$uri =404;
}
EOF

echo "Passo 8: Configurando Nginx para WordPress..."
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$domain_name

sudo tee /etc/nginx/sites-available/$domain_name >/dev/null <<EOF
server {
    listen 80;
    server_name www.$domain_name $domain_name;

    root /var/www/html/$domain_name;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

    include snippets/letsencrypt.conf;
}
EOF

echo "Passo 9: Habilitando o arquivo de configuração..."
sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/

echo "Passo 10: Verificando a sintaxe do Nginx..."
sudo nginx -t

echo "Passo 11: Reiniciando o Nginx..."
sudo systemctl restart nginx

echo "Passo 12: Criando arquivo test.php..."
sudo tee /var/www/html/$domain_name/test.php >/dev/null <<EOF
<?php phpinfo(); ?>
EOF

echo "Passo 13: Definindo permissões para os arquivos do WordPress..."
sudo chown -R www-data: /var/www/html/$domain_name

echo "A instalação e configuração do WordPress com Nginx foram concluídas com sucesso!"

echo "Senha aleatória gerada, guarde a senha do banco de dados MySQL: $db_password"
