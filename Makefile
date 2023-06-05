DOCKER_COMPOSE_FILE =./docker-compose.yaml
POSTGRES_URL =postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable

network:
	docker network create bank-network

up:
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d

down:
	docker compose -f $(DOCKER_COMPOSE_FILE) down

postgres:
	docker run --name postgres --network bank-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:14-alpine

createdb:
	docker exec -it simplebank-postgres-1 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it simplebank-postgres-1 dropdb simple_bank

# ================================================== #

migrateup1:
	migrate -path db/migration -database $(POSTGRES_URL) -verbose up 1

migrateup:
	migrate -path db/migration -database $(POSTGRES_URL) -verbose up

migratedown:
	migrate -path db/migration -database $(POSTGRES_URL) -verbose down

migratedown1:
	migrate -path db/migration -database $(POSTGRES_URL) -verbose down 1

db_docs:
	dbdocs build doc/db.dbml

db_schema:
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml

# ================================================== #

sqlc:
	sqlc generate
	
mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/techschool/simplebank/db/sqlc Store

proto:
	rm -f pb/*.go
	rm -f doc/swagger/*.swagger.json
	protoc --proto_path=proto --go_out=pb --go_opt=paths=source_relative \
	--go-grpc_out=pb --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=pb --grpc-gateway_opt=paths=source_relative \
	--openapiv2_out=doc/swagger --openapiv2_opt=allow_merge=true,merge_file_name=simple_bank \
   	proto/*.proto
	statik -src=./doc/swagger -dest=./doc

# ================================================== #

psql:
	docker exec -it simplebank-postgres-1 psql -U root -d  simple_bank

server:
	go run main.go

evans:
	evans --host localhost  --port 9090 -r repl

test:
	go test -v -cover ./...

# ================================================== #

dockerdeleteall:
	docker system prune -a

dockerdelete:
	docker system prune

dockershow:
	docker images -a && docker ps -a 

# ================================================== #

tagandpush:
	docker tag postgres:14-alpine registry.localhost:5000/postgres:14-alpine
	docker push registry.localhost:5000/postgres:14-alpine
	docker tag simplebank-api:14-alpine registry.localhost:5000/simplebank-api:14-alpine
	docker push registry.localhost:5000/simplebank-api:14-alpine

deployments:

	kubectl apply -f ./manifests/deployment.yaml; \
	kubectl apply -f ./manifests/database-service.yaml; \
	kubectl apply -f ./manifests/api-service.yaml; \
	kubectl apply -f ./manifests/ingress-object.yaml; \
	kubectl apply -f ./manifests/ingress-service.yaml; \
	kubectl apply -f ./manifests/prometheus-object.yaml; \

reset:
	k3d cluster delete simplebank
	make down
	make prom-down
	make dockerdeleteall
	make dockershow

cluster:
	make up
	k3d cluster create simplebank -p "8082:30080@agent:0" --agents 2 --config ./manifests/k3d-config.yaml
	make tagandpush
	kubectl create -f ./manifests/bundle.yaml
	make deployments
	sleep 5
	helm install my-prometheus prometheus-community/prometheus --version 22.6.2
	helm upgrade --install my-prometheus prometheus-community/prometheus --version 22.6.2 -f prometheus-helmchart/prometheus/values.yaml
	cd prom-docker-compose/prometheus
	docker compose up -d
	cd ../..

prom-up:
	cd prom-docker-compose/prometheus; \
	docker compose up -d; \
	cd ../..;

prom-down:
	cd prom-docker-compose/prometheus; \
	docker compose down;\
	cd ../..;

hosts:
	sudo nano /private/etc/hosts

.PHONY: network postgres createdb dropdb migrateup migratedown migrateup1 migratedown1 db_docs db_schema sqlc test server mock up down dockerdelete dockerdeleteall dockershow deployments tagandpush cluster reset proto evans

# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm pull --untar prometheus-community/prometheus --version 22.6.2
# helm install my-prometheus prometheus-community/prometheus --version 22.6.2
# helm upgrade --install my-prometheus prometheus-community/prometheus --version 22.6.2 -f prometheus-helmchart/prometheus/values.yaml
# kubectl port-forward svc/my-prometheus-server  9090:80 
# http://localhost:9090/

# Deployment
# ================================================== #

# Build containers

# k3d managed registry
# k3d cluster create simplebank -p "8080:80@loadbalancer" --agents 2 --registry-create registry.localhost
# k3d cluster create simplebank -p "8080:80@loadbalancer" --agents 2
# k3d cluster create simplebank --config ./manifests/k3d-config.yaml

# kubectl cluster-info
# k3d cluster list
# k3d node list
# kubectl get nodes -o wide
# docker exec k3d-simplebank-server-0 sh -c 'ctr version'
# k3d kubeconfig get k3s-default

# # Start registry container (only if not defined in the k3d-config)
# -> docker container run -d --name registry.localhost --restart always -p 5000:5000 registry:2

# Attach container to k3d cluster network (only if non k3d-managed registry)
# docker network connect k3d-simplebank registry.localhost

# Tag / Push local image with local registry
# docker tag postgres:12-alpine registry.localhost:5000/postgres:12-alpine
# docker push registry.localhost:5000/postgres:12-alpine
# docker tag simplebank-api:12-alpine registry.localhost:5000/simplebank-api:12-alpine
# docker push registry.localhost:5000/simplebank-api:12-alpine

# k3d image import localhost:5000/postgres:12-alpine -c my-cluster
# k3d image import localhost:5000/simplebank-api:latest -c my-cluster

# create Deployment.yaml, postres-service.yaml and api-service.yaml

# Create a ClusterIP service for deployment
# kubectl create service clusterip nginx --tcp=80:80

# Create an ingress object for it by copying the following manifest (ingress.yaml) to a file and applying
# Note: k3s deploys traefik as the default ingress controller

# kubectl apply -f database-service.yaml
# kubectl apply -f api-service.yaml
# kubectl apply -f deployment.yaml

# Curl it via localhost
# curl localhost:8080/

# kubectl get deployments
# kubectl get pods
# kubectl get services

# kubectl delete deployment simplebank
# kubectl delete service postgres-service
# kubectl delete service api-service

# kubectl exec -it simplebank-c87c8f4c9-mvtn5 -- sh 

# -> apply the yamls again

# http://10.43.0.1:32665
# http://192.168.128.3:30414

# curl http://192.168.128.3:32332

# ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'

# to get internal ip addr of first node. replace 0 if you have more nodes.
#kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'