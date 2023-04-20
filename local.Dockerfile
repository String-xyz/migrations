FROM golang:1.19.3

RUN apt update && apt upgrade -y && \
	apt install -y git \
	make openssh-client

# all the code lives here. We gonna mount the volume here
WORKDIR /migrations

# install goose for db migrations
RUN go install github.com/pressly/goose/v3/cmd/goose@latest

# will run from an entrypoint.sh file
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]