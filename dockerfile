FROM mcr.microsoft.com/azure-powershell:ubuntu-22.04
ENV TARGETARCH="linux-x64"
ENV PYTHON_VERSION=3.9
ENV PYTHONPATH=/usr/local/lib/python${PYTHON_VERSION}

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Update and remove Python 3.10 first
RUN apt-get update \
&& apt-get purge -y python3.10 python3.10-minimal python3 python3-minimal \
&& apt-get autoremove -y \
&& apt-get clean

# Install software-properties-common to manage repositories
RUN apt-get update \
&& apt-get install -y software-properties-common

# Add deadsnakes PPA for Python 3.9
RUN add-apt-repository ppa:deadsnakes/ppa \
&& apt-get update

# Install necessary packages including Python 3.9
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        git \
        iputils-ping \
        libicu70 \
        libcurl4 \
        libunwind8 \
        netcat \
        ruby \
        unzip \
        dnsutils \
        gnupg \
        nodejs \
        npm \
        python${PYTHON_VERSION} \
        python3-pip \
        gettext-base \
        powershell \
        zip \
        docker.io \
&& apt-get clean \
&& update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN curl -sL https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip -o terraform.zip \
&& unzip terraform.zip \
&& mv terraform /usr/local/bin/ \
&& rm terraform.zip

# Install Azure Functions Core Tools
RUN npm install -g azure-functions-core-tools@4

# Verify installations
RUN terraform -version \
&& az --version \
&& func --version \
&& pip3 --version \
&& python3 --version \
&& envsubst --version \
&& pwsh --version \
&& zip --version \
&& docker --version

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

# Uncomment to allow the agent to run as root
# ENV AGENT_ALLOW_RUNASROOT="true"

# Remove USER agent to run as root
USER agent

ENTRYPOINT [ "./start.sh" ]
