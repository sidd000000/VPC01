FROM google/cloud-sdk:latest
# Installing terraform
RUN apt-get -y install unzip && \
    cd /tmp && \
    curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip && \
    unzip /tmp/terraform.zip && \
    cp /tmp/terraform /usr/local/bin && \
    chmod a+x /usr/local/bin/terraform && \
    apt-get -y remove unzip && \
    apt-get clean && \
    rm /tmp/terraform /tmp/terraform.zip
# Installing terragrunt
RUN cd /tmp && \
    curl -o /tmp/terragrunt -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.25.5/terragrunt_linux_amd64 && \
    cp /tmp/terragrunt /usr/local/bin && \
    chmod a+x /usr/local/bin/terragrunt && \
    rm /tmp/terragrunt 
# Installing OPA
RUN cd /tmp && \
    curl -o /tmp/opa -L https://github.com/open-policy-agent/opa/releases/download/v0.17.1/opa_linux_amd64 && \
    cp /tmp/opa /usr/local/bin && \
    chmod a+x /usr/local/bin/opa && \
    rm /tmp/opa