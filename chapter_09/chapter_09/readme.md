# Designing a Modern Analytics Solution with Snowflake, dbt, Matabase, Airbyte

You are now familiar with the Snowflake data warehouse (DW) and its advantages over other DW solutions. However, a typical organization won’t be using Snowflake alone. Snowflake is part of an analytics solution that consists of multiple components, including business intelligence and data integration tools.

## Preprequisite

- Snowflake Free Trial: https://signup.snowflake.com/
- Knowledge of CLI commands

> This tutorial created on MacBookPro M3. For Windows we suggest to use Ubuntu terminal.

## Installed Versions

```bash
dbt --version
Core:
  - installed: 1.8.7
  - latest:    1.8.7 - Up to date!

Plugins:
  - snowflake: 1.8.3 - Up to date!
```

## Virtual Environment

We are using Python Virtual Environment [venv](https://docs.python.org/3/library/venv.html) for this tutorial. Alternative could be popular [poetry](https://python-poetry.org/).

Make sure you have a Python installed. You can check by running this command:

```bash
python --version

Python 3.11.9
```

You can use another version of Python.

```bash
# create venv
python3 -m venv venv

# activate venv
source venv/bin/activate

# install all dependencies
pip install -r requirements.txt
```

## dbt project

Go to project dbt folder

```bash
cd snowflakebook
```

Copy and configure dbt profile:

```bash
cp profiles.yml ~/.dbt/profiles.yml
```

Export Variable with your profile

```bash
export SNOWFLAKE_ACCOUNT=<YOUR_ACCOUNT>
```

Test dbt

```bash
dbt debug
```

Install Packages

```bash
dbt deps
```

Run models

```bash
dbt build
```

The command should run models and tests. After completion you may check the result in Snowflake.

## Install Metabase

Let's install Metabase. We will use official Metabase [documentation](https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker) and will deploy Metabase community edition using Docker containers.

Assuming you have Docker installed and running, get the latest Docker image:

```bash
docker pull metabase/metabase:latest
```

Then start the Metabase container:

```bash
docker run -d -p 3000:3000 --name metabase metabase/metabase
```

This will launch an Metabase server on port 3000 by default.

Optional: to view the logs as your Open Source Metabase initializes, run:

```bash
docker logs -f metabase
```

Once startup completes, you can access your Open Source Metabase at [http://localhost:3000](http://localhost:3000).

To run your Open Source Metabase on a different port, say port 12345:

```bash
docker run -d -p 12345:3000 --name metabase metabase/metabase
```

### Metabase Query

Query for Metabase

```sql
SELECT
    dp.product_type,
    SUM(fo.final_price) AS total_sales
FROM JUMPSTART.business.fact_order fo
JOIN JUMPSTART.business.dim_product dp
    ON fo.product_key = dp.product_key
GROUP BY
    dp.product_type
ORDER BY
    total_sales DESC
LIMIT 10
```


## (Optional) Airbyte and Metabase on Kubernetes

We can optionly install Airbyte and Metabasle using local Minikube and deploy it to the remote service. This topic is out of the scope but we will provide some information to start.

> This are is unsupported and just gives you idea where to start and available options.

### Install Airbyte

We will use official [Airbyte OSS tutorial](https://docs.airbyte.com/using-airbyte/getting-started/oss-quickstart)

We will install `abctl` (Airbyte Command Line Tool).

```bash
abctl version
version: v0.22.0
```

### Run Airbyte locally

```bash
abctl local install
```

We can open the Airbyte in `http://localhost:8000`

We would need to obtain credentials

```bash
abctl local credentials
```

> If your laptop is weak you can try to run with `abctl local install --low-resource-mode`.


## Option 2: Setup Minikube

### Install Minikube

We can using [minikube start guide](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download).

**Install it for you OS. In my case, I am using MacBookPro with M3. Commands are specific for Apple Silicon.**

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

Start minicube

```bash
minikube start
```

Adding Ingress

```bash
# Enable Ingress addon
minikube addons enable ingress
```

To install `kubectl` we can use [official guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/).

```bash
# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
fi
```

> `kubectl` (pronounced "kube-control" or "kube-cuddle" or "kube-C-T-L") is the primary command-line interface for managing Kubernetes clusters.

To install Helm we can use [official guide](https://github.com/helm/helm).

```bash
# Install Helm if not present
brew install helm
```

> Helm, which is often called the "package manager for Kubernetes" - think of it like apt/yum for Linux or npm for Node.js, but for Kubernetes applications.

We have everything we need and now we can create data stack.

```bash
# Create namespace for our stack
kubectl create namespace data-stack

namespace/data-stack created
```

### Install Airbyte

[Official Airbyte Helm-Chart](https://artifacthub.io/packages/helm/airbyte/airbyte).

```bash
helm repo add airbyte https://airbytehq.github.io/helm-charts

helm install my-airbyte airbyte/airbyte --version 1.2.0
NAME: my-airbyte

NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=webapp" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### Install Metabase

[Official Metabase Helm-Chart](https://artifacthub.io/packages/helm/pmint93/metabase).

```bash
echo "Installing Metabase..."
helm repo add pmint93 https://pmint93.github.io/helm-charts
helm repo update
helm install metabase pmint93/metabase \
    --namespace data-stack \
    --set database.type=postgres \
    --set database.host=postgres-postgresql \
    --set database.port=5432 \
    --set database.dbname=metabase \
    --set database.username=postgres \
    --set database.password=your_secure_password \
    --set service.type=NodePort
```

Get Metabase information:

```bash
export NODE_PORT=$(kubectl get --namespace data-stack -o jsonpath="{.spec.ports[0].nodePort}" services metabase)
export NODE_IP=$(kubectl get nodes --namespace data-stack -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$NODE_IP:$NODE_PORT
```
