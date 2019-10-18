.PHONY: setup build deploy clean upload terraform_apply psql_as_admin psql_db_user1

azure.tfvars:
	@echo 'owner="YOUR_NAME"' > azure.tfvars
	@echo 'location="AZURE_LOCATION"' >> azure.tfvars
	@echo 'admin_login="PSQL_ADMIN_LOGIN"' >> azure.tfvars
	@echo 'admin_password="PSQL_ADMIN_PASS"' >> azure.tfvars
	@echo 'dbuser_login="PSQL_USER_LOGIN"' >> azure.tfvars
	@echo 'dbuser_password="PSQL_USER_PASS"' >> azure.tfvars
	@echo 'dbserver_name="DBSERVER_NAME"' >> azure.tfvars
	@echo 'db_name="DB_NAME"' >> azure.tfvars

setup: azure.tfvars

build:
	@test -f azure.tfvars || (echo 'run `make setup` and update values in azure.tfvars' && exit -1)
	@terraform init
	@terraform plan -var-file azure.tfvars -out out.plan

deploy: 
	@test -f azure.tfvars || (echo 'run `make setup` and update values in azure.tfvars' && exit -1)
	@terraform apply "out.plan"

clean:
	@test -f azure.tfvars || (echo 'run `make setup` and update values in azure.tfvars' && exit -1)
	terraform destroy -var-file azure.tfvars

psql_as_admin:
	$(shell terraform output psql_admin)

psql_db_sql_user:
	@echo "replace __PSQL_USER_PASS__ with the correct value"
	@echo "replace __DB_SERVER_NAME__ with the correct value"
	@echo "replace __USER_PASS__ with the correct value"
	@echo "replace __DB_NAME__ with the correct value"
	@echo "and then remove this and the exit below."
	exit 1
	PGPASSWORD='__PSQL_USER_PASS__' psql -h __DB_SERVER_NAME__.postgres.database.azure.com -U __USER_PASS__@__DB_SERVER_NAME __DB_NAME__

psql_db_tf_user:
	$(shell terraform output psql_user)

