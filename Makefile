BASE_NAME=aha
DEPLOYMENT_BUCKET_NAME := fsd-artifacts
DEPLOYMENT_KEY := $(shell echo $(BASE_NAME)-$$RANDOM.zip)
STACK_NAME := $(BASE_NAME)-lambda-layer

clean: 
	rm -rf build

build/bin/aha: 
	mkdir -p build/bin
	rm -rf build/aha*
	cd build; \
	        curl -sL https://github.com/theZiz/aha/archive/0.5.tar.gz | tar xz
	cd build/aha*; \
	        make 2>/dev/null
	mv build/aha*/aha build/bin 

build/layer.zip: build/bin/aha
	cd build && zip -r layer.zip bin

build/output.yaml: build/layer.zip cloudformation/template.yaml
	aws s3 cp build/layer.zip s3://$(DEPLOYMENT_BUCKET_NAME)/$(DEPLOYMENT_KEY)
	sed "s:DEPLOYMENT_BUCKET_NAME:$(DEPLOYMENT_BUCKET_NAME):;s:DEPLOYMENT_KEY:$(DEPLOYMENT_KEY):" cloudformation/template.yaml > build/output.yaml

deploy: build/output.yaml
	aws cloudformation deploy --template-file build/output.yaml --stack-name $(STACK_NAME)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs[].OutputValue --output text
