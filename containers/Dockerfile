# Specify the base image you want to use. In this case it's fedora linux
FROM fedora:35

# Install golang
RUN dnf install -y golang

# Set the working directory inside the image
WORKDIR /demo-server

# Copy and download all dependencies using go mod
COPY go.mod .
COPY go.sum .
RUN go mod download

# Grab all the code and put it into the image
COPY . .

# Build the application
RUN export ARCH="amd64" && \
  CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GO111MODULE=on go build -o server app.go

# Run the compiled application
ENTRYPOINT ["./server"]
