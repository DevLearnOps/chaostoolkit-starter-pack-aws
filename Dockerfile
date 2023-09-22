FROM python:3.11-slim-bullseye

#############################################################
# install AWS cloudwatch agent
#############################################################
RUN : \
    && apt-get update \
    && apt-get install --no-install-recommends -qq -y \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && export ARCH=$(test $(uname -m) = "x86_64" && echo "amd64" || echo "arm64") \
    && curl -sS -L -o /opt/amazon-cloudwatch-agent.deb \
        https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/${ARCH}/latest/amazon-cloudwatch-agent.deb \
    && dpkg -i -E /opt/amazon-cloudwatch-agent.deb \
    && rm -f /opt/amazon-cloudwatch-agent.deb \
    && :

ENV ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]'

#############################################################
# install Grafana k6 binary
#############################################################
ARG K6_VERSION="0.45.0"
RUN : \
    && set -eux \
    && apt-get update \
    && apt-get install --no-install-recommends -qq -y \
        unzip \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && export ARCH=$(test $(uname -m) = "x86_64" && echo "amd64" || echo "arm64") \
    && curl -sS -L -o /opt/k6.tgz \
        "https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-${ARCH}.tar.gz" \
    && tar xf /opt/k6.tgz -C /opt \
    && rm -rf /opt/k6.tgz \
    && ln -s -T /opt/k6-*/k6 /usr/local/bin/k6 \
    && :

#############################################################
# install terraform binary
#############################################################
ARG TERRAFORM_VERSION="1.5.5"
RUN : \
    && set -eux \
    && export ARCH=$(test $(uname -m) = "x86_64" && echo "amd64" || echo "arm64") \
    && curl -sS -L -o /opt/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
    && unzip /opt/terraform.zip -d /opt/ \
    && rm -rf /opt/terraform.zip \
    && ln -s -T /opt/terraform /usr/local/bin/terraform \
    && :

#############################################################
# install aws-fail-az binary
#############################################################
ARG AWS_FAIL_AZ_VERSION="0.0.7"
RUN : \
    && set -eux \
    && export ARCH=$(test $(uname -m) = "x86_64" && echo "x86_64" || echo "arm64") \
    && curl -sS -L -o /opt/aws-fail-az.tar.gz \
        "https://github.com/mcastellin/aws-fail-az/releases/download/${AWS_FAIL_AZ_VERSION}/aws-fail-az_Linux_${ARCH}.tar.gz" \
    && tar xf /opt/aws-fail-az.tar.gz -C /opt/ \
    && rm -rf /opt/aws-fail-az.tar.gz \
    && ln -s -T /opt/aws-fail-az /usr/local/bin/aws-fail-az \
    && :

#############################################################
# install Python modules for chaos experiments
#############################################################
COPY requirements.txt .
RUN : \
    && pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir -U \
        build \
        setuptools \
        wheel \
        envsubst \
    && pip install --no-cache-dir -U -r requirements.txt \
    && :

#############################################################
# install custom modules and experiment files
#############################################################
WORKDIR /chaos
COPY . .

ENV PYTHONPATH="/chaos/modules/"

CMD []
ENTRYPOINT ["python", "/chaos/start-chaos.py"]
