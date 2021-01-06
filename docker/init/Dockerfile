FROM alpine:latest

RUN apk add --no-cache \
  git \
  make \
  musl-dev \
  go


# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin \
  && git clone https://github.com/letsencrypt/boulder/ $GOPATH/src/github.com/letsencrypt/boulder \
  && cd $GOPATH/src/github.com/letsencrypt/boulder \
  && make \
  && go get bitbucket.org/liamstask/goose/cmd/goose \
  && go get github.com/jsha/minica

FROM alpine:3  

MAINTAINER Patrick Weber "docker@patweber.de"

LABEL io.k8s.description="Boulder" \ 
      io.k8s.display-name="Boulder"

ENV PATH /opt/boulder/bin:$PATH
ENV INTERNAL_DOMAIN=boulder \
    INTERMEDIATE_COMMON_NAME="test intermediate" \
    DB_MIGRATE_USER=root \
    DB_HOST=boulder-mysql \
    DB_PORT=3306 \
    DB_ENVS="test \
    integration"

RUN apk --no-cache add \
  gettext \
  rsyslog \
  mysql-client \
  softhsm

COPY entrypoint.sh /opt/entrypoint
COPY script/migrate.sh /opt/boulder/migrate
COPY script/create_pki.sh /opt/boulder/create_pki

COPY --from=0 /go/src/github.com/letsencrypt/boulder/bin/ /opt/boulder/bin
COPY --from=0 /go/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/config /opt/boulder/config
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/grpc-creds /opt/boulder/config/secrets/ca
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/create_db.sh /opt/boulder/scripts
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db /opt/boulder/sql/_db
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db-next /opt/boulder/sql/_db-next
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/sa_db_users.sql /opt/boulder/sql/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/cert-ceremonies /opt/boulder/cert-ceremonies
RUN find /opt/boulder/config  -name "**.json"  -type f -exec sh -c ' \
       sed -i "s|test/secrets/|/opt/boulder/config/secrets/|g" "$0"; \
       sed -i "s|test/grpc-creds/|/opt/boulder/config/secrets/ca/|g" "$0"; \ 
       sed -i "s|test/|/opt/boulder/config/|g" "$0"' {} \; \
    && find /opt/boulder/cert-ceremonies/ -name "*.yaml" -type f -exec sh -c ' \
       sed -i "s|/usr/local/lib/|/usr/lib/|g" "$0"; \
       sed -i "s|/tmp/|/pki/|g" "$0"' {} \; \
    && mkdir /pki

ENTRYPOINT ["/opt/entrypoint"]
CMD ["sleep","1"]
