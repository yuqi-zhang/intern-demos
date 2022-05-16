export ARCH="amd64" && CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GO111MODULE=on go build -o server app.go
