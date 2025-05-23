.PHONY: dev, stop, drop, install, open-db

dev:
	ddev start

stop:
	ddev stop

install:
	ddev start
	$(call message_primary, "DOWNLOAD WP")
	ddev exec wp core download --force

	$(call message_primary, "VERSION WP")
	ddev exec wp core version

	@echo "🧹 Cleaning up wp folder"
		@ddev exec rm -f app/wp/readme.html app/wp/license.txt app/wp/wp-config.php
		@ddev exec rm -rf app/wp/wp-content*

	$(call message_primary, "SETUP ENVIRONMENT")
	@if [ ! -f .env ]; then \
		if [ -f .env.example.dev ]; then \
			cp .env.example.dev app/.env; \
			echo ".env file created from .env.example.dev"; \
		else \
			echo "Error: .env.example.dev file not found"; \
			exit 1; \
		fi; \
	fi; \

	$(call message_primary, "CREATE DB")
	@ddev exec wp db check >/dev/null 2>&1 || ddev exec wp db create

	$(call message_primary, "INSTALL WP")
	ddev exec wp core install \
		--url=https://your-site.ddev.site \
		--title="My Site" \
		--admin_user=admin \
		--admin_password=admin \
		--admin_email=admin@your-site.ddev.site \
		--skip-plugins=hello \
		--skip-themes=twentyfifteen,twentysixteen,twentyseventeen,twentynineteen,twentytwenty

	@if git submodule status | egrep -q '^[-+]' ; then \
		echo "INFO: Need to reinitialize git submodules"; \
		git submodule update --init; \
    fi \

	#$(call message_primary, "INSTALL PLUGINS")
	#wp plugin install jetpack --activate
	#wp plugin install contact-form-7 --activate
	#wp plugin install wordpress-seo --activate
	#wp plugin install updraftplus --activate
	#wp plugin install backwpup

	$(call message_primary, "INSTALL THEME")
	#wp theme install astra --activate
	ddev exec wp theme install twentytwenty --activate

	$(call message_primary, "PAGES CREATE - home / blog / contact / privacy")
	ddev exec wp post create --post_type=page --post_title='Home' --post_status=publish
	ddev exec wp post create --post_type=page --post_title='Blog' --post_status=publish
	ddev exec wp post create --post_type=page --post_title='Contact' --post_status=publish
	ddev exec wp post create --post_type=page --post_title='Privacy' --post_status=publish

	$(call message_primary, "CONFIG SET PAGE - select home page / article")
	ddev exec wp option update show_on_front page
	ddev exec wp option update page_on_front 4
	ddev exec wp option update page_for_posts 5

	$(call message_primary, "CONFIG MENU")
	ddev exec wp menu create "Main Menu"
	ddev exec wp menu item add-post main-menu 3
	ddev exec wp menu item add-post main-menu 4
	ddev exec wp menu item add-post main-menu 5
	ddev exec wp menu item add-post main-menu 6

	$(call message_primary, "DELETE : plugin - theme - articles examples")
	ddev exec wp option update blogdescription 'my website'
	ddev exec wp post delete 1 --force
	ddev exec wp post delete 2 --force

	$(call message_primary, "PERMALINKS")
	ddev exec wp option get permalink_structure
	ddev exec wp option update permalink_structure '/%postname%'
	ddev exec wp rewrite flush --hard

	ifeq ($(os_custom), mac)
		$(call message_primary, "GIT - init")
		@ddev exec bash -c "if [ ! -d .git ]; then git init && git add -A && git commit -m 'Initial commit'; fi"
	endif

drop:
	ddev exec mysql -e "DROP DATABASE IF EXISTS db; CREATE DATABASE db;"

update-wp:
	ddev exec wp core update

update-plugins:
	ddev exec wp plugin update --all

update-git:
	git pull origin main
	git submodule update --init

update-all: update-git update-wp
	git submodule foreach git pull origin main
	git submodule foreach git checkout main

open-db:
	@echo "Opening the database for direct access"
	open mysql://wordpress:wordpress@127.0.0.1:$$(lando info --service=database --path 0.external_connection.port | tr -d "'")/wordpress?enviroment=local&name=$database&safeModeLevel=0&advancedSafeModeLevel=0