MAKE := $(shell which make)

LOCAL_PORT := 9003

ifdef TEMPLATE
	TEMPLATE_PARAM := -t=$(TEMPLATE)
else
	TEMPLATE_PARAM := ""
endif


check-doc-project:
ifndef DOC_PROJECT
	$(error missing DOC_PROJECT)
endif

check-googleapis:
ifndef PROTO_GOOGLEAPIS
	@echo "Clone the repository from https://github.com/googleapis/googleapis"
	@echo "Set PROTO_GOOGLEAPIS to point to this repository"
	@exit 1
endif


install:
	go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest

doc: check-googleapis
	./docgen.sh -p=$(TARGET) $(TEMPLATE_PARAM) $(EXCLUDES)

run:
	export PORT=$(LOCAL_PORT) && \
	go run server.go

deploy: check-doc-project doc
	gcloud app deploy \
		--project=$(DOC_PROJECT)
