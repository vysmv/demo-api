FROM golang:1.26.3-trixie

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
        git \
        postgresql-client \
        redis-tools \
        gosu \
        curl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/golang-migrate/migrate/releases/download/v4.16.2/migrate.linux-amd64.tar.gz \
    | tar xvz && \
    mv migrate /usr/local/bin/migrate

ENV GOFLAGS="-buildvcs=false"

COPY go.mod go.sum ./

RUN go mod download

COPY . .

CMD ["bash", "./docker/entrypoint.sh"]