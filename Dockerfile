# This is a multi-stage Dockerfile and requires >= Docker 17.05
# https://docs.docker.com/engine/userguide/eng-image/multistage-build/
#
#
FROM node:10 as elm
WORKDIR /app

COPY frontend/package.json .
RUN yarn install --silent

COPY frontend/elm.json .

ENV NODE_ENV "production"
COPY frontend .
RUN yarn run prod


# Build binary
FROM golang:latest as buffalo

RUN go get -u github.com/gobuffalo/packr/packr
# RUN apt-get update && apt-get install -y \
#     ca-certificates \
#  && rm -rf /var/lib/apt/lists/*

ENV GO111MODULE=on

RUN mkdir -p $GOPATH/src/github.com/kradalby/bork
WORKDIR $GOPATH/src/github.com/kradalby/bork

# Add transpiled frontend code
RUN mkdir -p assets templates

COPY --from=elm /app/dist/index.html ./templates/index.html
COPY --from=elm /app/dist ./assets


COPY . .
# RUN go mod download

RUN packr -z

# RUN CGO_ENABLED=0 go build -o /bin/app 
RUN CGO_ENABLED=0 go build -mod vendor -o /bin/app 
# RUN buffalo build --static -o /bin/app

FROM ubuntu:latest
# Trying something
RUN apt-get update && apt-get install -y \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /bin/

COPY --from=buffalo /bin/app .
COPY database.yml .

# Uncomment to run the binary in "production" mode:
ENV GO_ENV=production

# Bind the app to 0.0.0.0 so it can be seen from outside the container
ENV ADDR=0.0.0.0

EXPOSE 3000

# Uncomment to run the migrations before running the binary:
# CMD /bin/app migrate; /bin/app
CMD exec /bin/app serve
