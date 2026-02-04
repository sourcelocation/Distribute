# --- CONFIGURATION ---
SERVER   := $(DISTRIBUTE_SERVER)
REGISTRY := $(DISTRIBUTE_REGISTRY)
REMOTE_DIR := $(DISTRIBUTE_REMOTE_DIR)
ARCH := $(DISTRIBUTE_ARCH)

BUILD_CMD := docker buildx build --platform linux/$(ARCH) --target runner --push

.PHONY: all deploy update debug logs build-distributor

all: deploy

# -----------------
# BUILD
# -----------------

build-distributor:
	@echo "Building distributor..."
	$(BUILD_CMD) -f api/Dockerfile -t $(REGISTRY)/distributor:latest .

# -----------------
# DEPLOYMENT
# -----------------

deploy: build-distributor update

update:
	@echo "Updating remote stack..."
	ssh $(SERVER) "cd $(REMOTE_DIR) && docker compose pull && docker compose up -d --remove-orphans"

logs:
	ssh $(SERVER) "cd $(REMOTE_DIR) && docker compose logs -f --tail=100"

# -----------------
# DEVELOPMENT
# -----------------

debug:
	cd api && docker compose up --build
