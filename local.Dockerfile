FROM golang:1.19.3

RUN apt update && apt upgrade -y && \
	apt install -y git \
	make openssh-client

# all the code lives here. We gonna mount the volume here
WORKDIR /migrations


# will run from an entrypoint.sh file
ADD migrations/ migrations/
ADD cmd/ cmd/
COPY entrypoint.sh /entrypoint.sh
ADD .env .env
ADD go.mod go.mod
ADD go.sum go.sum

RUN go mod download

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]