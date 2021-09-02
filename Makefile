AWS_ACCOUNT=123456789012
AWS_REGION=us-east-1
VERSION=1.0.1

.PHONY: all clean build push run

run:
	docker-compose up

clean:
	docker-compose down --rmi local

build:
	docker build -t aws-lambda-custom-docker-image .
	docker tag aws-lambda-custom-docker-image:latest ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/aws-lambda-custom-docker-image:${VERSION}

push:
	docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/aws-lambda-custom-docker-image:${VERSION}
