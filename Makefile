.PHONY: init, config, get-wp, install-wp, dev, stop, drop, open-db, config-wp

ifeq ($(wildcard .env.local),.env.local)
    include .env.local
    export $(shell sed 's/^#.*//g' .env.local | sed '/^$$/d' | cut -d'=' -f1)
    WP_BLOGNAME := $(strip $(subst ",,$(WP_BLOGNAME)))
    WP_BLOGDESCRIPTION := $(strip $(subst ",,$(WP_BLOGDESCRIPTION)))
    GITHUB_PLUGINS_REPOS := $(strip $(subst ",,$(GITHUB_PLUGINS_REPOS)))
endif

init:
	ddev config
	ddev config --webserver-type apache-fpm
	ddev restart

config:
	$(call message_primary, "SETUP ENVIRONMENT")
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			cp .env.example app/.env; \
			echo ".env file created from .env.example"; \
		else \
			echo "Error: .env.example file not found"; \
			exit 1; \
		fi; \
	fi; \

get-wp:
	ddev start
	$(call message_primary, "DOWNLOAD WP $(WP_VERSION)")
	ddev exec wp core download --force --version=$(WP_VERSION)

	$(call message_primary, "VERSION WP")
	ddev exec wp core version

	@echo "🧹 Cleaning up wp folder"
		ddev exec rm -f app/wp/readme.html app/wp/license.txt
		ddev exec rm -rf app/wp/wp-content

install-wp:
	@echo "Running install-wp..."
	ddev exec wp db check >/dev/null 2>&1 || ddev exec wp db create
	@echo "INSTALL WP"
	ddev exec wp core install \
		--url='$(WP_HOME)' \
		--title='$(WP_TITLE)' \
		--admin_user='$(WP_USER)' \
		--admin_password='$(WP_PASSWORD)' \
		--admin_email='$(WP_EMAIL)' \
		--skip-plugins=hello \
		--skip-themes=twentyfifteen,twentysixteen,twentyseventeen,twentynineteen,twentytwenty

	@echo "WordPress installed!"

config-wp:
	@echo "Configuring WordPress General Settings..."
	ddev exec wp option update blogname '$(WP_BLOGNAME)'
	ddev exec wp option update blogdescription '$(WP_BLOGDESCRIPTION)'
	ddev exec wp option update WPLANG '$(WP_WPLANG)'
	ddev exec wp option update timezone_string '$(WP_TIMEZONE)'

	$(call message_primary, "PERMALINKS")
	ddev exec wp option get permalink_structure
	ddev exec wp option update permalink_structure '/%postname%'
	ddev exec wp rewrite flush --hard

	@echo "WordPress Settings Applied!"

theme-setup:
	$(call message_primary, "INSTALL PLUGINS")
	ddev exec wp plugin install fluent-smtp --activate
	ddev exec wp plugin install advanced-custom-fields --activate
	ddev exec wp plugin install woocommerce --activate

	ddev exec wp theme install yootheme_wp_4.5.17.zip --activate

install-github-plugins:
	@echo "--- Initializing GitHub Plugin Installation ---"
	@echo "1. Ensuring DDEV SSH Agent is Authenticated..."
	ddev auth ssh || { echo "ERROR: ddev auth ssh failed. Ensure your SSH agent is running and keys are added (e.g., 'eval \"\$$\(ssh-agent -s\)\"; ssh-add ~/.ssh/id_ed25519')"; exit 1; }

	@echo "2. Preparing target plugin directory: $(WP_PLUGINS_DEST_DIR)..."
	ddev exec sudo chown -R www-data:www-data $(WP_PLUGINS_DEST_DIR) || { echo "ERROR: Failed to change ownership"; exit 1; }
	ddev exec sudo chmod -R ug+rwX,o+rX $(WP_PLUGINS_DEST_DIR) || { echo "ERROR: Failed to set permissions"; exit 1; }

	@echo "3. Cloning and Activating GitHub Plugins..."
	@for repo_url in $(GITHUB_PLUGINS_REPOS); do \
		repo_name=$$(basename $$repo_url .git); \
		echo "  -> Processing $$repo_name from $$repo_url..."; \
		ddev exec bash -c "git clone '$$repo_url' '$(WP_PLUGINS_DEST_DIR)/$$repo_name' || ( cd '$(WP_PLUGINS_DEST_DIR)/$$repo_name' && git pull )"; \
		ddev exec wp plugin activate "$$repo_name/$$repo_name.php" || \
		echo "WARNING: Could not activate $$repo_name. Maybe it's already active or the main file name is wrong."; \
	done

	@echo "--- GitHub Plugins Installation Complete ---"

dev:
	ddev start

stop:
	ddev stop

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
