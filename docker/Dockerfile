FROM alpine:latest

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
  && apk add --no-cache \
  git \
  make \
  musl-dev \
  go
#   paxmark bison flex texinfo gawk zip gmp-dev mpfr-dev mpc1-dev zlib-dev libucontext-dev linux-headers isl-dev gcc-gnat-bootstrap

# Configure Go
ENV GOROOT=/usr/lib/go \
    GOPATH=/go \
    PATH=/go/bin:$PATH \
    BOULDER_GO_BUILDFLAGS="" \
    BOULDER_GO_LDFLAGS=" -s -w "

RUN  mkdir -p ${GOPATH}/src ${GOPATH}/bin \
  && git clone https://github.com/letsencrypt/boulder/ $GOPATH/src/github.com/letsencrypt/boulder \
  && cd $GOPATH/src/github.com/letsencrypt/boulder \
  && sed -i 's/GO_BUILD_FLAGS = -ldflags "\(.*\)/GO_BUILD_FLAGS = ${BOULDER_GO_BUILDFLAGS}  -ldflags "${BOULDER_GO_LDFLAGS} \1/g' Makefile \
  && make \
  && go get bitbucket.org/liamstask/goose/cmd/goose \
  && go get github.com/jsha/minica \
  && go get github.com/patsys/grpc_health_proxy@v1.1.0


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
   integration" \
   DB_CLEAN_INIT=false \
   ENVIRONMENT="" \
   AKAMAI_SECRET=very-secret

RUN apk --no-cache add \
  gettext \
  rsyslog \
  monit \
  softhsm \
  curl \
  mysql-client \
  && curl -Lo yaml2json https://github.com/wakeful/yaml2json/releases/latest/download/yaml2json-linux-amd64 && chmod ugo+x yaml2json && mv yaml2json /usr/local/bin/

COPY entrypoint.sh /opt/entrypoint
COPY conf/monit/* /opt/boulder/template/monit/
COPY script/monit/* /opt/monit/
COPY conf/grpc-health-proxy/* /opt/boulder/template/grpc-health-proxy/
COPY script/migrate.sh /opt/boulder/migrate
COPY script/create_pki.sh /opt/boulder/create_pki

COPY --from=0 /go/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/config /opt/boulder/config/test
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/secrets /opt/boulder/config/test/secrets
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/grpc-creds /opt/boulder/config/test/secrets/ca
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.json /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.yml /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.yaml /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.pem /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.key /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.der /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db /opt/boulder/sql/_db
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db-next /opt/boulder/sql/_db-next
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/sa_db_users.sql /opt/boulder/sql/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/cert-ceremonies /opt/boulder/cert-ceremonies
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/wfe-tls /opt/boulder/config/test/wfe-tls
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/mail-test-srv/localhost/*.pem /opt/boulder/config/test/secrets/ca/mail-test-srv/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/mail-test-srv/*.pem /opt/boulder/config/test/secrets/ca/mail-test-srv/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*-template /opt/boulder/config/test/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/mail-test-srv/*.pem /opt/boulder/config/test/mail-test-srv/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/ct-test-srv/*.json /opt/boulder/config/test/ct-test-srv/

RUN find /opt/boulder/config  -name "**.json"  -type f -exec sh -c ' \
       sed -i "s|\"test/grpc-creds/|\"/opt/boulder/config/test/secrets/ca/|g" "$0"; \ 
       sed -i "s|\"test/|\"/opt/boulder/config/test/|g" "$0"; \
       sed -i "s|/usr/local/lib/|/usr/lib/|g" "$0"; \
       sed -i "s|/tmp/|/pki/|g" "$0"' {} \; \ 
    && find /opt/boulder/cert-ceremonies/ -name "*.yaml" -type f -exec sh -c ' \
       sed -i "s|/usr/local/lib/|/usr/lib/|g" "$0"; \
       sed -i "s|/tmp/|/pki/|g" "$0"' {} \; \
    && mkdir /pki

ENTRYPOINT ["/opt/entrypoint"]
CMD ["monit","-d","5","-I","-B","-c","/etc/monitrc$ENVIRONMENT"]
