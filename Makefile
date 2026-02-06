## PARAM test: True False
## PARAM test TYPE=bool DEFAULT=False

## PARAM env: dev stage prod
## PARAM env TYPE=enum REQUIRED

## TARGET run
## PARAM app: api worker
## PARAM app TYPE=enum REQUIRED

## CMD when test=True: app.deploy app.cleanup

run:
	@echo run

build:
	@echo build

help:
	@awk '/^## /{print}' Makefile
