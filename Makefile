# WordPress Bedrock Development Makefile
# Simple, powerful workflow for small teams

# Configuration - Update these values
PROJECT_NAME := your-project
STAGING_HOST := ploi-staging
STAGING_PATH := /home/ploi/$(PROJECT_NAME).be
PRODUCTION_HOST := ploi-production
PRODUCTION_PATH := /home/ploi/$(PROJECT_NAME).com
TEMPLATE_GITHUB := your-github-username

# Colors
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

.PHONY: help setup start work save deploy release

help: ## Show available commands
	@echo "$(BLUE)WordPress Bedrock Commands$(RESET)"
	@echo "Current: $(git branch --show-current 2>/dev/null || echo 'no git') | DDEV: $(ddev describe -j 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo 'stopped')"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-15s$(RESET) %s\n", $1, $2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Typical workflow:$(RESET) work → save → deploy → release"

# === SETUP ===
setup: ## Initial project setup
	@echo "$(BLUE)Setting up project...$(RESET)"
	@if [ ! -f .env ]; then cp .env.example .env; echo "$(YELLOW)Created .env - configure it$(RESET)"; fi
	@composer install
	@ddev config --project-type=wordpress --project-name=$(PROJECT_NAME)
	@ddev start && ddev composer install
	@git checkout staging 2>/dev/null || git checkout -b staging
	@mkdir -p backups
	@echo "$(GREEN)Setup complete! Configure .env and Makefile variables$(RESET)"

start: ## Start development environment
	@ddev start
	@echo "$(GREEN)Development server started$(RESET)"
	@ddev describe

# === DAILY WORKFLOW ===
work: ## Start working (pull staging branch)
	@echo "$(BLUE)Starting work session...$(RESET)"
	@ddev start 2>/dev/null || true
	@git checkout staging && git pull origin staging 2>/dev/null || true
	@echo "$(GREEN)Ready to work on staging branch$(RESET)"

save: ## Commit current work
	@git add .
	@read -p "Commit message: " msg && git commit -m "$$msg"
	@echo "$(GREEN)Work saved$(RESET)"

deploy: ## Deploy to staging server
	@BRANCH=$(git branch --show-current); \
	echo "$(BLUE)Deploying $BRANCH...$(RESET)"; \
	git push origin $BRANCH; \
	if ssh $(STAGING_HOST) "cd $(STAGING_PATH) && git fetch && git checkout $BRANCH && git pull origin $BRANCH && composer install --no-dev && wp cache flush --path=web/wp"; then \
		echo "$(GREEN)✓ Deployed successfully$(RESET)"; \
		make verify; \
	else \
		echo "$(RED)✗ Deploy failed$(RESET)"; exit 1; \
	fi

release: ## Release staging to main (production)
	@echo "$(RED)Release staging to main?$(RESET)"; \
	read -p "Continue? (y/N): " confirm; \
	if [ "$confirm" = "y" ]; then \
		git checkout main && git pull origin main 2>/dev/null || true; \
		git merge staging && git push origin main; \
		git checkout staging; \
		echo "$(GREEN)✓ Released to main$(RESET)"; \
	fi

production: ## Deploy main branch to production server
	@echo "$(RED)DEPLOY TO PRODUCTION?$(RESET)"; \
	echo "$(YELLOW)This will deploy main branch to live site$(RESET)"; \
	read -p "Are you absolutely sure? (y/N): " confirm; \
	if [ "$confirm" = "y" ]; then \
		git checkout main && git pull origin main; \
		if ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) && git fetch && git checkout main && git pull origin main && composer install --no-dev --optimize-autoloader && wp cache flush --path=web/wp"; then \
			echo "$(GREEN)✓ PRODUCTION DEPLOYED$(RESET)"; \
			REMOTE=$(ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) && git rev-parse HEAD"); \
			echo "$(GREEN)Production commit: $REMOTE$(RESET)"; \
		else \
			echo "$(RED)✗ PRODUCTION DEPLOY FAILED$(RESET)"; exit 1; \
		fi; \
		git checkout staging; \
	else \
		echo "$(YELLOW)Production deploy cancelled$(RESET)"; \
	fi

# === FEATURE BRANCHES (when needed) ===
feature: ## Create feature branch (make feature name=my-feature)
	@if [ -z "$(name)" ]; then echo "$(RED)Usage: make feature name=my-feature$(RESET)"; exit 1; fi
	@git checkout staging && git pull origin staging
	@git checkout -b feature/$(name)
	@echo "$(GREEN)Created feature/$(name)$(RESET)"

