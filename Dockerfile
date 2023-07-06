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
        "https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-$ARCH.tar.gz" \
    && tar xf /opt/k6.tgz -C /opt \
    && rm -rf /opt/k6.tgz \
    && ln -s -T /opt/k6-*/k6 /usr/local/bin/k6 \
    && :

#############################################################
# install terraform binary
#############################################################
ARG TERRAFORM_VERSION="1.5.2"
RUN : \
    && set -eux \
    && export ARCH=$(test $(uname -m) = "x86_64" && echo "amd64" || echo "arm64") \
    && curl -sS -L -o /opt/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$ARCH.zip" \
    && unzip /opt/terraform.zip -d /opt/ \
    && rm -rf /opt/terraform.zip \
    && ln -s -T /opt/terraform /usr/local/bin/terraform \
    && :

#############################################################
# install Python modules for chaos experiments
#############################################################
RUN : \
    && pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir -U \
        build \
        setuptools \
        wheel \
        envsubst \
        click \
        marshmallow \
        jsonpath2 \
        chaostoolkit \
        chaostoolkit-lib \
        chaostoolkit-aws \
        chaostoolkit-addons \
        chaostoolkit-toxiproxy \
        chaostoolkit-terraform==0.0.8 \
        'git+https://github.com/chaostoolkit-incubator/chaostoolkit-grafana.git@master#egg=chaostoolkit-grafana' \
        'git+https://github.com/mcastellin/chaostoolkit-aws-attacks.git@main#egg=chaostoolkit-aws-attacks' \
    && :

#############################################################
# install custom modules and experiment files
#############################################################
WORKDIR /chaos
COPY . .

RUN chmod +x /chaos/scripts/*.sh

CMD ["/chaos/scripts/docker-entrypoint.sh"]
