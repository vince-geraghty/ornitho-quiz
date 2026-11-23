# Image de base officielle PHP : Debian + Apache + PHP 8.3.23 (mod_php).
# Version epinglee au patch pour que le build soit reproductible.
# Contrepartie : les correctifs de securite de l'image de base
# ne viennent pas tout seuls, il faut bumper ce numero a la main.
FROM php:8.3.23-apache

# Extensions livrees avec les sources de l'image officielle.
# docker-php-ext-install fait les deux choses : il compile ET il active.
# pdo + pdo_mysql = acces a MySQL via PDO.
RUN docker-php-ext-install pdo pdo_mysql

# mongodb n'est pas livree avec l'image : elle vient de PECL.
# pecl install compile seulement, d'ou le docker-php-ext-enable
# qui ecrit le fichier .ini d'activation.
# C'est l'etape la plus lente du build (~90 s sans cache).
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Tout fichier .ini depose dans conf.d/ est lu au demarrage de PHP.
# Celui-ci porte la configuration de journalisation des erreurs.
COPY php-error-logging.ini /usr/local/etc/php/conf.d/

# Modules Apache necessaires a l'application :
# rewrite -> regles de reecriture d'URL (routage MVC)
# headers -> envoi des en-tetes de securite (CSP, etc.)
RUN a2enmod rewrite headers

# Remplace le vhost par defaut d'Apache par celui du projet.
# C'est ce fichier qui place le DocumentRoot sur public/.
COPY apache.conf /etc/apache2/sites-available/000-default.conf

# Repertoire de travail du conteneur, et point de montage du projet.
# Cette image est un runtime de developpement : le code n'y est pas copie,
# il arrive par le bind mount declare dans docker-compose.yml.
# Un deploiement conteneurise demanderait une etape de build dediee
# (COPY + composer install --no-dev), pas la reintroduction d'un COPY . .
WORKDIR /var/www/html