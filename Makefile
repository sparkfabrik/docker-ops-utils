IMAGE_NAME := ops-utils
IMAGE_TAG := loc

all: build

build:
	docker build . --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG)

cli: build
	@touch .env
	docker run --rm -it \
		--env-file .env \
		$(IMAGE_NAME):$(IMAGE_TAG) ash -li

cli-dev: build
	@touch .env
	docker run --rm -it \
		--env-file .env \
		-v ${PWD}/app:/app \
		-w /app \
		$(IMAGE_NAME):$(IMAGE_TAG) ash -li

cli-test:
	docker-compose -f tests/docker-compose.yml run \
		-v ${PWD}/app:/app \
		-w /app \
		$(IMAGE_NAME) ash -li

test:
	@echo "\e[33mTESTS for: mysql-import-from-bucket\e[39m"
	@./tests/mysql-import-from-bucket.sh
	@echo "\e[33mTESTS for: mysql-export-to-bucket\e[39m"
	@./tests/mysql-export-to-bucket.sh
	@echo "\e[33mTESTS for: mysql-drop-db-tables\e[39m"
	@./tests/mysql-drop-db-tables.sh
	@echo "\e[33mTESTS for: bucket-copy-bucket\e[39m"
	@./tests/bucket-copy-bucket.sh
	@echo "\e[33mTESTS for: mysql-export-all-to-bucket\e[39m"
	@./tests/mysql-export-all-to-bucket.sh

mysql-test-up:
	@echo "\e[33mThis make target will reboot the test mysql service.\e[39m"
	@echo "\e[33mRemember that this service will be destroyed and recreated each time.\e[39m"
	@echo "\e[33mRemember also that this service will be destroyed if you run the tests.\e[39m"
	docker-compose -f tests/docker-compose.yml rm -fsv mysql
	docker-compose -f tests/docker-compose.yml up -d mysql

mysql-test-seeded: mysql-test-up
	docker-compose -f tests/docker-compose.yml run --rm \
		--entrypoint ash \
		-v ${PWD}/tests/minio/seeds:/seeds \
		ops-utils -lic 'wait-for-it $${DB_HOST}:$${DB_PORT:-3306} -t 30 && if [ $$? -eq 0 ]; then mysql -h$${DB_HOST} -P$${DB_PORT:-3306} -u$${DB_USER} --password="$${DB_PASSWORD}" $${DB_NAME} < /seeds/dump.sql; echo -e "\e[32mOK: database succesfully seeded\e[39m"; else echo -e "\e[31mERROR: the DB server fails to start\e[39m"; exit 1; fi'
