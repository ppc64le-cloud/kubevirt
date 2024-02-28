# To build the image we need to create the binary file.

## Create a binary file using go build.

Steps:
* `cd cmd/virt-handler/`
* `go build .`
This will create the binary file `virt-handler` in the same directory.

We need supported binary files here so will build the image
### virt-chroot binary file
* `cd cmd/virt-chroot/`
* `go build .`
* `cp virt-chroot ../virt-handler/`

### container_disk binary file
* `cd cmd/container-disk-v2alpha//`
* `gcc -static main.c -o container_disk`
* `cp container_disk ../virt-handler/`


## Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-handler and making as entry point .
* Run the command to build the imaage - `docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-handler:v1.1.1-ppc64le`. Here we are using `quay.io/powercloud` as image repository.
* Then upload the image to the same repository using the comamnd `docker push <image reposiroty location>`
