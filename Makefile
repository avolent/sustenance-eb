run_plan: init plan

run_apply: init zip apply

run_destroy_plan: init destroy_plan

run_destroy_apply: init destroy_apply

# Local Commands
local: requirements
	pipenv shell

requirements:
	pipenv install
	pipenv run pip freeze > app/requirements.txt

version:
	aws --version
	terraform --version

run_app:
	cd app/; flask --app application run

deploy_app: zip
	aws s3 cp app.zip s3://sustenance-app/beanstalk/app-$(shell git rev-parse --short HEAD).zip
	aws --region ap-southeast-2 elasticbeanstalk create-application-version --application-name sustenance --version-label $(shell git rev-parse --short HEAD) --source-bundle S3Bucket=sustenance-app,S3Key=beanstalk/app-$(shell git rev-parse --short HEAD).zip
	aws --region ap-southeast-2 elasticbeanstalk update-environment --environment-name sustenance-env --version-label $(shell git rev-parse --short HEAD)
zip:
	cd application/; zip -r ../app.zip application.py Procfile requirements.txt

# Terraform Commands
init:
	cd infrastructure/; terraform init -input=false; terraform validate; terraform fmt

plan:
	cd infrastructure/; terraform plan -out=tfplan -input=false

apply:
	cd infrastructure/; terraform apply "tfplan"

destroy_plan:
	cd infrastructure/; terraform plan -destroy

destroy_apply:
	cd infrastructure/; terraform destroy -auto-approve