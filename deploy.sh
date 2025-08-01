
cd go-service; ./build.sh; cd ..

cd infra; terraform plan; terraform apply -auto-approve
