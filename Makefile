# Load environment variables from .env
ifeq ($(wildcard .env.local),.env.local)
    include .env.local
    export $(shell sed 's/^#.*//g' .env.local | sed '/^$$/d' | cut -d'=' -f1)
    WP_BLOGNAME := $(strip $(subst ",,$(WP_BLOGNAME)))
    WP_BLOGDESCRIPTION := $(strip $(subst ",,$(WP_BLOGDESCRIPTION)))
    GITHUB_PLUGINS_REPOS := $(strip $(subst ",,$(GITHUB_PLUGINS_REPOS)))
endif

# Set fallback values only if not defined in .env
WP_HOME ?= https://$(PROJECT_NAME).ddev.site
WP_SITEURL ?= $(WP_HOME)/wp
DB_HOST ?= db
DB_NAME ?= db
DB_USER ?= db
DB_PASSWORD ?= db
DB_TABLE_PREFIX ?= ntdst_
TEMPLATE_DIR ?= export

# Configure DDEV server and download wordpress
.PHONY: init
init: 
	echo "⚙️  Configuring server..."
	ddev config
	ddev config --webserver-type apache-fpm
	ddev restart
	ddev exec composer install


	echo "📥 Downloading WordPress..."
	ddev exec wp core download --force --version=$(WP_VERSION)

	@echo "🧹 Cleaning up wp folder"
	ddev exec rm -f $(INSTALL_PATH)/wp/readme.html $(INSTALL_PATH)/wp/license.txt
	ddev exec rm -rf $(INSTALL_PATH)/wp/wp-content

# Removing all junk data from db
.PHONY: clean-db
clean-db:
	@echo "🧹 Cleaning database before export..."
	ddev exec wp transient delete --all 
	ddev exec wp option delete _site_transient_update_core
	ddev exec wp option delete _site_transient_update_plugins
	ddev exec wp option delete _site_transient_update_themes
	ddev exec wp option delete user_count
	ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)options WHERE option_name LIKE '_transient_%' OR option_name LIKE '_site_transient_%';"
	ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)comments WHERE comment_approved = 'spam' OR comment_approved = 'trash';" 
	ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)postmeta WHERE meta_key LIKE '_edit_lock' OR meta_key LIKE '_edit_last';" 
	ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)posts WHERE post_status = 'auto-draft';" 
	ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)posts WHERE post_type = 'revision';" 
	ddev exec wp db query "DELETE pm FROM $(DB_TABLE_PREFIX)postmeta pm LEFT JOIN $(DB_TABLE_PREFIX)posts wp ON pm.post_id = wp.ID WHERE wp.ID IS NULL;"
	ddev exec wp db query "DELETE cm FROM $(DB_TABLE_PREFIX)commentmeta cm LEFT JOIN $(DB_TABLE_PREFIX)comments wc ON cm.comment_id = wc.comment_ID WHERE wc.comment_ID IS NULL;"

# Export the current site into a clean template
.PHONY: export-site
export-site: clean-db
	@echo "📦 Exporting site as template"

	@echo "📁 Saving cleaned export to $(TEMPLATE_DIR)..."
	mkdir -p $(TEMPLATE_DIR)
	cp -R $(INSTALL_PATH)/content $(TEMPLATE_DIR)/
	ddev exec wp db export $(TEMPLATE_DIR)/sql.sql  
	sed -i "s|$(WP_HOME)|__SITEURL__|g" $(TEMPLATE_DIR)/sql.sql

	@echo "✅ Export complete: $(TEMPLATE_DIR)"

.PHONY: create-repo

create-repo:
	@echo "📁 Initializing Git repository in $(TEMPLATE_DIR)..."
	cd $(TEMPLATE_DIR) && \
	if [ ! -d .git ]; then \
		git init -b master && \
		git add . && \
		git commit -m "Initial commit of WordPress site export"; \
	fi

	@echo "🌐 Creating or pushing to GitHub repo $(PROJECT_NAME)..."
	cd $(TEMPLATE_DIR) && \
	if ! gh repo view $(PROJECT_NAME) > /dev/null 2>&1; then \
		gh repo create $(PROJECT_NAME) --private --source=. --remote=origin --push; \
	else \
		if ! git remote get-url origin > /dev/null 2>&1; then \
  			git remote add origin git@$(GIT_BASE)/$(PROJECT_NAME).git; \
		else \
  			git remote set-url origin git@$(GIT_BASE)/$(PROJECT_NAME).git; \
		fi && \
		git push -u origin master; \
	fi

	@echo "✅ GitHub repo created and pushed."



# Import a site from a remote template repo
.PHONY: import-site
import-site:
ifndef TEMPLATE
	$(error TEMPLATE is not set. Usage: make import-site TEMPLATE=portfolio)
endif

	@echo "🔧 Cloning template $(TEMPLATE)..."
	rm -rf $(TEMPLATE)
	git clone --depth 1 git@$(GIT_BASE)/$(TEMPLATE).git $(TEMPLATE)

	@echo "🧩 Copying content..."
	rm -rf $(INSTALL_PATH)/content
	cp -R $(TEMPLATE)/content $(INSTALL_PATH)/

	@echo "🔁 Updating site URL and importing SQL into $(DB_NAME)..."
	sed "s|__SITEURL__|$(WP_HOME)|g" $(TEMPLATE)/sql.sql | ddev exec mysql -u $(DB_USER) -p$(DB_PASSWORD) -h $(DB_HOST) $(DB_NAME)

	@echo "👤 Setting up admin user..."
	ddev exec wp user delete $(ADMIN_USER) --yes
	ddev exec wp user create $(ADMIN_USER) $(ADMIN_EMAIL) --user_pass=$(ADMIN_PASS) --role=administrator 

	@echo "🧹 Flushing permalinks..."
	ddev exec wp rewrite flush --hard 

	@echo "🧼 Cleaning up..."
	rm -rf $(TEMPLATE)
	find $(INSTALL_PATH) -name 'Zone.Identifier' -type f -delete

	@echo "✅ Site ready at $(WP_HOME)"


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
	ddev exec wp option update date_format 'd/m/Y'
	ddev exec wp option update time_format 'H:i'

	ddev exec wp post create --post_type=page --post_title="Home" --post_status=publish --allow-root
	ddev exec wp option update show_on_front 'page' --allow-root
	ddev exec wp option update page_on_front 5 --allow-root

	ddev exec wp option update default_comment_status 'closed' --allow-root

	$(call message_primary, "PERMALINKS")
	ddev exec wp option get permalink_structure
	ddev exec wp option update permalink_structure '/%postname%'
	ddev exec wp rewrite flush --hard

	ddev exec wp widget reset --all --allow-root

	@echo "WordPress Settings Applied!"


install-themes:
	ddev exec wp theme install $(WP_THEMES) --activate
	@echo "--- Initializing Theme Installation ---"
	@echo "1. Preparing target theme directory: $(WP_THEMES_DEST_DIR)..."
	ddev exec sudo chown -R www-data:www-data $(WP_THEMES_DEST_DIR) || { echo "ERROR: Failed to change ownership"; exit 1; }
	ddev exec sudo chmod -R ug+rwX,o+rX $(WP_THEMES_DEST_DIR) || { echo "ERROR: Failed to set permissions"; exit 1; }

	@echo "2. Installing WordPress themes..."
	@for theme in $(WP_THEMES); do \
 		echo "  - Installing $$theme..."; \
 		ddev exec wp theme install $$theme --activate --allow-root; \
 		if [ $$? -ne 0 ]; then \
 			echo "    Error: Failed to install and activate $$theme."; \
 			exit 1; \
 		fi; \
 	done
	@echo "All specified WordPress themes installed and activated successfully!"

install-themes-zip: 
	@echo "--- Initializing Custom Theme (ZIP) Installation ---"
	@for theme_zip in $(WP_THEMES_ZIP); do \
		echo "  - Installing $$theme_zip..."; \
		ddev wp theme install $$theme_zip --activate --allow-root; \
		if [ $$? -ne 0 ]; then \
			echo "    Error: Failed to install and activate $$theme_zip."; \
			exit 1; \
		fi; \
	done
	@echo "All specified custom WordPress themes installed and activated successfully!"

install-plugins:
	@echo "--- Initializing Plugin Installation ---"
	@for plugin in $(WP_PLUGINS); do \
 		echo "  - Installing $$plugin..."; \
 		ddev wp plugin install $$plugin --activate --skip-plugins --allow-root; \
 		if [ $$? -ne 0 ]; then \
 			echo "    Error: Failed to install and activate $$plugin."; \
 			exit 1; \
 		fi; \
 	done
	@echo "All specified WordPress plugins installed and activated successfully!"

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

drop:
	ddev exec mysql -e "DROP DATABASE IF EXISTS db; CREATE DATABASE db;"

# Target to fix host permissions for the plugins directory
fix-host-permissions:
	@echo "--- Fixing host permissions for plugins directory: $(HOST_PATH)$(WP_PLUGINS_DEST_DIR) ---"
	@mkdir -p $(HOST_PATH)$(WP_PLUGINS_DEST_DIR)
	@sudo chmod -R u+rwX,g+rwX,o+rX $(HOST_PATH)$(WP_PLUGINS_DEST_DIR) || { echo "ERROR: Failed to set permissions on host."; exit 1; }
	@sudo chown -R $(shell id -un):$(shell id -gn) $(HOST_PATH)$(WP_PLUGINS_DEST_DIR) || { echo "ERROR: Failed to change ownership on host."; exit 1; }
	@echo "Host permissions for plugins fixed."

	@echo "--- Fixing host permissions for themes directory: $(HOST_PATH)$(WP_THEMES_DEST_DIR) ---"
	@mkdir -p $(HOST_PATH)$(WP_THEMES_DEST_DIR)
	@sudo chmod -R u+rwX,g+rwX,o+rX $(HOST_PATH)$(WP_THEMES_DEST_DIR) || { echo "ERROR: Failed to set permissions on host."; exit 1; }
	@sudo chown -R $(shell id -un):$(shell id -gn) $(HOST_PATH)$(WP_THEMES_DEST_DIR) || { echo "ERROR: Failed to change ownership on host."; exit 1; }
	@echo "Host permissions for themes fixed."
