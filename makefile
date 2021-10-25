define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

purge: clean ## ⚠️  Removes All Developer Data for a fresh server start
	rm -r ./dev/data/recipes/
	rm -r ./dev/data/users/
	rm -f ./dev/data/mealie*.db
	rm -f ./dev/data/mealie.log
	rm -f ./dev/data/.secret

clean: clean-pyc clean-test ## 🧹 Remove all build, test, coverage and Python artifacts

clean-pyc: ## 🧹 Remove Python file artifacts
	find ./mealie -name '*.pyc' -exec rm -f {} +
	find ./mealie  -name '*.pyo' -exec rm -f {} +
	find ./mealie  -name '*~' -exec rm -f {} +
	find ./mealie  -name '__pycache__' -exec rm -fr {} +

clean-test: ## 🧹 Remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

test-all: lint-test test ## 🧪 Check Lint Format and Testing

test: ## 🧪 Run tests quickly with the default Python
	poetry run pytest

lint-test:
	poetry run black . --check
	poetry run isort . --check-only
	poetry run flake8 mealie tests

lint: ## 🧺 Format, Check and Flake8 
	poetry run isort .
	poetry run black .
	poetry run flake8 mealie tests


lint-frontend: ## 🧺 Run yarn lint
	cd frontend && yarn lint

coverage: ## ☂️  Check code coverage quickly with the default Python
	poetry run pytest
	poetry run coverage report -m
	poetry run coverage html
	$(BROWSER) htmlcov/index.html

setup: ## 🏗  Setup Development Instance
	cp template.env .env -n 
	poetry install && \
	cd frontend && \
	cp template.env .env -n 
	yarn install && \
	cd ..

backend: ## 🎬 Start Mealie Backend Development Server
	poetry run python mealie/db/init_db.py && \
	poetry run python mealie/services/image/minify.py && \
	poetry run python mealie/app.py


.PHONY: frontend
frontend: ## 🎬 Start Mealie Frontend Development Server
	cd frontend && yarn run dev

frontend-build: ## 🏗  Build Frontend in frontend/dist
	cd frontend && yarn run build

.PHONY: docs
docs: ## 📄 Start Mkdocs Development Server
	poetry run python dev/scripts/api_docs_gen.py && \
	cd docs && poetry run python -m mkdocs serve

docker-dev: ## 🐳 Build and Start Docker Development Stack
	docker-compose -f docker-compose.dev.yml -p dev-mealie down && \
	docker-compose -f docker-compose.dev.yml -p dev-mealie up --build

docker-prod: ## 🐳 Build and Start Docker Production Stack
	docker-compose -f docker-compose.yml -p mealie up --build

code-gen: ## 🤖 Run Code-Gen Scripts
	poetry run python dev/scripts/app_routes_gen.py

