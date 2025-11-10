# WordPress Development Makefile
# Simple, secure workflow for small teams
#
# DEPLOYMENT STRATEGY: Git bundles (no GitHub/remote repo required!)
# WORKFLOW: setup → dev → save → deploy → ship
#
# Version: 3.0
# ═══════════════════════════════════════════════════════════════════════════
#                          PROJECT CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

PROJECT_NAME := fuse
STAGING_HOST := combell-fuse-staging
STAGING_PATH := /data/sites/web/fusepilatesbe/subsites/staging.fusepilates.be
STAGING_URL := https://staging.fusepilates.be
PRODUCTION_HOST := # Configure when ready
PRODUCTION_PATH := # Configure when ready
PRODUCTION_URL := # Configure when ready

# ═══════════════════════════════════════════════════════════════════════════
#                     FOLDER STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════
WEB_ROOT := app
CONTENT_PATH := $(WEB_ROOT)/content
UPLOADS_PATH := $(CONTENT_PATH)/uploads
PLUGINS_PATH := $(CONTENT_PATH)/plugins
THEMES_PATH := $(CONTENT_PATH)/themes
MUPLUGINS_PATH := $(CONTENT_PATH)/mu-plugins

# Remote server paths (no 'app/' prefix on remote)
REMOTE_WP_PATH := wp

# ═══════════════════════════════════════════════════════════════════════════
#                          LOCAL DEVELOPMENT (DDEV)
# ═══════════════════════════════════════════════════════════════════════════

LOCAL_URL := https://$(PROJECT_NAME).ddev.site
ENV_FILE := .env

# ═══════════════════════════════════════════════════════════════════════════
#                          STORAGE & TEMPLATES
# ═══════════════════════════════════════════════════════════════════════════

BACKUP_DIR := backups
TEMP_DIR := /tmp
GITHUB_USER := netdust
TEMPLATE_PREFIX := wp-template-

# ═══════════════════════════════════════════════════════════════════════════
#                          INTERNAL (Don't modify)
# ═══════════════════════════════════════════════════════════════════════════

RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

# Ensure system binaries are available (appended to preserve user PATH priority)
export PATH := $(PATH):/usr/bin:/bin

# === HELP & STATUS ===
.PHONY: help
help: ## Show this help
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(BLUE)║  $(PROJECT_NAME) - WordPress Bedrock Development	$(RESET)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Branch:$(RESET) $(shell git branch --show-current 2>/dev/null || echo 'none')"
	@echo "$(GREEN)DDEV:$(RESET) $(shell if ddev describe >/dev/null 2>&1; then echo 'running'; else echo 'not installed'; fi)"
	@echo ""
	@echo "$(YELLOW)🚀 Deployment Strategy:$(RESET) Git bundles (no remote repo needed!)"
	@echo "   • Direct local → server deployment"
	@echo "   • No GitHub/GitLab dependency"
	@echo "   • Secure, verified transfers"
	@echo ""
	@echo "$(YELLOW)📋 INITIAL SETUP$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "setup" "Complete local setup"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "setup-staging" "Setup staging server with DB/files"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "setup-production" "Setup production server (requires confirmation)"
	@echo ""
	@echo "$(YELLOW)🔄 DAILY WORKFLOW$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "dev" "Start development (ensures safe branch)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "save" "Commit your work (auto-stages all changes)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "deploy" "Deploy code to staging (via secure bundle)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "deploy-test" "Test deployment (dry run - shows what would be deployed)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "ship" "Ship to production (with backup & verification)"
	@echo ""
	@echo "$(YELLOW)🌿 FEATURE BRANCHES$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "feature" "Create feature branch (make feature name=my-feature)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "finish" "Merge feature to staging and delete branch"
	@echo ""
	@echo "$(YELLOW)🔁 SYNC TOOLS$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "sync-to-local" "Pull DB & files from staging to local"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "sync-to-staging" "Push DB & files from local to staging"
	@echo ""
	@echo "$(YELLOW)📦 TEMPLATES$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "template-save" "Export site as reusable template"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "template-load" "Import template into current site"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "template-list" "List available templates"
	@echo ""
	@echo "$(YELLOW)🛠️  UTILITIES$(RESET)"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "status" "Show complete project status"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "backup" "Create local backup"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "logs" "Show DDEV logs"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "restart" "Restart DDEV"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "stop" "Stop DDEV"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "ssh" "SSH to staging"
	@printf "  $(GREEN)%-20s$(RESET) %s\n" "rollback" "Emergency rollback (staging or production)"
	@echo ""
	@echo "$(BLUE)Quickstart:$(RESET) make setup && make dev"
	@echo "$(BLUE)Workflow:$(RESET) dev → save → deploy → ship"

# === INITIAL SETUP ===

setup: ## Complete local setup
	@echo "$(BLUE)Setting up $(PROJECT_NAME) locally...$(RESET)"
	@$(MAKE) --no-print-directory _check-requirements
	@if [ ! -f $(ENV_FILE) ]; then \
		cp $(ENV_EXAMPLE) $(ENV_FILE) && \
		echo "$(YELLOW)✓ Created $(ENV_FILE) - Please configure it!$(RESET)"; \
	fi
	@if ! ddev describe >/dev/null 2>&1; then \
		ddev config --docroot=$(WEB_ROOT) --project-type=wordpress --project-name=$(PROJECT_NAME) && \
		echo "$(GREEN)✓ DDEV configured$(RESET)"; \
	fi
	@ddev start
	@ddev composer install --working-dir=$(WEB_ROOT)
	@$(MAKE) --no-print-directory _git-setup
	@echo "$(GREEN)✅ Local setup complete!$(RESET)"
	@echo "$(YELLOW)Next steps:$(RESET)"
	@echo "  1. Configure $(ENV_FILE) file"
	@echo "  2. Run 'make setup-staging' to prepare staging"
	@echo "  3. Run 'make dev' to start working"

