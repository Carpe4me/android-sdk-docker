# ============================================================================ #
# Base image 설정
FROM ubuntu:18.04

# ============================================================================ #
# Author
LABEL maintainer Carpe4me "carpe4me@gmail.com"

# ============================================================================ #
# Change Mirror Server
RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

# Set Timezone
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Language/locale settings
#ENV LANG=ko_KR.UTF-8
#RUN  echo "ko_KR.UTF-8 UTF-8" > /etc/locale.gen \
#    && echo "LANG=ko_KR.UTF-8" > /etc/default/locale
# ---------------------------------------------------------------------------- #

# ============================================================================ #
## Install Essential tools
# support multiarch: i386 architecture
# install 32bit library 참고: 64비트 버전의 Ubuntu를 실행하는 경우, 다음 명령으로 일부 32비트 라이브러리를 설치해야 합니다.
#                             (https://developer.android.com/studio/install)
# install Java
# install essential tools
# install Qt
# Clean up
RUN dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
        libncurses5:i386 libc6:i386 libstdc++6:i386 zlib1g:i386 lib32z1 lib32ncurses5 lib32stdc++6 lib32gcc1 \
        git wget zip unzip vim sudo curl gnupg2 openssh-server \
        openjdk-8-jdk \
        qt5-default \
        locales language-pack-ko fonts-nanum fonts-nanum-coding \
        uim im-config \
        gdebi-core \
    && apt-get -y autoremove \
    && apt-get clean \
    && apt-get -y autoclean
# ---------------------------------------------------------------------------- #

# ============================================================================ #
# 개발자 Font 추가
# [D2Coding] https://github.com/naver/d2codingfont/releases
# [Bitstream Vera Sans Mono] http://ftp.gnome.org/pub/GNOME/sources/ttf-bitstream-vera/1.10/
RUN wget -q https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip && \
    mkdir -p /usr/share/fonts/truetype/D2Coding && \
    unzip -qq D2Coding-*.zip -d /usr/share/fonts/truetype/D2Coding && \
    wget -q http://ftp.gnome.org/pub/GNOME/sources/ttf-bitstream-vera/1.10/ttf-bitstream-vera-1.10.zip &&\
    mkdir -p /usr/share/fonts/truetype/ttf-bitstream-vera && \
    unzip -qq ttf-bitstream-vera*.zip -d /usr/share/fonts/truetype/ttf-bitstream-vera &&\
    fc-cache -f -v &&\
    rm -f /tmp/D2Coding-Ver*.zip &&\
    rm -f /tmp/ttf-bitstream-vera-*.zip
# ---------------------------------------------------------------------------- #

# ============================================================================ #
## Add User : Docker에서 사용되는 기본 User 설정
ENV user=developer \
    group=developer \
    uid=1000 \
    gid=1000

RUN useradd -m -u ${uid} ${user} && \
    echo "${user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    chown -R ${user}:${group} /home/${user}

ENV HOME_DIR=/home/${user} \
    TOOL_DIR=/opt \
    BUILD_CFG=/home/${user}/buildcfg

RUN chown -R ${user}:${group} $TOOL_DIR

WORKDIR ${TOOL_DIR}
USER ${user}
# ---------------------------------------------------------------------------- #

# ============================================================================ #
# Gradle configuration
ENV GRADLE_VERSION=5.6.4
ENV GRADLE_HOME=$TOOL_DIR/gradle/gradle-$GRADLE_VERSION \
    GRADLE_USER_HOME=${BUILD_CFG}/gradle
ENV PATH=${PATH}:${GRADLE_HOME}/bin

# Change the gradle user home
# https://stackoverflow.com/questions/12016681/how-to-change-gradle-download-location

RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -qq gradle*.zip -d $TOOL_DIR/gradle && \
    mkdir -p $GRADLE_USER_HOME && \
    rm gradle*.zip
# ---------------------------------------------------------------------------- #

# ====================================================================== #
# Kotlin compiler configuration
ENV KOTLIN_VERSION=1.3.40 \
    KOTLIN_HOME=$TOOL_DIR/kotlinc
ENV PATH=${PATH}:${KOTLIN_HOME}/bin

RUN wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip && \
    unzip -qq *kotlin*.zip -d $TOOL_DIR/ && \
    rm kotlin-compiler-*.zip
# ------------------------------------------------------------------------ #

# ======================================================================== #
# Install Android SDK
ENV ANDROID_SDK_VERSION=6200805_latest \
    ANDROID_HOME=$TOOL_DIR/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}.zip && \
    mkdir -p $ANDROID_HOME &&\
    unzip -qq *commandlinetools*linux*.zip -d $ANDROID_HOME && \
    chmod -R a+w ${ANDROID_HOME} && \
    rm *commandlinetools*linux*.zip

# setup adb server
EXPOSE 5037
# ------------------------------------------------------------------------ #

# ======================================================================== #
# Update Android SDKManager
RUN mkdir ~/.android && \
    echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg && \
    sdkmanager --update --sdk_root=${ANDROID_HOME}  && yes | sdkmanager --licenses --sdk_root=${ANDROID_HOME}

# Update SDK manager and install system image, platform and build tools
RUN sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "extras;android;m2repository" \
  "extras;google;m2repository" \
  "extras;google;google_play_services" \
  "build-tools;28.0.3" \
  "build-tools;29.0.2" \
  "build-tools;29.0.3" \
  --sdk_root=${ANDROID_HOME}
# ---------------------------------------------------------------------------- #
# ============================================================================ #
# Set the environment variables
ENV JAVA_HOME "/usr/lib/jvm/java-8-openjdk-amd64"
#COPY --chown=1000:1000 .bashrc $HOME_DIR

# ============================================================================ #
# Install Beyond Compare 4
# https://www.scootersoftware.com/download.php?zz=kb_linux_install
# RUN wget -q https://www.scootersoftware.com/bcompare-4.2.8.23479_amd64.deb -O bcompare.deb && \
#    sudo gdebi --non-interactive bcompare.deb &&\
#    rm bcompare.deb

# ---------------------------------------------------------------------------- #
# Git Configuration
COPY bashrc gitconfig ${BUILD_CFG}/

RUN cat ${BUILD_CFG}/bashrc >> ${HOME_DIR}/.bashrc && \
    mv ${BUILD_CFG}/gitconfig ${HOME_DIR}/.gitconfig

# ---------------------------------------------------------------------------- #
WORKDIR ${HOME_DIR}

ENTRYPOINT /bin/bash