finish: ## Merge current feature to staging
	@BRANCH=$$(git branch --show-current); \
	if [[ $$BRANCH != feature/* ]]; then echo "$(RED)Not on feature branch$(RESET)"; exit 1; fi; \
	git checkout staging && git pull origin staging && git merge $$BRANCH && git push origin staging; \
	git branch -d $$BRANCH; \
	echo "$(GREEN)✓ Feature merged to staging$(RESET)"

switch: ## Switch branch (make switch name=branch-name)
	@if [ -z "$(name)" ]; then git branch -a; echo "$(RED)Usage: make switch name=branch$(RESET)"; exit 1; fi
	@git checkout $(name)

# === SYNC ===
sync-down: ## Download files and database from staging
	@echo "$(BLUE)Syncing from staging server...$(RESET)"
	@rsync -avz --exclude='.git' --exclude='.ddev' --exclude='vendor' --exclude='node_modules' $(STAGING_HOST):$(STAGING_PATH)/web/app/uploads/ web/app/uploads/
	@ssh $(STAGING_HOST) "cd $(STAGING_PATH) && wp db export --path=web/wp temp.sql"
	@scp $(STAGING_HOST):$(STAGING_PATH)/temp.sql ./temp.sql
	@ssh $(STAGING_HOST) "rm $(STAGING_PATH)/temp.sql"
	@ddev import-db --src=temp.sql && rm temp.sql
	@ddev wp search-replace "https://your-staging-domain.com" "https://$(PROJECT_NAME).ddev.site"
	@echo "$(GREEN)✓ Sync complete$(RESET)"

sync-up: ## Upload files to staging (careful!)
	@echo "$(RED)Upload files to staging server?$(RESET)"; \
	read -p "Continue? (y/N): " confirm; \
	if [ "$confirm" = "y" ]; then \
		rsync -avz --exclude='.git' --exclude='.ddev' --exclude='vendor' --exclude='node_modules' web/app/uploads/ $(STAGING_HOST):$(STAGING_PATH)/web/app/uploads/; \
		echo "$(GREEN)✓ Files uploaded$(RESET)"; \
	fi

# === UTILITIES ===
verify: ## Verify deployment worked
	@EXPECTED=$(git rev-parse HEAD); \
	REMOTE=$(ssh $(STAGING_HOST) "cd $(STAGING_PATH) && git rev-parse HEAD"); \
	if [ "$EXPECTED" = "$REMOTE" ]; then \
		echo "$(GREEN)✓ Deployment verified$(RESET)"; \
	else \
		echo "$(RED)✗ Deployment not synced$(RESET)"; \
	fi

status: ## Show git and environment status
	@echo "$(BLUE)Branch:$(RESET) $(git branch --show-current)"
	@echo "$(BLUE)Status:$(RESET) $(git status --porcelain | wc -l | tr -d ' ') changes"
	@ddev describe 2>/dev/null || echo "$(YELLOW)DDEV not running$(RESET)"

ssh: ## SSH to staging server
	@ssh $(STAGING_HOST)

ssh-production: ## SSH to production server
	@ssh $(PRODUCTION_HOST)

clear-cache: ## Clear all caches on production
	@echo "$(BLUE)Clearing production caches...$(RESET)"
	@ssh $(PRODUCTION_HOST) "cd $(PRODUCTION_PATH) && wp cache flush --path=web/wp && wp redis flush --path=web/wp && sudo nginx -s reload"
	@echo "$(GREEN)✓ All caches cleared$(RESET)"

# === UPDATES ===
update: ## Update WordPress core and all plugins
	@echo "$(BLUE)Updating WordPress and plugins...$(RESET)"
	@composer update
	@echo "$(GREEN)✓ WordPress and plugins updated$(RESET)"
	@echo "$(YELLOW)Run 'make save' and 'make deploy' to deploy updates$(RESET)"

update-core: ## Update only WordPress core
	@echo "$(BLUE)Updating WordPress core...$(RESET)"
	@composer update roots/wordpress
	@echo "$(GREEN)✓ WordPress core updated$(RESET)"

update-plugins: ## Update only plugins
	@echo "$(BLUE)Updating plugins...$(RESET)"
	@composer update wpackagist-plugin/*
	@echo "$(GREEN)✓ Plugins updated$(RESET)"

show-updates: ## Show available updates
	@echo "$(BLUE)Checking for updates...$(RESET)"
	@composer outdated
	@echo ""
	@echo "$(YELLOW)Use 'make update' to update all or 'make update-core' / 'make update-plugins'$(RESET)"

logs: ## Show ddev logs
	@ddev logs -f

clean: ## Clean up environment
	@ddev clean && composer dump-autoload
	@echo "$(GREEN)✓ Cleaned up$(RESET)"

stop: ## Stop development environment
	@ddev stop
