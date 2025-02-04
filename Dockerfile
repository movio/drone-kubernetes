FROM alpine:3.7
RUN apk --no-cache add curl ca-certificates bash jq py-setuptools && easy_install-2.7 awscli && \ 
    curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.9/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    mkdir -p /bin/scripts && mkdir -p /tmp && \
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH && \
    ln -s $HOME/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

COPY ./scripts /bin/scripts

ENTRYPOINT ["/bin/bash"]
CMD ["/bin/scripts/run.sh"]
