cd infra; terraform destroy -auto-approve; rm -f authorizer.zip service_1.zip service_2.zip; cd ..

cd go-service; rm -f bootstrap; cd ..
