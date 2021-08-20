IMAGE_NAME := ops-utils
IMAGE_TAG := loc

all: build

build:
	docker build . --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG)

cli: build
	docker run --rm -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION --entrypoint ash $(IMAGE_NAME):$(IMAGE_TAG)

print-run:
	@echo "docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION $(IMAGE_NAME):$(IMAGE_TAG) <COMMAND> [SUBCOMMAND] [OPTIONS]"
