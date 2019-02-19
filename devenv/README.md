# Local/Offline development environment

This is an attempt to setup all the things needed for offline development.


## Dependencies
Install Node, npm, yarn, go (1.11+)

Change directory to the project root.
```
go mod download
```

Change directorty to the frontend root `frontend/`
```
yarn install
```


## Database
Install docker

Get the docker image for postgres
```
docker pull postgres:10-alpine
```


## Kubernetes (Minikube)
Install minikube and a hypervisor.

Enable ingress server
```
minikube addons enable ingress
```

Install tiller:
```
kubectl apply -f tiller.yml
helm init --upgrade --wait --tiller-namespace=kube-system --service-account=tiller
```

Install dex:
```
helm install stable/dex \
    --name dex \
    --namespace dex \
    -f dex.yaml
```

Make minikube ingress/dex accessable:
```
echo "$(minikube ip) dex.minikube" | sudo tee -a /etc/hosts
```

Minikube might get clock drift when the laptops sleeps:
```
minikube ssh -- sudo date -u (date -u +%m%d%H%M%Y.%S)
```
