ifeq ($(shell test -e '.env' && echo -n yes),yes)
	include .env
endif

# Manually define main variables

ifndef APP_PORT
override APP_PORT = 8000
endif

ifndef APP_HOST
override APP_HOST = 127.0.0.1
endif

args := $(wordlist 2, 100, $(MAKECMDGOALS))
ifndef args
MESSAGE = "No such command (or you pass two or many targets to ). List of possible commands: make help"
else
MESSAGE = "Done"
endif

APPLICATION_NAME = delivery_hub
TEST = poetry run python3 -m pytest --verbosity=2 --showlocals --log-level=DEBUG
CODE = $(APPLICATION_NAME) tests

HELP_FUN = \
	%help; while(<>){push@{$$help{$$2//'options'}},[$$1,$$3] \
	if/^([\w-_]+)\s*:.*\#\#(?:@(\w+))?\s(.*)$$/}; \
    print"$$_:\n", map"  $$_->[0]".(" "x(20-length($$_->[0])))."$$_->[1]\n",\
    @{$$help{$$_}},"\n" for keys %help; \

# Commands

help: ##@Help Show this help
	@echo -e "Usage: make [target] ...\n"
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

install:  ##@Setup Install project requirements
	python3 -m pip install poetry
	poetry install

env:  ##@Environment Create .env file with variables
	@$(eval SHELL:=/bin/bash)
	@cp .env.sample .env
	@echo "REDIS_PASSWORD=$$(openssl rand -hex 32)" >> .env

db:  ##@Database Create database with docker-compose
	docker-compose -f docker-compose.yaml up -d --remove-orphans


run:  ##@Application Run application
	poetry run python3 -m $(APPLICATION_NAME)

lint:  ##@Code Check code with pylint
	poetry run python3 -m pflake8 $(CODE)
	poetry run python3 -m mypy $(CODE)

format:  ##@Code Reformat code with isort and black
	poetry run python3 -m isort $(CODE)
	poetry run python3 -m black $(CODE)

clean-pyc:  ##@Clean .pyc files
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:  ##@Clean coverage reports
	rm -f .coverage
	rm -f .coverage.*

clean-mypy:  ##@Clean mypy cache
	rm -r .mypy_cache

clean:  ##@Clean Clean all temp, report or cache files
	make clean-pyc && make clean-test && make clean-mypy
