#!/bin/bash


ENV=prod
APP_NAME=web
WORKDIR=/home/super/docker
DEPLOY_PATH=${WORKDIR}/meatbox-${APP_NAME}-${ENV}
SOURCE_PATH=${WORKDIR}/meatbox-${APP_NAME}
DOCKER_PATH=${WORKDIR}/meatbox-${APP_NAME}-docker
LIBRARY_PATH=${DEPLOY_PATH}/src/main/webapp/WEB-INF/lib
RESOURCE_PATH=${DEPLOY_PATH}/src/main/resources/properties
PROPERTY_PATH=${DEPLOY_PATH}/src/main/properties/${ENV}
IMAGE_REPO="nexus.meatbox.co.kr/${ENV}/meatbox"
IMAGE_NAME="web"

# 디렉토리 존재 여부 확인
if [  -e "${DEPLOY_PATH}" ]; then
    # 디렉토리가 있다면 내부 파일 삭제
    rm -rf ${DEPLOY_PATH}/*
else
    # 디렉토리가 없다면 생성
    mkdir -p ${DEPLOY_PATH}
fi

# office 소스 PULL
git -C ${SOURCE_PATH} pull
# DOCKER 파일 PULL
git -C ${DOCKER_PATH} pull

# 소스 파일을 DEPLOY 경로로 이동
cp -rp ${SOURCE_PATH}/* ${DEPLOY_PATH}/

# 라이브러리 버전 교체
cp -r  ${DOCKER_PATH}/${APP_NAME}/lib/icu4j-50.1.1.jar ${LIBRARY_PATH}/icu4j-50.1.1.jar
rm -rf ${LIBRARY_PATH}/icu4j-4.0.1.jar
# swarmpit 사용을 위한 의도적으로 파일 추가하여 docker image layer 변경점 추가
echo "배포날짜: $(TZ='Asia/Seoul' date +"%Y-%m-%d %H:%M:%S.%3N")" > ${RESOURCE_PATH}/deploy-date.txt

# 설정 파일 교체
cp -r  ${DOCKER_PATH}/${IMAGE_NAME}/config/logback.xml ${PROPERTY_PATH}/logback.xml

# Docker Build에 필요한 파일을 DEPLOY 경로로 이동
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/tomcat ${DEPLOY_PATH}/tomcat
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/build-local.xml ${DEPLOY_PATH}/build.xml
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/Dockerfile-${APP_NAME}-local ${DEPLOY_PATH}/Dockerfile-${APP_NAME}-local
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/.dockerignore ${DEPLOY_PATH}/.dockerignore
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/docker-compose.yml ${DEPLOY_PATH}/docker-compose.yml

# Ant 빌드
ant -f ${DEPLOY_PATH}/build.xml dist || exit 0

# 이미지 태그를 git hash 값으로 설정
IMAGE_TAG="$(git -C ${SOURCE_PATH} rev-parse HEAD | cut --characters=-7)-$(git -C ${DOCKER_PATH} rev-parse HEAD | cut --characters=-7)"
echo "배포 이미지 태그: ${IMAGE_TAG}"

# Office 앱 이미지 빌드
cd ${DEPLOY_PATH} && docker build -t ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile-${APP_NAME}-local . || exit 0

# 이미지 태깅 & Push
docker tag ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_REPO}/${IMAGE_NAME}:latest
docker push ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} || exit 0
echo "pushed ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
docker push ${IMAGE_REPO}/${IMAGE_NAME}:latest || exit 0
echo "pushed ${IMAGE_REPO}/${IMAGE_NAME}:latest"

# deploy to swarm cluster
#IMAGE_FULL_NAME="${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG}" docker stack deploy --with-registry-auth -c ${DEPLOY_PATH}/docker-compose.yml ${APP_NAME}
#IMAGE_FULL_NAME="${IMAGE_REPO}/${IMAGE_NAME}:latest" docker stack deploy --with-registry-auth -c ${DEPLOY_PATH}/docker-compose.yml ${APP_NAME}

# Clean Deploy Path
rm -rf ${DEPLOY_PATH}
