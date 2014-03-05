#! /usr/bin/env bash

if [ ! -d "$1" -o ! -d "$2"  ]; then 
	echo "Usage Parameter should be $0 <pre-redmine dir> <new redmine dir>"
	exit 1
fi

OLD_REDMINE=$1
NEW_REDMINE=$2
if [ "`uname`" = "FreeBSD" ]; then
	HTTPD_USER=www
elif [ "`uname`" = "Linux" ]; then
	HTTPD_USER=apache
fi

echo "This is migrate redmine script."
echo "migrate $OLD_REDMINE to $NEW_REDMINE"
echo "Are you sure? (y:yes continue, the others:no,exit now)"
read -p ":" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo ...exit
	exit 0
fi

cp -vp $OLD_REDMINE/config/database.yml $NEW_REDMINE/config/database.yml
# redmine may not have configuration.yml
if [ -f $OLD_REDMINE/config/configuration.yml ]; then
	cp -vp $OLD_REDMINE/config/configuration.yml $NEW_REDMINE/config/configuration.yml
fi

cp -rvp $OLD_REDMINE/files/* $NEW_REDMINE/files/ 
cp -rvp $OLD_REDMINE/plugins/* $NEW_REDMINE/plugins/
cp -rvp $OLD_REDMINE/public/.htaccess $NEW_REDMINE/public/
cp -rvp $OLD_REDMINE/public/themes/* $NEW_REDMINE/public/themes/

# permission changed
chown -R $HTTPD_USER $NEW_REDMINE
chgrp -R $HTTPD_USER $NEW_REDMINE

# install modules

cd $NEW_REDMINE
bundle install && (
	bundle update
	rake db:migrate RAILS_ENV="production"
	rake generate_secret_token
	rake tmp:cache:clear
	rake tmp:sessions:clear
	rake redmine:plugins RAILS_ENV="production"
)



