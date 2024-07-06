#########################################
# Build base
#########################################
FROM --platform=linux/amd64 golang:1.22.4-alpine AS builder

# Set GOARCH=arm64 when building Docker for arm64 (mac os)
ENV CGO_ENABLED=1 \
    GOOS=linux \
    GOARCH=amd64

RUN apk update && apk add --no-cache make git gcc g++ pkgconfig imagemagick imagemagick-dev imagemagick-libs && rm -rf /var/cache/apk/*

WORKDIR /build
COPY . .

RUN go build -o dive_lambda .

#########################################
# Build environment
#########################################
FROM --platform=linux/amd64 amazonlinux:2

# Update and install necessary packages
RUN yum update -y && \
    yum install -y \
    ca-certificates \
    chromium \
    fontconfig \
    gcc \
    gcc-c++ \
    pkgconfig \
    ImageMagick \
    ImageMagick-devel \
    ImageMagick-libs && \
    yum clean all

# Download and install the Lambda Insights extension
RUN curl -O https://lambda-insights-extension.s3-ap-northeast-1.amazonaws.com/amazon_linux/lambda-insights-extension.rpm && \
    rpm -U lambda-insights-extension.rpm && \
    rm -f lambda-insights-extension.rpm

WORKDIR /app

COPY ./assets/template/dummy/ ./assets/template/dummy/

# Install fonts
RUN mkdir -p /usr/share/fonts && cp -r ./assets/template/dummy/fonts/. /usr/share/fonts && fc-cache -fv

COPY --from=builder /build/dive_lambda .

# Set the command to run when the container starts
CMD [ "/app/dive_lambda" ]