setup-staging: ## Setup staging server with DB/files
	@echo "$(BLUE)Setting up staging server...$(RESET)"
	@$(MAKE) --no-print-directory _check-staging-config
	@$(MAKE) --no-print-directory _ensure-clean-git
	@$(MAKE) --no-print-directory _verify-ssh-access host=$(STAGING_HOST)
	@$(MAKE) --no-print-directory _init-remote-git host=$(STAGING_HOST) path=$(STAGING_PATH) env=staging
	@$(MAKE) --no-print-directory _create-bundle
	@$(MAKE) --no-print-directory _deploy-bundle host=$(STAGING_HOST) path=$(STAGING_PATH) env=staging
	@if ddev describe >/dev/null 2>&1; then \
		echo "$(YELLOW)Exporting local database...$(RESET)"; \
		ddev export-db --file=$(TEMP_DIR)/staging-init.sql.gz && gunzip $(TEMP_DIR)/staging-init.sql.gz; \
		sed -i.bak "s|$(LOCAL_URL)|$(STAGING_URL)|g" $(TEMP_DIR)/staging-init.sql && rm -f $(TEMP_DIR)/staging-init.sql.bak; \
		echo "$(YELLOW)Pushing database to staging...$(RESET)"; \
		scp $(TEMP_DIR)/staging-init.sql $(STAGING_HOST):$(TEMP_DIR)/; \
		ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp db import $(TEMP_DIR)/staging-init.sql --path=$(REMOTE_WP_PATH) && rm $(TEMP_DIR)/staging-init.sql"; \
		rm $(TEMP_DIR)/staging-init.sql; \
		if [ -d "$(UPLOADS_PATH)" ]; then \
			echo "$(YELLOW)Pushing uploads...$(RESET)"; \
			rsync -avz $(UPLOADS_PATH)/ $(STAGING_HOST):$(STAGING_PATH)/content/uploads/; \
		fi; \
		ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp cache flush --path=$(REMOTE_WP_PATH)"; \
		echo "$(GREEN)✅ Staging setup complete with DB and files!$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  Staging Git ready. Run from active DDEV to push DB/files$(RESET)"; \
	fi

setup-production: ## Setup production server (requires confirmation)
	@make _check-production-config
	@echo "$(RED)╔════════════════════════════════════════╗$(RESET)"
	@echo "$(RED)║     SETUP PRODUCTION SERVER?           ║$(RESET)"
	@echo "$(RED)╚════════════════════════════════════════╝$(RESET)"
	@make _confirm message="This will initialize production. Continue?"
	@echo "$(YELLOW)Testing SSH connection...$(RESET)"
	@ssh $(PRODUCTION_HOST) "echo 'SSH OK'" || { echo "$(RED)Cannot connect to production$(RESET)"; exit 1; }
	@ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) && \
		git init 2>/dev/null || true && \
		git config receive.denyCurrentBranch ignore && \
		git config user.name Deploy && \
		git config user.email deploy@localhost"
	@echo "$(GREEN)✅ Production server initialized$(RESET)"

# === DAILY WORKFLOW ===

dev: ## Start development (ensures safe branch)
	@echo "$(BLUE)Starting development...$(RESET)"
	@$(MAKE) --no-print-directory _check-ddev
	@ddev start
	@$(MAKE) --no-print-directory _ensure-safe-branch
	@echo "$(GREEN)✅ Ready on branch: $(shell git branch --show-current)$(RESET)"
	@echo "$(GREEN)🌐 Local: $(LOCAL_URL)$(RESET)"

save: ## Commit your work (auto-stages all changes)
	@$(MAKE) --no-print-directory _ensure-safe-branch
	@if [ -z "$$(git status --porcelain 2>/dev/null)" ]; then \
		echo "$(YELLOW)No changes to save$(RESET)"; \
	else \
		git add -A; \
		echo "$(YELLOW)Changes to commit:$(RESET)"; \
		git status --short; \
		read -p "Commit message: " msg && \
		if [ -n "$$msg" ]; then \
			git commit -m "$$msg" && \
			echo "$(GREEN)✅ Saved: $$msg$(RESET)"; \
		else \
			echo "$(RED)❌ Commit cancelled$(RESET)"; \
		fi; \
	fi

deploy: ## Deploy code to staging (via secure bundle)
	@echo "$(BLUE)Deploying to staging...$(RESET)"
	@$(MAKE) --no-print-directory _ensure-clean-git
	@$(MAKE) --no-print-directory _verify-ssh-access host=$(STAGING_HOST)
	@$(MAKE) --no-print-directory _create-bundle
	@$(MAKE) --no-print-directory _deploy-bundle host=$(STAGING_HOST) path=$(STAGING_PATH) env=staging
	@echo "$(GREEN)🌐 View at: $(STAGING_URL)$(RESET)"

ship: ## Ship to production (with backup & verification)
	@make _check-production-config
	@echo "$(RED)╔════════════════════════════════════════╗$(RESET)"
	@echo "$(RED)║         SHIP TO PRODUCTION?            ║$(RESET)"
	@echo "$(RED)╚════════════════════════════════════════╝$(RESET)"
	@make _confirm message="This deploys to LIVE site. Continue?"
	@make _ensure-clean-git
	@make _backup-production
	@make _verify-ssh-access host=$(PRODUCTION_HOST)
	@make _create-bundle
	@make _deploy-bundle host=$(PRODUCTION_HOST) path=$(PRODUCTION_PATH) env=production
	@echo "$(GREEN)🌐 Live at: $(PRODUCTION_URL)$(RESET)"

# === FEATURE BRANCHES ===

feature: ## Create feature branch (make feature name=my-feature)
	@if [ -z "$(name)" ]; then \
		echo "$(RED)Usage: make feature name=my-feature$(RESET)"; \
		exit 1; \
	fi
	@if ! echo "$(name)" | grep -qE '^[a-zA-Z][a-zA-Z0-9._-]*$$'; then \
		echo "$(RED)❌ Invalid branch name. Use only letters, numbers, dots, hyphens (must start with letter)$(RESET)"; \
		exit 1; \
	fi
	@if git show-ref --verify --quiet refs/heads/feature/$(name); then \
		echo "$(RED)❌ Feature branch 'feature/$(name)' already exists$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Switching to staging branch...$(RESET)"
	@git checkout staging 2>/dev/null || git checkout -b staging
	@echo "$(YELLOW)Creating feature branch...$(RESET)"
	@git checkout -b feature/$(name)
	@echo "$(GREEN)✅ Created feature/$(name)$(RESET)"
	@echo "$(YELLOW)Work on your feature, then 'make finish' to merge$(RESET)"

finish: ## Merge feature to staging and delete branch
	@BRANCH=$$(git branch --show-current); \
	if ! echo "$$BRANCH" | grep -q "^feature/"; then \
		echo "$(RED)❌ Not on a feature branch (current: $$BRANCH)$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Merging $$BRANCH to staging...$(RESET)"
	@$(MAKE) --no-print-directory _ensure-clean-git
	@FEATURE=$$(git branch --show-current); \
	echo "$(YELLOW)About to merge: $$FEATURE → staging$(RESET)"; \
	read -p "Continue? [y/N]: " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "$(RED)❌ Merge cancelled$(RESET)"; \
		exit 1; \
	fi; \
	if git checkout staging; then \
		if git merge --no-ff "$$FEATURE" -m "Merge $$FEATURE"; then \
			git branch -d "$$FEATURE" && \
			echo "$(GREEN)✅ Merged $$FEATURE to staging and deleted branch$(RESET)"; \
		else \
			echo "$(RED)❌ Merge failed - resolve conflicts manually$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ Could not switch to staging branch$(RESET)"; \
		exit 1; \
	fi

##@ Database
# NOTE: Database maintenance tasks use raw SQL via wp db query for efficiency
# This is an EXCEPTION to the project's "Zero raw SQL" rule, which applies to
# application code. Admin/maintenance operations are acceptable use cases.

