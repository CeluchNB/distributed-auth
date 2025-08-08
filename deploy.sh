
cd go-service; ./build.sh; cd ..

cd infra; terraform test; terraform plan; terraform apply -auto-approve

api_gateway_url=$(terraform output api_gateway_url)
auth0_client_id=$(terraform output auth0_client_id)

cd ..; cd client

sed -i '' "s/VITE_AUTH0_CLIENT_ID=.*/VITE_AUTH0_CLIENT_ID=$auth0_client_id/" .env
sed -i '' "s|VITE_AUDIENCE=.*|VITE_AUDIENCE=$api_gateway_url|" .env

yarn dev &

sleep 5
open -a firefox -g http://localhost:5173/login