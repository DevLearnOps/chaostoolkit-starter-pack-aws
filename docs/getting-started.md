# Getting Started

## Concepts

Chaos Toolkit Starter Pack for AWS is a *template project* to accelerate the adoption of chaos engineering practices. The experiments in this project are created using [Chaos Toolkit][chaostoolkit], a simple and extensible framework for chaos engineering.

### Why Chaos Toolkit?

There are a number of chaos engineering frameworks available today, each with pros and cons. We decided to create the Starter Pack for AWS using Chaos Toolkit mainly because of its simplicity.

Implementing your first chaos engineering project is no easy feat. Especially at the beginning, engineers need to learn new techniques to inject faults into their systems, evaluate what works with their infrastructure and what does not. Chaos Toolkit comes with no additional overhead, the only requirements are Python and a few other command-line utilities and gives teams the freedom to build prototypes quickly.

### Project structure

> This is project is still under development so the project structure may be subject to change in future versions

```text
.
├── infrastructure/
├── library/
├── modules/
├── my-experiments/
├── Dockerfile
├── push_to_ecr.sh
├── requirements-dev.txt
├── requirements.txt
├── start-chaos.py
└── submit-job.py
```

#### `infrastructure/`
The `infrastructure/` directory contains the Terraform code to deploy the sample application into your own AWS infrastructure.

#### `library/`
The `library/` directory contains all Chaos Toolkit experiment examples provided with the starter pack.

#### `modules/`
The `modules/` directory contains Python modules that provide custom Chaos Toolkit activities used in experiments.

#### `my-experiments/`
The `my-experiments/` directory is an empty placeholder to store user-created experiments.

#### `Dockerfile`
The Dockerfile used to bundle all templates, tools and modules into a single container image to run chaos experiments on AWS.

#### `push_to_ecr.sh`
A utility shell script to build and push the container to AWS ECR (Elastic Container Registry).

#### `requirements.txt` and `requirements-dev.txt`
List of Python requirements to execute and develop chaos experiments.

#### `start-chaos.py`
A Python wrapper for Chaos Toolkit CLI that facilitates variables configuration and reporting. For help see `./start-chaos.py --help`.

#### `submit-job.py`
A Python utility to submit a chaos experiment request to the AWS Batch environment queue. For help see `./submit-job.py --help`.


## Setting up locally

### Setup the Python interpreter and Pip

Chaos Toolkit is a Python application and needs the Python interpreter to run. Most systems today have a Python version pre-installed.

To verify if the `python` interpreter and `pip` are already available in your system, run the following commands using your terminal:

```shell
python --version
# Python 3.11.5

pip --version
# pip 23.1 from /Users/manuel/.pyenv/versions/3.11.3/lib/python3.11/site-packages/pip (python 3.11)
```

Any Python version `>=3.7` should be fine to run Chaos Toolkit. In case the commands above return and error you need to install a Python version in your system.

Depending on the operating system you're running on the installation process may be different.

**On Windows**:

