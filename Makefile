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
	docker-compose -f tests/docker-compose.yml run $(IMAGE_NAME) ash -li

test:
	@./tests/mysql-import-from-bucket.sh