.PHONY: db-clean
db-clean: ## Clean up WordPress database (remove spam, revisions, transients, etc.)
	@echo "🧹 Starting WordPress database cleanup..."

	# Remove spam and trash comments
	@echo "🗑️  Removing spam and trash comments..."
	@spam_ids=$$(ddev wp comment list --status=spam --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$spam_ids" ]; then \
		ddev wp comment delete $$spam_ids --force; \
	else \
		echo "No spam comments found"; \
	fi
	@trash_ids=$$(ddev wp comment list --status=trash --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$trash_ids" ]; then \
		ddev wp comment delete $$trash_ids --force; \
	else \
		echo "No trash comments found"; \
	fi

	# Remove post revisions
	@echo "📝 Cleaning up post revisions..."
	@revision_ids=$$(ddev wp post list --post_type=revision --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$revision_ids" ]; then \
		ddev wp post delete $$revision_ids --force; \
	else \
		echo "No revisions found"; \
	fi

	# Remove auto-drafts
	@echo "📄 Removing auto-drafts..."
	@autodraft_ids=$$(ddev wp post list --post_status=auto-draft --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$autodraft_ids" ]; then \
		ddev wp post delete $$autodraft_ids --force; \
	else \
		echo "No auto-drafts found"; \
	fi

	# Clean up transients
	@echo "⏰ Cleaning expired transients..."
	@ddev wp transient delete --expired 2>/dev/null || echo "No expired transients"
	@echo "🧽 Removing all transients..."
	@ddev wp transient delete --all 2>/dev/null || echo "No transients to delete"

	# Remove orphaned postmeta
	@echo "🔗 Removing orphaned postmeta..."
	@ddev wp db query "DELETE pm FROM wp_postmeta pm LEFT JOIN wp_posts wp ON wp.ID = pm.post_id WHERE wp.ID IS NULL" 2>/dev/null || echo "Postmeta cleanup completed"

	# Remove orphaned term relationships
	@echo "🏷️  Cleaning term relationships..."
	@ddev wp db query "DELETE tr FROM wp_term_relationships tr LEFT JOIN wp_posts p ON p.ID = tr.object_id WHERE p.ID IS NULL" 2>/dev/null || echo "Term relationships cleaned"

	# Remove unused terms
	@echo "📚 Removing unused terms..."
	@ddev wp db query "DELETE t FROM wp_terms t LEFT JOIN wp_term_taxonomy tt ON tt.term_id = t.term_id WHERE tt.term_id IS NULL" 2>/dev/null || echo "Unused terms cleaned"

	# Remove pingbacks and trackbacks
	@echo "🔄 Removing pingbacks and trackbacks..."
	@pingback_ids=$$(ddev wp comment list --type=pingback --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$pingback_ids" ]; then \
		ddev wp comment delete $$pingback_ids --force; \
	else \
		echo "No pingbacks found"; \
	fi
	@trackback_ids=$$(ddev wp comment list --type=trackback --format=ids 2>/dev/null || echo ""); \
	if [ ! -z "$$trackback_ids" ]; then \
		ddev wp comment delete $$trackback_ids --force; \
	else \
		echo "No trackbacks found"; \
	fi

	# Clean up orphaned comment meta
	@echo "🛡️  Removing orphaned comment meta..."
	@ddev wp db query "DELETE FROM wp_commentmeta WHERE comment_id NOT IN (SELECT comment_id FROM wp_comments)" 2>/dev/null || echo "Comment meta cleaned"

	# Optimize database tables
	@echo "⚡ Optimizing database tables..."
	@ddev wp db optimize 2>/dev/null || echo "Database optimization completed"

	# Show database stats
	@echo "📊 Database cleanup complete! Current stats:"
	@ddev wp db size --human-readable 2>/dev/null || echo "Database size check completed"
	@echo "✅ WordPress database cleanup finished!"

.PHONY: db-clean-hardcore
db-clean-hardcore: ## AGGRESSIVE database cleanup (removes more data - use with caution!)
	@echo "⚠️  HARDCORE database cleanup - this will remove A LOT of data!"
	@read -p "Are you sure? This is irreversible! (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1

	# All the regular cleanup
	$(MAKE) --no-print-directory db-clean

	# Remove ALL post revisions via SQL
	@echo "🔥 Removing ALL post revisions..."
	@ddev wp db query "DELETE FROM wp_posts WHERE post_type = 'revision'" 2>/dev/null || echo "Revisions cleaned via SQL"

	# Remove all spam comments via SQL
	@echo "🔥 Deep cleaning comments..."
	@ddev wp db query "DELETE FROM wp_comments WHERE comment_approved = 'spam'" 2>/dev/null || echo "Spam comments cleaned via SQL"

	# Remove plugin transients and cache
	@echo "🔥 Cleaning plugin options..."
	@ddev wp db query "DELETE FROM wp_options WHERE option_name LIKE '%_transient_%'" 2>/dev/null || echo "Transients cleaned"
	@ddev wp db query "DELETE FROM wp_options WHERE option_name LIKE '%_site_transient_%'" 2>/dev/null || echo "Site transients cleaned"

	# Remove old post metadata
	@echo "🔥 Removing old metadata..."
	@ddev wp db query "DELETE FROM wp_postmeta WHERE meta_key IN ('_edit_lock', '_edit_last')" 2>/dev/null || echo "Old metadata cleaned"

	# Remove expired sessions
	@echo "🔥 Cleaning user sessions..."
	@ddev wp db query "DELETE FROM wp_usermeta WHERE meta_key LIKE 'session_tokens'" 2>/dev/null || echo "User sessions cleaned"

	@echo "🔥 HARDCORE cleanup complete!"

.PHONY: db-stats
db-stats: ## Show WordPress database statistics
	@echo "📊 WordPress Database Statistics:"
	@echo "=================================="
	@ddev wp db size --human-readable 2>/dev/null | grep -E "Size|Database" || echo "Database size: Unable to determine"
	@echo ""
	@echo "Content breakdown:"
	@echo "Posts: $$(ddev wp post list --format=count 2>/dev/null || echo 'N/A')"
	@echo "Pages: $$(ddev wp post list --post_type=page --format=count 2>/dev/null || echo 'N/A')"
	@echo "Revisions: $$(ddev wp db query --skip-column-names 'SELECT COUNT(*) FROM wp_posts WHERE post_type=\"revision\"' 2>/dev/null || echo 'N/A')"
	@echo "Comments: $$(ddev wp comment list --format=count 2>/dev/null || echo 'N/A')"
	@echo "Spam comments: $$(ddev wp comment list --status=spam --format=count 2>/dev/null || echo 'N/A')"
	@echo ""
	@echo "System data:"
	@echo "Active plugins: $$(ddev wp plugin list --status=active --format=count 2>/dev/null || echo 'N/A')"
	@echo "Transients: $$(ddev wp db query --skip-column-names 'SELECT COUNT(*) FROM wp_options WHERE option_name LIKE \"_transient_%\"' 2>/dev/null || echo 'N/A')"
	@echo "Database tables: $$(ddev wp db query --skip-column-names 'SHOW TABLES' 2>/dev/null | wc -l || echo 'N/A')"

.PHONY: db-backup
db-backup: ## Create database backup
	@echo "💾 Creating database backup..."
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	if ddev describe >/dev/null 2>&1; then \
		ddev export-db --file=$(BACKUP_DIR)/local-$$TIMESTAMP.sql.gz && \
		echo "$(GREEN)✅ Database backed up: $(BACKUP_DIR)/local-$$TIMESTAMP.sql.gz$(RESET)"; \
	else \
		echo "$(RED)❌ DDEV not running$(RESET)"; \
		exit 1; \
	fi

.PHONY: db-backup-clean
db-backup-clean: ## Backup database, then clean it up
	@echo "💾 Creating backup before cleanup..."
	$(MAKE) --no-print-directory db-backup
	@echo "🧹 Starting cleanup..."
	$(MAKE) --no-print-directory db-clean
	@echo "✅ Backup and cleanup complete!"

# === SYNC TOOLS ===

sync-to-local: ## Pull DB & files from staging to local
	@echo "$(BLUE)Syncing staging → local...$(RESET)"
	@$(MAKE) --no-print-directory _check-ddev
	@echo "$(YELLOW)Creating local backup...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@if ! ddev export-db --file=$(BACKUP_DIR)/local-before-sync-$$(date +%Y%m%d-%H%M%S).sql.gz; then \
		echo "$(RED)❌ Failed to create local backup$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Pulling database...$(RESET)"
	@if ! ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp db export --path=$(REMOTE_WP_PATH) -" > $(TEMP_DIR)/staging.sql; then \
		echo "$(RED)❌ Failed to export staging database$(RESET)"; \
		exit 1; \
	fi
	@if ! ddev import-db --src=$(TEMP_DIR)/staging.sql; then \
		echo "$(RED)❌ Failed to import staging database$(RESET)"; \
		rm -f $(TEMP_DIR)/staging.sql; \
		exit 1; \
	fi
	@rm $(TEMP_DIR)/staging.sql
	@if ! ddev wp search-replace "$(STAGING_URL)" "$(LOCAL_URL)" --all-tables; then \
		echo "$(RED)❌ Failed to update URLs in database$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Pulling files...$(RESET)"
	@if ! rsync -avz --delete $(STAGING_HOST):$(STAGING_PATH)/content/uploads/ $(UPLOADS_PATH)/; then \
		echo "$(RED)❌ Failed to sync files from staging$(RESET)"; \
		exit 1; \
	fi
	@ddev wp cache flush
	@echo "$(GREEN)✅ Synced staging → local$(RESET)"

sync-to-staging: ## Push DB & files from local to staging
	@echo "$(BLUE)Syncing local → staging...$(RESET)"
	@$(MAKE) --no-print-directory _check-ddev
	@echo "$(RED)⚠️  This will OVERWRITE staging database and files$(RESET)"
	@$(MAKE) --no-print-directory _confirm message="Continue sync to staging?"
	@echo "$(YELLOW)Backing up staging...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@if ! ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp db export --path=$(REMOTE_WP_PATH) -" > $(BACKUP_DIR)/staging-$$(date +%Y%m%d-%H%M%S).sql; then \
		echo "$(RED)❌ Failed to backup staging database$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Pushing database...$(RESET)"
	@if ! ddev export-db --file=$(TEMP_DIR)/local.sql.gz; then \
		echo "$(RED)❌ Failed to export local database$(RESET)"; \
		exit 1; \
	fi
	@gunzip $(TEMP_DIR)/local.sql.gz
	@sed -i.bak "s|$(LOCAL_URL)|$(STAGING_URL)|g" $(TEMP_DIR)/local.sql && rm -f $(TEMP_DIR)/local.sql.bak
	@if ! scp $(TEMP_DIR)/local.sql $(STAGING_HOST):$(TEMP_DIR)/; then \
		echo "$(RED)❌ Failed to transfer database to staging$(RESET)"; \
		rm -f $(TEMP_DIR)/local.sql; \
		exit 1; \
	fi
	@if ! ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp db import $(TEMP_DIR)/local.sql --path=$(REMOTE_WP_PATH) && rm $(TEMP_DIR)/local.sql"; then \
		echo "$(RED)❌ Failed to import database on staging$(RESET)"; \
		rm -f $(TEMP_DIR)/local.sql; \
		exit 1; \
	fi
	@rm -f $(TEMP_DIR)/local.sql
	@echo "$(YELLOW)Pushing files...$(RESET)"
	@if ! rsync -avz --delete $(UPLOADS_PATH)/ $(STAGING_HOST):$(STAGING_PATH)/content/uploads/; then \
		echo "$(RED)❌ Failed to sync files to staging$(RESET)"; \
		exit 1; \
	fi
	@if ! ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp cache flush --path=$(REMOTE_WP_PATH)"; then \
		echo "$(RED)❌ Failed to flush cache on staging$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Synced local → staging$(RESET)"

# === TEMPLATES ===

template-save: ## Export site as reusable template
	@if [ -z "$(name)" ]; then \
		echo "$(RED)Usage: make template-save name=my-template$(RESET)"; \
		exit 1; \
	elif ! echo "$(name)" | grep -qE '^[a-zA-Z][a-zA-Z0-9._-]*$$'; then \
		echo "$(RED)❌ Invalid template name. Use only letters, numbers, dots, hyphens (must start with letter)$(RESET)"; \
		exit 1; \
	else \
		echo "$(BLUE)Creating template: $(name)$(RESET)"; \
		$(MAKE) --no-print-directory _check-ddev && \
		TEMPLATE_DIR="$(TEMP_DIR)/$(TEMPLATE_PREFIX)$(name)" && \
		echo "$(YELLOW)Cleaning up any existing template...$(RESET)" && \
		rm -rf "$$TEMPLATE_DIR" && mkdir -p "$$TEMPLATE_DIR" && \
		echo "$(YELLOW)Exporting database...$(RESET)" && \
		ddev export-db --file="$$TEMPLATE_DIR/database.sql.gz" && \
		gunzip "$$TEMPLATE_DIR/database.sql.gz" && \
		sed -i.bak "s|$(LOCAL_URL)|__SITE_URL__|g" "$$TEMPLATE_DIR/database.sql" && \
		rm -f "$$TEMPLATE_DIR/database.sql.bak" && \
		if [ -d "$(UPLOADS_PATH)" ]; then \
			echo "$(YELLOW)Copying uploads...$(RESET)"; \
			cp -R $(UPLOADS_PATH) "$$TEMPLATE_DIR/"; \
		else \
			echo "$(YELLOW)No uploads directory found$(RESET)"; \
		fi && \
		echo "$(YELLOW)Creating README...$(RESET)" && \
		echo "# WordPress Template: $(name)" > "$$TEMPLATE_DIR/README.md" && \
		echo "Created: $$(date)" >> "$$TEMPLATE_DIR/README.md" && \
		echo "Source: $(PROJECT_NAME)" >> "$$TEMPLATE_DIR/README.md" && \
		echo "$(YELLOW)Initializing git repository...$(RESET)" && \
		cd "$$TEMPLATE_DIR" && \
		git init -b main && \
		git add . && \
		git commit -m "Template: $(name)" && \
		echo "$(YELLOW)Checking for remote repository...$(RESET)" && \
		if git ls-remote "git@github.com:$(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name).git" >/dev/null 2>&1; then \
			echo "$(YELLOW)Remote repository exists, pushing...$(RESET)" && \
			git remote add origin "git@github.com:$(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name).git" && \
			git push -u origin main && \
			echo "$(GREEN)✅ Template pushed to GitHub: $(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name)$(RESET)"; \
		else \
			echo "$(GREEN)✅ Template saved locally: $$TEMPLATE_DIR$(RESET)" && \
			echo "$(YELLOW)To push to GitHub:$(RESET)" && \
			echo "  1. Create repo: https://github.com/new" && \
			echo "  2. Name it: $(TEMPLATE_PREFIX)$(name)" && \
			echo "  3. Run: cd $$TEMPLATE_DIR && git remote add origin git@github.com:$(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name).git && git push -u origin main"; \
		fi; \
	fi

template-load: ## Import template into current site
	@if [ -z "$(name)" ]; then \
		echo "$(RED)Usage: make template-load name=my-template$(RESET)"; \
		exit 1; \
	elif ! echo "$(name)" | grep -qE '^[a-zA-Z][a-zA-Z0-9._-]*$$'; then \
		echo "$(RED)❌ Invalid template name. Must start with letter$(RESET)"; \
		exit 1; \
	else \
		echo "$(BLUE)Loading template: $(name)$(RESET)"; \
		$(MAKE) --no-print-directory _check-ddev && \
		echo "$(RED)⚠️  This will OVERWRITE your current database and uploads$(RESET)" && \
		read -p "Continue? [y/N]: " confirm && \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			TEMPLATE_DIR="$(TEMP_DIR)/$(TEMPLATE_PREFIX)$(name)"; \
			TEMPLATE_NAME="$(name)"; \
			FOUND_TEMPLATE=false; \
			echo "$(YELLOW)Looking for template...$(RESET)"; \
			if [ -d "$$TEMPLATE_DIR" ] && [ -f "$$TEMPLATE_DIR/README.md" ]; then \
				echo "$(GREEN)Using local template$(RESET)"; \
				FOUND_TEMPLATE=true; \
			else \
				echo "$(YELLOW)Trying to clone from GitHub via SSH...$(RESET)"; \
				rm -rf "$$TEMPLATE_DIR"; \
				if git clone "git@github.com:$(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name).git" "$$TEMPLATE_DIR" 2>/dev/null; then \
					echo "$(GREEN)Template cloned from GitHub$(RESET)"; \
					FOUND_TEMPLATE=true; \
				fi; \
			fi; \
			if [ "$$FOUND_TEMPLATE" = "false" ]; then \
				echo "$(RED)❌ Template '$$TEMPLATE_NAME' not found$(RESET)"; \
				echo "$(YELLOW)Check:$(RESET)"; \
				echo "  • Template exists locally in $(TEMP_DIR)/$(TEMPLATE_PREFIX)$(name)"; \
				echo "  • GitHub repo exists: https://github.com/$(GITHUB_USER)/$(TEMPLATE_PREFIX)$(name)"; \
				echo "  • SSH key is configured for GitHub"; \
				$(MAKE) --no-print-directory template-list; \
				true; \
			else \
				mkdir -p $(BACKUP_DIR); \
				if [ -f "$$TEMPLATE_DIR/database.sql" ]; then \
					echo "$(YELLOW)Creating backup...$(RESET)"; \
					ddev export-db --file="$(BACKUP_DIR)/before-template-$$(date +%Y%m%d-%H%M%S).sql.gz" || true; \
					echo "$(YELLOW)Importing database...$(RESET)"; \
					ddev import-db --src="$$TEMPLATE_DIR/database.sql" && \
					ddev wp search-replace '__SITE_URL__' "$(LOCAL_URL)" --all-tables; \
				fi; \
				if [ -d "$$TEMPLATE_DIR/uploads" ]; then \
					echo "$(YELLOW)Copying uploads...$(RESET)"; \
					mkdir -p $(UPLOADS_PATH); \
					rsync -av "$$TEMPLATE_DIR/uploads/" $(UPLOADS_PATH)/; \
				fi; \
				ddev wp cache flush 2>/dev/null || true; \
				rm -rf "$$TEMPLATE_DIR"; \
				echo "$(GREEN)✅ Template '$$TEMPLATE_NAME' loaded successfully$(RESET)"; \
			fi; \
		else \
			echo "$(RED)❌ Template load cancelled$(RESET)"; \
		fi; \
	fi

template-list: ## List available templates
	@echo "$(BLUE)Available Templates$(RESET)"
	@echo "$(BLUE)==================$(RESET)"
	@echo ""
	@echo "$(YELLOW)📁 Local templates:$(RESET)"
	@LOCAL_COUNT=0; \
	for template in $(TEMP_DIR)/$(TEMPLATE_PREFIX)*; do \
		if [ -d "$$template" ] && [ -f "$$template/README.md" ]; then \
			TEMPLATE_NAME=$$(basename "$$template" | sed 's/^$(TEMPLATE_PREFIX)//'); \
			CREATED=$$(grep "Created:" "$$template/README.md" 2>/dev/null | cut -d: -f2- | sed 's/^ *//') || echo "Unknown"; \
			printf "  • %-20s %s\n" "$$TEMPLATE_NAME" "($$CREATED)"; \
			LOCAL_COUNT=$$((LOCAL_COUNT + 1)); \
		fi; \
	done 2>/dev/null; \
	if [ "$$LOCAL_COUNT" -eq 0 ]; then \
		echo "  (none)"; \
	fi
	@echo ""
	@echo "$(YELLOW)🌐 GitHub templates:$(RESET)"
	@if command -v gh >/dev/null 2>&1; then \
		REMOTE_COUNT=0; \
		if REPO_LIST=$$(gh repo list "$(GITHUB_USER)" --limit 100 2>&1); then \
			echo "$$REPO_LIST" | while read repo_info; do \
				REPO_NAME=$$(echo "$$repo_info" | awk '{print $$1}'); \
				if echo "$$REPO_NAME" | grep -q "^$(GITHUB_USER)/$(TEMPLATE_PREFIX)"; then \
					TEMPLATE_NAME=$$(echo "$$REPO_NAME" | sed 's|^$(GITHUB_USER)/$(TEMPLATE_PREFIX)||'); \
					UPDATED=$$(echo "$$repo_info" | awk '{print $$3, $$4, $$5}'); \
					printf "  • %-20s %s\n" "$$TEMPLATE_NAME" "(updated $$UPDATED)"; \
					REMOTE_COUNT=$$((REMOTE_COUNT + 1)); \
				fi; \
			done; \
		else \
			echo "  (unable to fetch - check 'gh auth status')"; \
		fi; \
	else \
		echo "  (install GitHub CLI: brew install gh)"; \
	fi

# === UTILITIES ===

.PHONY: status
status: ## Show complete project status
	@echo "$(BLUE)╔════════════════════════════════════════╗$(RESET)"
	@echo "$(BLUE)║         PROJECT STATUS                 ║$(RESET)"
	@echo "$(BLUE)╚════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(YELLOW)LOCAL:$(RESET)"
	@echo "  Branch: $(shell git branch --show-current 2>/dev/null || echo 'none')"
	@echo "  Changes: $(shell git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files"
	@echo "  Commit: $(shell git log --oneline -1 2>/dev/null | head -c 50 || echo 'No commits')"
	@echo "  DDEV: $(shell if ddev describe >/dev/null 2>&1; then echo 'running'; else echo 'stopped'; fi)"
	@echo ""
	@echo "$(YELLOW)STAGING:$(RESET)"
	@ssh $(STAGING_HOST) "cd $(STAGING_PATH) 2>/dev/null && \
		echo '  Commit:' $$(git log --oneline -1 2>/dev/null | head -c 50 || echo 'Not deployed')" 2>/dev/null || \
		echo "  $(RED)Not accessible$(RESET)"
	@echo ""
	@if [ -n "$(PRODUCTION_HOST)" ] && [ -n "$(PRODUCTION_PATH)" ]; then \
		echo "$(YELLOW)PRODUCTION:$(RESET)"; \
		ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) 2>/dev/null && \
			echo '  Commit:' $$(git log --oneline -1 2>/dev/null | head -c 50 || echo 'Not deployed')" 2>/dev/null || \
			echo "  $(RED)Not accessible$(RESET)"; \
	else \
		echo "$(YELLOW)PRODUCTION:$(RESET)"; \
		echo "  $(RED)Not configured$(RESET)"; \
	fi

.PHONY: backup
backup:
	@echo "$(BLUE)Creating backup...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	if ddev describe >/dev/null 2>&1; then \
		ddev export-db --file=$(BACKUP_DIR)/local-$$TIMESTAMP.sql.gz && \
		echo "$(GREEN)✅ Database: $(BACKUP_DIR)/local-$$TIMESTAMP.sql.gz$(RESET)"; \
	fi; \
	if [ -d "$(UPLOADS_PATH)" ] && [ "$$(ls -A $(UPLOADS_PATH))" ]; then \
		tar -czf $(BACKUP_DIR)/local-$$TIMESTAMP-uploads.tar.gz $(UPLOADS_PATH) && \
		echo "$(GREEN)✅ Files: $(BACKUP_DIR)/local-$$TIMESTAMP-uploads.tar.gz$(RESET)"; \
	fi

.PHONY: logs
logs: ## Show DDEV logs
	@ddev logs -f

.PHONY: restart
restart: ## Restart DDEV
	@ddev restart

.PHONY: stop
stop: ## Stop DDEV
	@ddev stop

.PHONY: ssh
ssh: ## SSH to staging
	@ssh $(STAGING_HOST) -t "cd $(STAGING_PATH); bash"

.PHONY: ssh-prod
ssh-prod: ## SSH to production
	@make _check-production-config
	@ssh $(PRODUCTION_HOST) -t "cd $(PRODUCTION_PATH); bash"

.PHONY: test
test: ## Test configuration and connections
	@echo "$(BLUE)Testing configuration...$(RESET)"
	@echo ""
	@echo "$(YELLOW)Requirements:$(RESET)"
	@command -v ddev >/dev/null 2>&1 && echo "  ✅ DDEV installed" || echo "  ❌ DDEV missing"
	@command -v git >/dev/null 2>&1 && echo "  ✅ Git installed" || echo "  ❌ Git missing"
	@command -v rsync >/dev/null 2>&1 && echo "  ✅ rsync installed" || echo "  ❌ rsync missing"
	@command -v ssh >/dev/null 2>&1 && echo "  ✅ SSH installed" || echo "  ❌ SSH missing"
	@command -v wp >/dev/null 2>&1 && echo "  ✅ WP-CLI installed" || echo "  ⚠️  WP-CLI missing (optional)"
	@command -v gh >/dev/null 2>&1 && echo "  ✅ GitHub CLI installed" || echo "  ⚠️  GitHub CLI missing (optional)"
	@echo ""
	@echo "$(YELLOW)Configuration:$(RESET)"
	@echo "  Project: $(PROJECT_NAME)"
	@echo "  Staging: $(STAGING_HOST):$(STAGING_PATH)"
	@if [ -n "$(PRODUCTION_HOST)" ]; then echo "  Production: $(PRODUCTION_HOST):$(PRODUCTION_PATH)"; else echo "  Production: Not configured"; fi
	@echo ""
	@echo "$(YELLOW)Connections:$(RESET)"
	@if ssh -o ConnectTimeout=2 $(STAGING_HOST) "echo 'OK'" >/dev/null 2>&1; then \
		echo "  ✅ Staging SSH working"; \
	else \
		echo "  ❌ Staging SSH failed"; \
	fi
	@if [ -n "$(PRODUCTION_HOST)" ]; then \
		if ssh -o ConnectTimeout=2 $(PRODUCTION_HOST) "echo 'OK'" >/dev/null 2>&1; then \
			echo "  ✅ Production SSH working"; \
		else \
			echo "  ❌ Production SSH failed"; \
		fi; \
	fi
	@echo ""
	@echo "$(GREEN)✅ Configuration test complete$(RESET)"

.PHONY: rollback
rollback: ## Emergency rollback (staging or production)
	@echo "$(RED)╔════════════════════════════════════════╗$(RESET)"
	@echo "$(RED)║         EMERGENCY ROLLBACK             ║$(RESET)"
	@echo "$(RED)╚════════════════════════════════════════╝$(RESET)"
	@echo "1) Staging"
	@echo "2) Production"
	@read -p "Select environment (1-2): " env; \
	if [ "$$env" = "1" ]; then \
		HOST=$(STAGING_HOST); \
		REMOTE_PATH=$(STAGING_PATH); \
	elif [ "$$env" = "2" ]; then \
		make _check-production-config; \
		HOST=$(PRODUCTION_HOST); \
		REMOTE_PATH=$(PRODUCTION_PATH); \
	else \
		echo "$(RED)Invalid selection$(RESET)"; \
		exit 1; \
	fi; \
	make _confirm message="Rollback to previous commit?"; \
	ssh $$HOST "cd $$REMOTE_PATH && \
		git reset --hard HEAD~1 && \
		composer install --no-dev && \
		wp cache flush --path=$(REMOTE_WP_PATH)" && \
	echo "$(GREEN)✅ Rolled back successfully$(RESET)"

# === OPTIONAL: REMOTE REPO WORKFLOW ===
# Uncomment these if you prefer using GitHub/GitLab instead of bundles

# deploy-remote: ## Deploy via GitHub (alternative to bundle)
# 	@echo "$(BLUE)Deploying via remote repository...$(RESET)"
# 	@make _ensure-clean-git
# 	@git push origin $(shell git branch --show-current)
# 	@ssh $(STAGING_HOST) "cd $(STAGING_PATH) && \
# 		git fetch origin && \
# 		git reset --hard origin/$(shell git branch --show-current) && \
# 		composer install --no-dev && \
# 		wp cache flush --path=$(WP_REMOTE_PATH)"
# 	@echo "$(GREEN)✅ Deployed via remote repo$(RESET)"

# push: ## Push to remote repository
# 	@git push origin $(shell git branch --show-current)
# 	@echo "$(GREEN)✅ Pushed to remote$(RESET)"

# pull: ## Pull from remote repository
# 	@git pull origin $(shell git branch --show-current)
# 	@echo "$(GREEN)✅ Pulled from remote$(RESET)"

# === INTERNAL HELPERS (DO NOT CALL DIRECTLY) ===

_check-requirements:
	@command -v ddev >/dev/null 2>&1 || { echo "$(RED)❌ DDEV not installed$(RESET)"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "$(RED)❌ Git not installed$(RESET)"; exit 1; }
	@command -v rsync >/dev/null 2>&1 || { echo "$(RED)❌ rsync not installed$(RESET)"; exit 1; }
	@command -v ssh >/dev/null 2>&1 || { echo "$(RED)❌ SSH not installed$(RESET)"; exit 1; }

_check-ddev:
	@if ! ddev describe >/dev/null 2>&1; then \
		echo "$(RED)❌ DDEV not running. Run 'make dev' first$(RESET)"; \
		exit 1; \
	fi

_check-staging-config:
	@if [ -z "$(STAGING_HOST)" ] || [ -z "$(STAGING_PATH)" ]; then \
		echo "$(RED)❌ Staging not configured in Makefile$(RESET)"; \
		exit 1; \
	fi

_check-production-config:
	@if [ -z "$(PRODUCTION_HOST)" ] || [ -z "$(PRODUCTION_PATH)" ]; then \
		echo "$(RED)❌ Production not configured in Makefile$(RESET)"; \
		exit 1; \
	fi

_verify-ssh-access:
	@if ! ssh -o ConnectTimeout=5 $(host) "echo 'SSH OK'" >/dev/null 2>&1; then \
		echo "$(RED)❌ Cannot connect to $(host)$(RESET)"; \
		echo "$(YELLOW)Check SSH access and try again$(RESET)"; \
		exit 1; \
	fi

_check-temp-dir:
	@if [ ! -d "$(TEMP_DIR)" ]; then \
		echo "$(RED)❌ Temp directory $(TEMP_DIR) does not exist$(RESET)"; \
		exit 1; \
	fi
	@if [ ! -w "$(TEMP_DIR)" ]; then \
		echo "$(RED)❌ Temp directory $(TEMP_DIR) is not writable$(RESET)"; \
		exit 1; \
	fi

_git-setup:
	@if [ ! -d .git ]; then git init; fi
	@git checkout -b staging 2>/dev/null || git checkout staging 2>/dev/null || true
	@git add -A 2>/dev/null || true
	@git commit -m "Initial setup" 2>/dev/null || true

_ensure-safe-branch:
	@BRANCH=$$(git branch --show-current 2>/dev/null || echo "none"); \
	if [ "$$BRANCH" = "main" ] || [ "$$BRANCH" = "master" ]; then \
		echo "$(YELLOW)Switching to staging branch...$(RESET)"; \
		git checkout staging 2>/dev/null || git checkout -b staging; \
	elif [ "$$BRANCH" = "none" ]; then \
		git checkout -b staging; \
	fi

_ensure-clean-git:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "$(RED)❌ You have uncommitted changes$(RESET)"; \
		echo "$(YELLOW)Run 'make save' first$(RESET)"; \
		exit 1; \
	fi

_confirm:
	@echo "$(YELLOW)$(message)$(RESET)"; \
	read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "$(RED)❌ Cancelled$(RESET)"; \
		exit 1; \
	fi

_safe-db-export:
	@ddev export-db --file=$(file).gz && gunzip $(file).gz
	@if ! grep -q "WordPress database" $(file) 2>/dev/null; then \
		echo "$(RED)❌ Invalid database export$(RESET)"; \
		rm $(file); \
		exit 1; \
	fi

_safe-db-push:
	@sed -i.bak "s|$(LOCAL_URL)|$(url)|g" $(file) && rm $(file).bak
	@scp $(file) $(STAGING_HOST):$(TEMP_DIR)/db-import.sql
	@ssh $(STAGING_HOST) "cd $(STAGING_PATH) && \
		wp db import $(TEMP_DIR)/db-import.sql --path=$(REMOTE_WP_PATH) && \
		rm $(TEMP_DIR)/db-import.sql && \
		wp cache flush --path=$(REMOTE_WP_PATH)"

_safe-files-push:
	@if [ -d "$(UPLOADS_PATH)" ]; then \
		rsync -avz --delete $(UPLOADS_PATH)/ $(STAGING_HOST):$(STAGING_PATH)/content/uploads/ && \
		echo "$(GREEN)✅ Files pushed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  No uploads directory$(RESET)"; \
	fi

_backup-staging:
	@echo "$(YELLOW)Backing up staging...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	ssh $(STAGING_HOST) "cd $(STAGING_PATH) && \
		wp db export --path=$(REMOTE_WP_PATH) - | gzip" > $(BACKUP_DIR)/staging-$$TIMESTAMP.sql.gz && \
	echo "$(GREEN)✅ Staging backed up: $(BACKUP_DIR)/staging-$$TIMESTAMP.sql.gz$(RESET)"

_backup-production:
	@echo "$(YELLOW)Backing up production...$(RESET)"
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	if ! ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) && \
		wp db export --path=$(REMOTE_WP_PATH) - | gzip" > $(BACKUP_DIR)/production-$$TIMESTAMP.sql.gz; then \
		echo "$(RED)❌ Failed to backup production database$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)✅ Production backed up: $(BACKUP_DIR)/production-$$TIMESTAMP.sql.gz$(RESET)"

_init-remote-git:
	@echo "$(YELLOW)Initializing git on $(env)...$(RESET)"
	@ssh $(host) "cd $(path) && \
		if [ ! -d .git ]; then \
			git init && \
			git config user.name 'Deploy' && \
			git config user.email 'deploy@localhost' && \
			git config receive.denyCurrentBranch ignore && \
			echo 'Git initialized'; \
		else \
			echo 'Git already initialized'; \
		fi"

_create-bundle:
	@CURRENT_BRANCH=$$(git branch --show-current); \
	COMMIT=$$(git rev-parse --short HEAD); \
	BUNDLE_NAME="deploy-$$COMMIT-$$$$-$$(date +%s).bundle"; \
	echo "$(YELLOW)Creating temporary deploy branch from staging...$(RESET)"; \
	if ! git show-ref --verify --quiet refs/heads/staging; then \
		echo "$(RED)❌ Staging branch not found$(RESET)"; \
		exit 1; \
	fi; \
	git branch -D deploy-temp 2>/dev/null || true; \
	git checkout -b deploy-temp staging && \
	echo "$(YELLOW)Modifying .gitignore to track all plugins/themes...$(RESET)"; \
	if [ -f .gitignore ]; then \
		sed -i.bak \
			-e "/^$(PLUGINS_PATH)\/\*/d" \
			-e "/^!$(PLUGINS_PATH)\//d" \
			-e "/^$(THEMES_PATH)\/\*/d" \
			-e "/^!$(THEMES_PATH)\//d" \
			.gitignore && \
		rm -f .gitignore.bak; \
	fi && \
	echo "$(YELLOW)Adding all third-party plugins and themes...$(RESET)"; \
	git add -f .gitignore $(PLUGINS_PATH)/ $(THEMES_PATH)/ && \
	if [ -n "$$(git status --porcelain)" ]; then \
		git commit -m "Deploy: Add all plugins and themes for deployment" --no-verify; \
	fi && \
	if [ "$(PROJECT_TYPE)" = "bedrock" ]; then \
		echo "$(YELLOW)Creating bundle from entire project (Bedrock mode): $$COMMIT$(RESET)"; \
		if ! git bundle create $(TEMP_DIR)/$$BUNDLE_NAME deploy-temp; then \
			DEPLOY_COMMIT=$$(git rev-parse HEAD); \
			git checkout "$$CURRENT_BRANCH"; \
			git checkout $$DEPLOY_COMMIT -- $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null || true; \
			git reset HEAD $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null; \
			git branch -D deploy-temp 2>/dev/null || true; \
			echo "$(RED)❌ Failed to create bundle$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)Creating bundle from $(WEB_ROOT)/ directory (Standard WordPress mode): $$COMMIT$(RESET)"; \
		git subtree split --prefix=$(WEB_ROOT) -b deploy-bundle-temp && \
		if ! git bundle create $(TEMP_DIR)/$$BUNDLE_NAME deploy-bundle-temp; then \
			git branch -D deploy-bundle-temp 2>/dev/null || true; \
			DEPLOY_COMMIT=$$(git rev-parse HEAD); \
			git checkout "$$CURRENT_BRANCH"; \
			git checkout $$DEPLOY_COMMIT -- $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null || true; \
			git reset HEAD $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null; \
			git branch -D deploy-temp 2>/dev/null || true; \
			echo "$(RED)❌ Failed to create bundle$(RESET)"; \
			exit 1; \
		fi; \
		git branch -D deploy-bundle-temp; \
	fi && \
	echo "$(YELLOW)Verifying bundle integrity...$(RESET)"; \
	if ! git bundle verify $(TEMP_DIR)/$$BUNDLE_NAME >/dev/null 2>&1; then \
		DEPLOY_COMMIT=$$(git rev-parse HEAD); \
		git checkout "$$CURRENT_BRANCH"; \
		git checkout $$DEPLOY_COMMIT -- $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null || true; \
		git reset HEAD $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null; \
		git branch -D deploy-temp 2>/dev/null || true; \
		echo "$(RED)❌ Bundle verification failed$(RESET)"; \
		rm -f $(TEMP_DIR)/$$BUNDLE_NAME; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Cleaning up: switching back to $$CURRENT_BRANCH and removing deploy-temp branch$(RESET)"; \
	DEPLOY_COMMIT=$$(git rev-parse HEAD) && \
	git checkout "$$CURRENT_BRANCH" && \
	git checkout $$DEPLOY_COMMIT -- $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null || true && \
	git reset HEAD $(PLUGINS_PATH)/ $(THEMES_PATH)/ 2>/dev/null && \
	git branch -D deploy-temp && \
	echo "$(GREEN)✅ Bundle created successfully$(RESET)"; \
	echo "$$BUNDLE_NAME" > $(TEMP_DIR)/.bundle-name

_deploy-bundle:
	@BUNDLE_NAME=$$(cat $(TEMP_DIR)/.bundle-name); \
	echo "$(YELLOW)Transferring bundle to $(env)...$(RESET)"; \
	if ! scp $(TEMP_DIR)/$$BUNDLE_NAME $(host):$(path)/; then \
		echo "$(RED)❌ Failed to transfer bundle$(RESET)"; \
		rm -f $(TEMP_DIR)/$$BUNDLE_NAME $(TEMP_DIR)/.bundle-name; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Deploying on $(env) server...$(RESET)"; \
	if ssh $(host) "cd $(path) && \
		git bundle verify $$BUNDLE_NAME && \
		git tag backup-before-deploy-\$$(date +%Y%m%d-%H%M%S) 2>/dev/null || true && \
		BUNDLE_REF=\$$(git bundle list-heads $$BUNDLE_NAME | awk '{print \$$1}') && \
		git bundle unbundle $$BUNDLE_NAME && \
		git --work-tree=. --git-dir=.git checkout -f \$$BUNDLE_REF && \
		if [ -f composer.json ]; then \
			composer install --no-dev --optimize-autoloader; \
		fi && \
		if [ -d $(REMOTE_WP_PATH)/wp-content ]; then \
			echo 'Removing default wp-content...' && \
			rm -rf $(REMOTE_WP_PATH)/wp-content; \
		fi && \
		if [ -d $(REMOTE_WP_PATH) ]; then \
			wp cache flush --path=$(REMOTE_WP_PATH) 2>/dev/null || true; \
		fi && \
		rm -f $$BUNDLE_NAME"; then \
		echo "$(GREEN)✅ Deployed to $(env)$(RESET)"; \
		rm -f $(TEMP_DIR)/$$BUNDLE_NAME $(TEMP_DIR)/.bundle-name; \
	else \
		echo "$(RED)❌ Deployment failed$(RESET)"; \
		rm -f $(TEMP_DIR)/.bundle-name; \
		exit 1; \
	fi

# Quick aliases for common workflows
.PHONY: s d p
s: save ## Alias for save
d: deploy ## Alias for deploy
p: sync-to-local ## Alias for pull (sync-to-local)