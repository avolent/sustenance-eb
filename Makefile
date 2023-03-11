run_plan: init plan

run_apply: init zip apply

run_destroy_plan: init destroy_plan

run_destroy_apply: init destroy_apply

# Local Commands
local: requirements
	pipenv shell

requirements:
	pipenv install
	pipenv run pip freeze > application/requirements.txt

version:
	aws --version
	terraform --version

run_app:
	cd application/; flask --app application:app run --debug

deploy_app: zip
	aws --version
	echo "Uploading artifact"
	aws s3 cp app.zip s3://sustenance-app/beanstalk/app-$(shell git rev-parse --short HEAD).zip
	echo "Creating/Deploying new version"
	aws elasticbeanstalk create-application-version --application-name sustenance --version-label $(shell git rev-parse --short HEAD) --description "$(shell git log -1 --pretty=%B)" --source-bundle S3Bucket=sustenance-app,S3Key=beanstalk/app-$(shell git rev-parse --short HEAD).zip
	aws elasticbeanstalk update-environment --environment-name sustenance-env --version-label $(shell git rev-parse --short HEAD)

zip:
	rm -f app.zip; cd application; zip -r ../app.zip ./*

# Terraform Commands
init:
	cd infrastructure/; terraform init -input=false; terraform validate; terraform fmt

plan:
	cd infrastructure/; terraform plan -var="commit_id=$(shell git rev-parse --short HEAD)" -var="commit_id=$(shell git log -1 --pretty=%B)" -var="aws_region=$(AWS_REGION)" -out=tfplan -input=false

apply:
	cd infrastructure/; terraform apply "tfplan"

destroy_plan:
	cd infrastructure/; terraform plan -destroy

destroy_apply:
	cd infrastructure/; terraform destroy -auto-approve