You can download the Python binary installer from the [official website](https://www.python.org/downloads/windows/).

**On MacOS X**:
```shell
brew install python3
```

**On Debian/Ubuntu**:
```shell
sudo apt-get install python3 python3-dev
```

After following the installation steps, verify that Python and Pip have been correctly installed using the `python --version` and `pip --version` commands described above.


### Create a new virtual environment

A Python **virtualenv** is a self-contained Python installation created from the existing Python environment (known as the *base* environment). The main benefit of using a virtual environment instead of the base Python installation is being able to create a separate space where all our project dependencies will live.

To create a new virtual environment we need to install the `virtualenv` package with `pip`:

```shell
pip install -U virtualenv
```

After the installation is complete, we create a new virtualenv in the `./venv/` directory:

```shell
python -m venv ./venv/
```

The command above, will create a new folder in your current directory called `venv/` that contains the Python binaries and all additional packages we install.

> IMPORTANT: your system will not use the Python virtualenv by default. We need to activate the virtual environment in `./venv/` before we can use it!

Every time we open a new terminal window, we need to tell our terminal to use the virtual environment instead of the base Python interpreter. To do so we use the `activate` utility script provided with the virtualenv:

**On Windows**:
```shell
venv/Scripts/activate.bat
```

**On MacOS X**:
```shell
source venv/bin/activate
```

### Install Python requirements

All project requirements and development requirements are stored in respectively the `requirements.txt` and `requirements-dev.txt` files.
Installing the packages listed in the `requirements.txt` is sufficient for executing experiments both locally and on the AWS Batch compute environment.

Use the following command to install all packages from a requirements file:
```shell
pip install -r requirements.txt
```

To verify the requirements installation was successful, check if the Chaos Toolkit CLI is available in your virtual environment:
```shell
chaos --version
# chaos, version 1.15.1
```

## Installing additional dependencies
Some of the chaos experiments provided with *ChaosToolkit Starter Pack for AWS* require additional dependencies to run. If that's the case, the experiment's `README` file will provide a list of additional software required to run.

### Install Terraform and Terragrunt

**ChaosToolkit Starter Pack for AWS** uses [Terraform][terraform] and [Terragrunt][terragrunt] to provision the infrastructure for the sample application and run experiments.

* [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
* [Install Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

### Install AWS CLI

* [Install the AWS CLI V2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Install Grafana K6

**Grafana K6** is a load generation tool and required by the `chaostoolkit-grafana` Python extension for Chaos Toolkit. Follow the instructions in the [Official Grafana documentation](https://k6.io/docs/get-started/installation/) to install `k6` in your machine.

### Install `aws-fail-az`

**aws-fail-az** is a Go program that simulates AZ (Availability Zone) failures on AWS resources. To install this tool, follow the installation instructions provided in the project's homepage:

* [Install `aws-fail-az`](https://github.com/mcastellin/aws-fail-az#readme)


## Deploying the test infrastructure

**ChaosToolkit Starter Pack for AWS** comes with a sample application infrastructure you can deploy on your own AWS account. It provides a microservices application called `comments-app` that can store users' comments for blog posts and articles.

The sample infrastructure will deploy three microservices into AWS ECS (Elastic Container Service):

* **comments-web**: the web layer exposes the application API to the Internet. It's a Nodejs application and its role is providing a consistent API interface to the public by forwarding incoming requests to the `comments-api` microservice
* **comments-api**: the core microservice of the application written in Java. It stores information about *users*, *posts* and *comments* into an RDS database
* **comments-spamcheck**: a Python microservice that uses a pre-trained machine learning model to filter offensive comments automatically

To provide different types of deployment to experiment with, some microservices are provisioned using AWS Fargate, while other are deployed on an ECS Cluster with EC2 capacity providers.

Find below an **overview of the application architecture provided**:

![comments-app infrastructure overview](img/comments-app-infrastructure-overview.svg)

### Provision the application in your AWS account

We use **Terraform** and **Terragrunt** to automate the application infrastructure deployment. All provided infrastructure code is located under the `infrastructure/` folder in this project.

```text
infrastructure/
├── README.md
├── comments-app/
│   ├── networking/
│   ├── services/
│   └── terragrunt.hcl
└── submodules/
    ├── compute-environment/
    └── ecs-cluster-ec2-provider/
```

The Terraform code that creates the app infrastructure is organized in different modules and tied together using Terragrunt. The `terragrunt` CLI will allow us to deploy the entire application stack using a single command.

To deploy the infrastructure, first locate your AWS Account ID from the [AWS Console](http://console.aws.amazon.com) and export it as a variable in your current terminal together with the AWS Region and CLI profile:

```shell
export AWS_ACCOUNT_ID=XXXXXXXXXXXX
export AWS_REGION=us-east-1
export AWS_PROFILE=default
```

```shell
cd infrastructure/comments-app/

terragrunt run-all apply
# INFO[0000] The stack at infrastructure/comments-app will be processed in the following order for command apply:
# Group 1
# - Module infrastructure/comments-app/networking
# 
# Group 2
# - Module infrastructure/comments-app/services
# 
# Are you sure you want to run 'terragrunt apply' in each folder of the stack described above? (y/n)
#
# <-- reply `y`
```



## Running experiments locally with Chaos Toolkit CLI

## Running experiments using the `start-chaos.py` wrapper script


[chaostoolkit]: https://chaostoolkit.org
[terraform]: https://www.terraform.io/
[terragrunt]: https://terragrunt.gruntwork.io/
