DOCKERIMG:=carpe4me/android-sdk:29.0.4
DOCKERIMG_LATEST:=carpe4me/android-sdk
CONTAINER:=android-sdk
HOSTNAME:=docker
USER:=developer

all: start cmd

build:
	@docker build -t ${DOCKERIMG_LATEST} -t ${DOCKERIMG} .
install: create-data
	@docker run \
		-it \
		--name ${CONTAINER} \
		--hostname=${HOSTNAME} \
		--privileged -v /dev/bus/usb:/dev/bus/usb \
		-v ${HOME}/.ssh:/home/${USER}/.ssh \
		-v ${HOME}:/home/${USER}/hosthome \
		-e DISPLAY=unix${DISPLAY} --net=host \
		--mount source=gradle-user-home,target=/home/${USER}/buildcfg/gradle \
		${DOCKERIMG_LATEST}
start:
	@docker start ${CONTAINER}
stop:
	@docker stop ${CONTAINER}
uninstall:	stop
	@docker rm ${CONTAINER}
update:
	@docker pull ${DOCKERIMG_LATEST}
create-data:
	@docker volume create gradle-user-home
clean-data:
	@docker volume rm gradle-user-home
ps:
	@docker ps -a
cmd:
	@docker exec -it ${CONTAINER} /bin/bash
su:
	@docker exec -u root -it ${CONTAINER} /bin/bash
remove_container_all:
	@docker rm $(docker ps -a -q)
clean-none-images:
	@docker rmi $(docker images -f "dangling=true" -q)

# Docker Container 삭제
# $> docker stop $(docker ps -a -q)
# $> docker rm $(docker ps -a -q)

# Docker Image 삭제
# docker rmi $(docker images -q)