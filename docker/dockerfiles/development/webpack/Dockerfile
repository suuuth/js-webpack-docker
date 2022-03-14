# Node.js app Docker file
FROM node:9-stretch
RUN apt-get update && apt-get install -y \
        build-essential \
        libssl-dev \
        nodejs \
        git
RUN npm config set strict-ssl false
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
RUN npm install -g webpack
COPY start.sh /start.sh
CMD /start.sh
ENTRYPOINT "/start.sh"