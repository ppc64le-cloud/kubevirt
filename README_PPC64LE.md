# To build the image we need to create the binary file.

## Create a binary file for `virt-api` using go build.

Steps:
* `cd cmd/virt-api/`
* `go build .`

This will create the binary file `virt-api` in the same directory.

### Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-api and making as entry point .
* Run the command to build the imaage - `docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-api:v1.1.1-ppc64le`. Here we are using `quay.io/powercloud` as image repository.
* Then upload the image to the same repository using the comamnd `docker push <image reposiroty location>`

#############################################################################################
#############################################################################################

## Create a binary file for `virt-controller` using go build.

Steps:

* cd cmd/virt-controller/
* go build .

This will create the binary file virt-controller in the same directory.

### Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-controller and making as entry point .
* Run the command to build the imaage - docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-controller:v1.1.1-ppc64le. Here we are using quay.io/powercloud as image repository.
* Then upload the image to the same repository using the comamnd docker push <image reposiroty location>

#############################################################################################
#############################################################################################

## Create a binary file for `virt-operator` using go build.

Steps:

* cd cmd/virt-operator/
* go build .

This will create the binary file virt-operator in the same directory.

### Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-operator and making as entry point .
* Run the command to build the imaage - docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-operator:v1.1.1-ppc64le. Here we are using quay.io/powercloud as image repository.
* Then upload the image to the same repository using the comamnd docker push <image reposiroty location>

#############################################################################################
#############################################################################################

## Create a binary file for `virt-handler` using go build.

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

#############################################################################################
#############################################################################################

## Create a binary file for `virt-launcher` using go build.

Steps:
* `cd cmd/virt-launcher/`
* `go build .`
This will create the binary file `virt-launcher` in the same directory.

We need supported binary files here so will build the image if already created these binary then just copy to virt-launcher folder.
### virt-chroot binary file
* `cd cmd/virt-chroot/`
* `go build .`
* `cp virt-chroot ../virt-launcher/`

### virt-launcher-monitor binary file
* `cd cmd/virt-launcher-monitor/`
* `go build .`
* `cp virt-launcher-monitor ../virt-launcher/`

### container_disk binary file
* `cd cmd/container-disk-v2alpha//`
* `gcc -static main.c -o container_disk`
* `cp container_disk ../virt-launcher/`

### virt-tail binary file
* `cd cmd/virt-tail/`
* `go build .`
* `cp virt-tail ../virt-launcher/`

### virt-probe binary file
* `cd cmd/virt-probe/`
* `go build .`
* `cp virt-probe ../virt-launcher/`

### virt-freezer binary file
* `cd cmd/virt-freezer/`
* `go build .`
* `cp virt-freezer ../virt-launcher/`

### virt-freezer binary file
* `cd cmd/virt-launcher/node-labeller/`
* `cp node-labeller.sh ../`

### Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-launcher and making as entry point .
* Run the command to build the imaage - `docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-launcher:v1.1.1-ppc64le`. Here we are using `quay.io/powercloud` as image repository.
* Then upload the image to the same repository using the comamnd `docker push <image reposiroty location>`

