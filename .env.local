# ============================================================================
# WordPress + DDEV Project Makefile
# ----------------------------------------------------------------------------
# Purpose
#   Automate common tasks for a DDEV-based WordPress project: initializing the
#   environment, installing/configuring WordPress, exporting/importing a site
#   template, cleaning the DB, building theme assets, managing Git/GitHub, and
#   installing/updating themes/plugins (including GitHub-hosted ones).
#
# Prerequisites
#   - DDEV (https://ddev.readthedocs.io/)
#   - WP-CLI inside DDEV (ddev exec wp ...)
#   - Composer (used via ddev exec composer)
#   - Node.js + npm for building assets (inside theme directory)
#   - Git and, if using GitHub operations, the GitHub CLI (gh) and SSH auth
#
# Quick start
#   1) Configure env:  make init
#   2) Install WP:     make install-wp
#   3) Configure WP:   make config-wp
#   4) Themes/plugins: make install-themes install-plugins (and/or install-git-plugins)
#
# Useful targets
#   - export-site:  Export sanitized content + DB to TEMPLATE_DIR for reuse
#   - import-site:  Import a template repo into this instance (TEMPLATE=repo)
#   - clean-db:     Remove transients, junk posts/comments, etc. before export
#   - build-assets: Build frontend assets via npm in your theme directory
#   - create-repo:  Initialize/push export folder to new/existing GitHub repo
#   - update-*:     Update WP core, plugins, and git submodules
#
# Notes
#   - Environment variables are primarily read from .env.local (if present).
#   - Some defaults are set below as fallbacks.
#   - This Makefile uses ddev exec to run commands inside the container.
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Environment & Defaults
# ----------------------------------------------------------------------------
# Load environment variables from .env.local when present. We expose variables
# by exporting all keys found in .env.local (ignoring comments and empty lines).
# Some variables (with quotes) are stripped for safety.
ifeq ($(wildcard .env.local),.env.local)
    include .env.local
    export $(shell sed 's/^#.*//g' .env.local | sed '/^$$/d' | cut -d'=' -f1)
    WP_BLOGNAME := $(strip $(subst ",,$(WP_BLOGNAME)))
    WP_BLOGDESCRIPTION := $(strip $(subst ",,$(WP_BLOGDESCRIPTION)))
    GITHUB_PLUGINS_REPOS := $(strip $(subst ",,$(GITHUB_PLUGINS_REPOS)))
endif

# Default fallbacks if not provided via .env.local
# PROJECT_NAME must typically come from .ddev/config.yaml or your env
WP_HOME ?= https://$(PROJECT_NAME).ddev.site
WP_SITEURL ?= $(WP_HOME)/wp
DB_HOST ?= db
DB_NAME ?= db
DB_USER ?= db
DB_PASSWORD ?= db
DB_TABLE_PREFIX ?= ntdst_
TEMPLATE_DIR ?= export

# Expected additional envs (commonly defined in .env.local):
# - INSTALL_PATH:       WP docroot inside container (e.g., app or .)
# - THEME_NAME:         Active theme folder name under content/themes/
# - WP_VERSION:         Target WP version for download (e.g., 6.5.5)
# - ADMIN_USER/PASS/EMAIL: WP admin credentials for install
# - WP_WPLANG, WP_TIMEZONE: WP locale/timezone (e.g., en_US, Europe/Paris)
# - WP_THEMES:          Space-separated list of themes to install from wp.org
# - WP_THEMES_DEST_DIR: Absolute path to wp-content/themes (inside container)
# - WP_THEMES_ZIP:      Space-separated list of zip URLs/paths for custom themes
# - WP_PLUGINS:         Space-separated list of plugins to install from wp.org
# - WP_PLUGINS_DEST_DIR: Absolute path to wp-content/plugins (inside container)
# - GITHUB_PLUGINS_REPOS: Space-separated git+ssh repo URLs for plugins
# - GIT_BASE:           e.g., github.com:<org> (used by gh and git remote URLs)
# - PROJECT_NAME:       Used when creating/viewing GitHub repos

# ----------------------------------------------------------------------------
# 2. Environment & WordPress Setup
# ----------------------------------------------------------------------------
.PHONY: init config install-wp config-wp

# init: Configure DDEV, restart environment, install PHP deps, and download WP.
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

# config: Ensure an environment file exists.
# NOTE: This copies .env.example to app/.env if .env is missing.
#       Verify paths (.env vs .env.local) match your convention.
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

# install-wp: Create DB if needed and perform WP installation with provided vars.
install-wp:
	@echo "Running install-wp..."
	ddev exec wp db check >/dev/null 2>&1 || ddev exec wp db create
	@echo "INSTALL WP"
	ddev exec wp core install \
		--url='$(WP_HOME)' \
		--title='$(WP_BLOGNAME)' \
		--admin_user='$(ADMIN_USER)' \
		--admin_password='$(ADMIN_PASS)' \
		--admin_email='$(ADMIN_EMAIL)' \
		--skip-plugins=hello \
		--skip-themes=twentyfifteen,twentysixteen,twentyseventeen,twentynineteen,twentytwenty

	@echo "WordPress installed!"

# config-wp: Apply general settings, create a Home page, set permalinks, etc.
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

# ----------------------------------------------------------------------------
# 3. Site Import / Export
# ----------------------------------------------------------------------------
.PHONY: create-template export-site import-site
# create-template: Clean DB then export content and SQL into TEMPLATE_DIR.
create-template: clean-db
	@echo "📦 Exporting site as template"

	@echo "📁 Saving cleaned export to $(TEMPLATE_DIR)..."
	@mkdir -p $(TEMPLATE_DIR)
	@cp -R $(INSTALL_PATH)/content $(TEMPLATE_DIR)/ >/dev/null 2>&1 && \
		echo "   ✅ Content copied" || { echo "   ❌ ERROR copying content"; exit 1; }

	@echo "💾 Exporting database..."
	@ddev exec wp db export $(TEMPLATE_DIR)/sql.sql >/dev/null 2>&1 && \
		echo "   ✅ Database exported" || { echo "   ❌ ERROR exporting database"; exit 1; }

	@echo "🔧 Replacing site URL with placeholder..."
	@sed -i "s|$(WP_HOME)|__SITEURL__|g" $(TEMPLATE_DIR)/sql.sql && \
		echo "   ✅ URL replaced" || { echo "   ❌ ERROR updating SQL file"; exit 1; }

	@echo "✅ Export complete: $(TEMPLATE_DIR)"

# export-site: Initialize a Git repo in TEMPLATE_DIR and push to GitHub.
# - Requires: gh CLI authenticated, SSH agent forwarded to DDEV if needed.
export-site:
	@echo "📁 Initializing Git repository in $(TEMPLATE_DIR)..."
	@cd $(TEMPLATE_DIR) && \
	if [ ! -d .git ]; then \
		git init -b main >/dev/null 2>&1 && \
		git add . && \
		git commit -m "Initial commit of WordPress site export" >/dev/null 2>&1 && \
		echo "   ✅ Repo initialized"; \
	else \
		if ! git diff-index --quiet HEAD -- || [ "$$(git rev-list --all --count)" -eq 0 ]; then \
			git add .; \
			if ! git diff-index --quiet HEAD --; then \
				git commit -m "Update WordPress site export" >/dev/null 2>&1 && \
				echo "   ✨ Changes committed"; \
			elif [ "$$(git rev-list --all --count)" -eq 0 ]; then \
				git commit --allow-empty -m "Initial empty commit for export" >/dev/null 2>&1 && \
				echo "   📝 Empty initial commit created"; \
			fi; \
		else \
			echo "   ✔️ No changes to commit"; \
		fi; \
	fi

	@echo "🔑 Authenticating with DDEV SSH Agent..."
	@ddev auth ssh >/dev/null 2>&1 || { \
		echo "   ❌ ERROR: ddev auth ssh failed."; \
		exit 1; \
	}
	@echo "   ✅ SSH authentication successful"

	@echo "🌐 Creating or pushing to GitHub repo: $(PROJECT_NAME)"
	@cd $(TEMPLATE_DIR) && { \
		if ! gh repo view $(PROJECT_NAME) >/dev/null 2>&1; then \
			if ! gh repo create $(PROJECT_NAME) --private --source=. --remote=origin --push; then \
				echo "   ❌ ERROR: Failed to create repo $(PROJECT_NAME)"; \
				exit 1; \
			else \
				echo "   🚀 Repo created and pushed to GitHub"; \
			fi; \
		else \
			if ! git remote get-url origin >/dev/null 2>&1; then \
				git remote add origin git@$(GIT_BASE)/$(PROJECT_NAME).git; \
			else \
				git remote set-url origin git@$(GIT_BASE)/$(PROJECT_NAME).git; \
			fi; \
			if ! git push -u origin main; then \
				echo "   ❌ ERROR: Failed to push to GitHub"; \
				exit 1; \
			else \
				echo "   ⬆️ Changes pushed to GitHub"; \
			fi; \
		fi; \
	}

	@echo "✅ Done!"

# import-site: Pull a template repo (TEMPLATE=<repo>) and import into this site.
# Usage: make import-site TEMPLATE=portfolio
import-site:
ifndef TEMPLATE
	$(error TEMPLATE is not set. Usage: make import-site TEMPLATE=portfolio)
endif

	@echo "🔧 Cloning template: $(TEMPLATE)"
	@if git clone --depth 1 git@$(GIT_BASE)/$(TEMPLATE).git $(TEMPLATE) >/dev/null 2>&1; then \
		echo "   ✅ Template cloned"; \
	else \
		echo "   ❌ ERROR: Failed to clone repo $(TEMPLATE)"; \
		exit 1; \
	fi

	@echo "🧩 Copying content into WordPress..."
	@rm -rf $(INSTALL_PATH)/content
	@cp -R $(TEMPLATE)/content $(INSTALL_PATH)/ >/dev/null 2>&1 && \
		echo "   ✅ Content copied" || { echo "   ❌ ERROR copying content"; exit 1; }

	@echo "🔁 Importing database into $(DB_NAME)..."
	@ddev exec mysql -u $(DB_USER) -p$(DB_PASSWORD) -h $(DB_HOST) $(DB_NAME) < $(TEMPLATE)/sql.sql >/dev/null 2>&1 && \
		echo "   ✅ Database imported" || { echo "   ❌ ERROR importing database"; exit 1; }

	@echo "🔧 Replacing placeholder URLs..."
	@ddev exec wp search-replace '__SITEURL__' '$(WP_HOME)' --all-tables >/dev/null 2>&1 && \
		echo "   ✅ URLs updated" || { echo "   ❌ ERROR updating URLs"; exit 1; }

	@echo "🧹 Flushing caches..."
	@ddev exec wp cache flush >/dev/null 2>&1 && \
		echo "   ✅ Cache flushed"

	@echo "🔗 Flushing permalinks..."
	@ddev exec wp rewrite flush --hard >/dev/null 2>&1 && \
		echo "   ✅ Permalinks flushed"

	@echo "🧼 Cleaning up temporary files..."
	@rm -rf $(TEMPLATE)
	@find $(INSTALL_PATH) -name 'Zone.Identifier' -type f -delete
	@echo "   ✅ Cleanup complete"

	@echo "✅ Site imported and ready at: $(WP_HOME)"

# ----------------------------------------------------------------------------
# 4. Database Utilities
# ----------------------------------------------------------------------------
# clean-db: Remove transients, spam/trash comments, orphaned meta, auto-drafts,
#           and revisions to produce a cleaner export.
.PHONY: clean-db
clean-db:
	@echo "🧹 Cleaning database before export..."

	@echo "   🗑️  Deleting transients..."
	@ddev exec wp transient delete --all >/dev/null 2>&1 || true
	@ddev exec wp option delete _site_transient_update_core >/dev/null 2>&1 || true
	@ddev exec wp option delete _site_transient_update_plugins >/dev/null 2>&1 || true
	@ddev exec wp option delete _site_transient_update_themes >/dev/null 2>&1 || true
	@ddev exec wp option delete user_count >/dev/null 2>&1 || true
	@ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)options WHERE option_name LIKE '_transient_%' OR option_name LIKE '_site_transient_%';" >/dev/null 2>&1 || true
	@echo "      ✅ Transients cleaned"

	@echo "   🗑️  Removing junk comments..."
	@ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)comments WHERE comment_approved IN ('spam','trash');" >/dev/null 2>&1 || true
	@ddev exec wp db query "DELETE cm FROM $(DB_TABLE_PREFIX)commentmeta cm LEFT JOIN $(DB_TABLE_PREFIX)comments wc ON cm.comment_id = wc.comment_ID WHERE wc.comment_ID IS NULL;" >/dev/null 2>&1 || true
	@echo "      ✅ Comments cleaned"

	@echo "   🗑️  Removing junk posts..."
	@ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)posts WHERE post_status='auto-draft' OR post_type='revision';" >/dev/null 2>&1 || true
	@ddev exec wp db query "DELETE pm FROM $(DB_TABLE_PREFIX)postmeta pm LEFT JOIN $(DB_TABLE_PREFIX)posts wp ON pm.post_id = wp.ID WHERE wp.ID IS NULL;" >/dev/null 2>&1 || true
	@ddev exec wp db query "DELETE FROM $(DB_TABLE_PREFIX)postmeta WHERE meta_key IN ('_edit_lock','_edit_last');" >/dev/null 2>&1 || true
	@echo "      ✅ Posts & metadata cleaned"

	@echo "✅ Database cleaned"

# ----------------------------------------------------------------------------
# 5. Assets
# ----------------------------------------------------------------------------
.PHONY: build-assets
# build-assets: Install npm deps and run the theme build via npm (Vite).
build-assets:
	@echo "⚡ Building assets with Vite..."
	@cd $(INSTALL_PATH)/content/themes/$(THEME_NAME) && \
		npm install >/dev/null 2>&1 && \
		npm run build >/dev/null 2>&1 && \
		echo "   ✅ Assets built" || { echo "   ❌ ERROR building assets"; exit 1; }


# ----------------------------------------------------------------------------
# 7. Themes & Plugins
# ----------------------------------------------------------------------------
.PHONY: install-themes install-themes-zip install-plugins install-git-plugins

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

install-git-plugins:
	@echo "--- Initializing GitHub Plugin Installation ---"
	@echo "1. Ensuring DDEV SSH Agent is Authenticated..."
	@ddev auth ssh || { echo "ERROR: ddev auth ssh failed. Ensure your SSH agent is running and keys are added (e.g., 'eval \"\$$\(ssh-agent -s\)\"; ssh-add ~/.ssh/id_ed25519')"; exit 1; }

	@echo "2. Preparing plugin directory $(WP_PLUGINS_DEST_DIR) on host..."
	@mkdir -p $(WP_PLUGINS_DEST_DIR)
	@sudo chown -R $(USER):$(USER) $(WP_PLUGINS_DEST_DIR)
	@chmod -R ug+rwX,o+rX $(WP_PLUGINS_DEST_DIR)

	@echo "3. Cloning and Activating GitHub Plugins..."
	@for repo_url in $(GITHUB_PLUGINS_REPOS); do \
		repo_name=$$(basename $$repo_url .git); \
		echo "  -> Processing $$repo_name from $$repo_url..."; \
		ddev exec bash -c "git clone '$$repo_url' '$(WP_PLUGINS_DEST_DIR)/$$repo_name' || ( cd '$(WP_PLUGINS_DEST_DIR)/$$repo_name' && git pull )"; \
		ddev exec wp plugin activate "$$repo_name/$$repo_name.php" || \
		echo "WARNING: Could not activate $$repo_name. Maybe it's already active or the main file name is wrong."; \
	done

	@echo "--- GitHub Plugins Installation Complete ---"

# ----------------------------------------------------------------------------
# 8. Updates
# ----------------------------------------------------------------------------
.PHONY: update-wp update-plugins update-git update-all

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

