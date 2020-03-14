ifndef SCM_USERNAME
  $(error SCM_USERNAME must be set)
endif

ifndef SCM_TOKEN
  $(error SCM_TOKEN must be set)
endif

.PHONY: build
build:
	./hack/build.sh
