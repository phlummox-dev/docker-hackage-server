
.PHONY: build serve run

IMAGE_NAME=hackage-server

IMAGE_VERSION=0.1.0

print-image-name:
	@echo $(IMAGE_NAME)

print-image-version:
	@echo $(IMAGE_VERSION)

build:
	docker build -f Dockerfile --target build \
			-t $(IMAGE_NAME):$(IMAGE_VERSION)-builder .
	docker build -f Dockerfile \
			-t $(IMAGE_NAME):$(IMAGE_VERSION) .

serve:
	docker -D run --rm -it --net=host $(IMAGE_NAME):$(IMAGE_VERSION) \
			hackage-server run  --static-dir=datafiles --base-uri=http://localhost:8080/

run:
	docker -D run --rm -it --net=host  \
		$(IMAGE_NAME):$(IMAGE_VERSION)

