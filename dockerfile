FROM mcr.microsoft.com/azure-powershell:ubuntu-22.04
ENV TARGETARCH="linux-x64"

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

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
        npm \
        python3-pip \
        gettext-base \
        powershell \
        zip

# Remove conflicting package
RUN apt-get remove -y libnode72

# Install Node.js 18.x from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
&& apt-get download nodejs \
&& dpkg -i --force-overwrite $(find . -name "nodejs_*.deb")

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
&& node -v \
&& npm -v

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
