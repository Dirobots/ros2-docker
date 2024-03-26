#!/bin/bash

check_docker_installation() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo "Docker is not running"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        echo "Docker Compose is not installed"
        exit 1
    fi

    if ! command -v nvidia-container-cli --version &> /dev/null; then
        echo "Nvidia Container toolkit is not installed"
        #TODO: Add installation instructions or install it automatically
        exit 1
    fi
}

is_image_built() {
    if ! docker inspect $1 &> /dev/null; then
        echo "Docker image $1 is not built"
        return 1
    fi
    return 0
}

build_image() {
    docker build . --tag=$1 --network=host
}

setup_x11_authorization() {
    # Create a named temporary file for X11 authorization
    xauth_path=$(mktemp -t .dockerXXXXXX.xauth)

    # Ensure the X11 authorization file exists
    if [ ! -f "$xauth_path" ]; then
        touch "$xauth_path"
    fi

    # Populate the authorization file with necessary data
    xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$xauth_path" nmerge -

    if [ $? -ne 0 ]; then
        echo "Failed setting up XAuthority"
        exit 1
    fi

    echo "$xauth_path"
}

launch_docker_compose() {
    xauth_path=$1

    # Export the X11 authorization file path (for Docker Compose)
    export XAUTHORITY=$xauth_path
    export XAUTH_PATH=$xauth_path

    docker compose up -d --build

    if [ $? -ne 0 ]; then
        echo "Failed to launch Docker container"
        exit 1
    fi
}

is_container_running() {
    if [ ! "$( docker container inspect -f '{{.State.Status}}' $1 )" = "running" ]; then
        return 1
    fi
    return 0
}

image_tag="dirobots/turtle:v1"
container_name="turtle"

check_docker_installation

if ! is_image_built $image_tag; then
    echo "Docker image is not built. Building it now..."
    build_image $image_tag
fi

if is_container_running $container_name ; then
    echo "Container is already running, reattaching to it..."
    docker exec -it $container_name bash
else
    echo "Container is not running, starting it..."
    xauth_name=$(setup_x11_authorization)
    launch_docker_compose $xauth_name

    if ! is_container_running $container_name ; then
        echo "Failed to start container"
        exit 1
    fi

    echo "Container is running, attaching to it..."
    docker exec -it $container_name bash
fi
