#!/bin/bash
export JAVA_HOME=/usr/local/java/java-se-7u75-ri
export ANT_HOME=/usr/local/apache-ant-1.9.16
export PATH=$PATH:$JAVA_HOME/bin:$ANT_HOME/bin

GIT_TAG=$1
GITHUB_USERNAME=meatbox-git
GITHUB_TOKEN=$2
REPO_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/meatbox-git/meatbox-admin.git"

ENV=prod
APP_NAME=office
WORKDIR=/home/super/docker
DEPLOY_PATH=${WORKDIR}/meatbox-${APP_NAME}-${ENV}
SOURCE_PATH=${WORKDIR}/meatbox-admin
DOCKER_PATH=${WORKDIR}/meatbox-${APP_NAME}-docker
LIBRARY_PATH=${DEPLOY_PATH}/src/main/webapp/WEB-INF/lib
RESOURCE_PATH=${DEPLOY_PATH}/src/main/resources/properties
PROPERTY_PATH=${DEPLOY_PATH}/src/main/properties/${ENV}
IMAGE_REPO="nexus.meatbox.co.kr/${ENV}/meatbox"
IMAGE_NAME="office"

# 깃 태그 이름과 토큰이 제공되지 않았을 경우 오류 메시지를 출력하고 종료합니다.
if [ -z "${GIT_TAG}" ] || [ -z "${GITHUB_TOKEN}" ]; then
    echo "사용법: $0 <배포 태그 명> <Github Token>"
    exit 1
fi

echo "배포 태그 명: ${GIT_TAG}"

# 디렉토리 존재 여부 확인
if [  -e "${DEPLOY_PATH}" ]; then
    # 디렉토리가 있다면 내부 파일 삭제
    rm -rf ${DEPLOY_PATH}/*
else
    # 디렉토리가 없다면 생성
    mkdir -p ${DEPLOY_PATH}
fi

# office 소스 Clone
rm -rf ${SOURCE_PATH} && cd ${WORKDIR} && git clone --depth 1 --branch ${GIT_TAG} ${REPO_URL} || exit
# DOCKER 파일 PULL
git -C ${DOCKER_PATH} pull || exit

# 소스 파일을 DEPLOY 경로로 이동
cp -rp ${SOURCE_PATH}/* ${DEPLOY_PATH}/ || exit

# 라이브러리 버전 교체
cp -r  ${DOCKER_PATH}/${APP_NAME}/lib/icu4j-50.1.1.jar ${LIBRARY_PATH}/icu4j-50.1.1.jar || exit
rm -rf ${LIBRARY_PATH}/icu4j-4.0.1.jar
# swarmpit 사용을 위한 의도적으로 파일 추가하여 docker image layer 변경점 추가
echo "배포날짜: $(TZ='Asia/Seoul' date +"%Y-%m-%d %H:%M:%S.%3N")" > ${RESOURCE_PATH}/deploy-date.txt

# 설정 파일 교체
sed -i 's|\${catalina.home}/logs|&/${HOSTNAME}|g' ${PROPERTY_PATH}/logback.xml || exit

# Docker Build에 필요한 파일을 DEPLOY 경로로 이동
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/tomcat ${DEPLOY_PATH}/tomcat || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/build-local.xml ${DEPLOY_PATH}/build.xml || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/Dockerfile-${APP_NAME}-local ${DEPLOY_PATH}/Dockerfile-${APP_NAME}-local || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/.dockerignore ${DEPLOY_PATH}/.dockerignore || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/const\(RELEASE-DOCKER\).xml ${RESOURCE_PATH}/const\(RELEASE-DOCKER\).xml || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/docker-compose.yml ${DEPLOY_PATH}/docker-compose.yml || exit
cp -rp ${DOCKER_PATH}/${APP_NAME}/deploy/managerview.png ${DEPLOY_PATH}/src/main/webapp/img/demo/managerview.png || exit

# Ant 빌드
ant -f ${DEPLOY_PATH}/build.xml dist || exit

# 이미지 태그를 git hash 값으로 설정
IMAGE_TAG=${GIT_TAG//\//_}  # 슬래시를 언더스코어로 대체
echo "배포 이미지 태그: ${IMAGE_TAG}"

# office 앱 이미지 빌드
cd ${DEPLOY_PATH} && docker build -t ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile-${APP_NAME}-local . || exit

# 이미지 태깅 & Push
docker tag ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_REPO}/${IMAGE_NAME}:latest
docker push ${IMAGE_REPO}/${IMAGE_NAME}:latest || exit
echo "pushed ${IMAGE_REPO}/${IMAGE_NAME}:latest"
docker push ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG} || exit
echo "pushed ${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

# Clean Deploy Path
rm -rf ${DEPLOY_PATH} ${SOURCE_PATH}
