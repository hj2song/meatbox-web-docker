#!/bin/bash


ENV=prod
IMAGE_REPO="nexus.meatbox.co.kr/${ENV}/meatbox"
IMAGE_NAME="web"

# deploy to swarm cluster
IMAGE_FULL_NAME="${IMAGE_REPO}/${IMAGE_NAME}:latest" docker stack deploy --with-registry-auth -c ./docker-compose.yml ${IMAGE_NAME}
