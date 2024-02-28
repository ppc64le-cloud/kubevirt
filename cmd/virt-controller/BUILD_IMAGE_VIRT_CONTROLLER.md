# To build the image we need to create the binary file.

## Create a binary file using go build.

Steps:

* cd cmd/virt-controller/
* go build .

This will create the binary file virt-controller in the same directory.

## Create image using the binary

* Dockerfile has a content to copy the binary file to /usr/bin/virt-controller and making as entry point .
* Run the command to build the imaage - docker buildx build --platform=linux/ppc64le . -t quay.io/powercloud/virt-controller:v1.1.1-ppc64le. Here we are using quay.io/powercloud as image repository.
* Then upload the image to the same repository using the comamnd docker push <image reposiroty location>
