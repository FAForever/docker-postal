FROM ruby:2.4

## Install nodejss
RUN apt-get -y update \
  && apt-get -y install nodejs mysql-client\
  && rm -rf /var/lib/apt/lists/*

## Install required gems
RUN gem install bundler && gem install procodile

## Create user for postal
RUN useradd -r -d /opt/postal -s /bin/bash postal

## Clone postal
RUN git clone https://github.com/atech/postal.git /opt/postal \
  && git --git-dir /opt/postal/.git checkout 83315f3a0006fd525b5b3f3ca664387cfcda2a81 \
  && chown -R postal:postal /opt/postal/

## Install gems required by postal
RUN /opt/postal/bin/postal bundle /opt/postal/vendor/bundle

## Move config folder
RUN mv /opt/postal/config /opt/postal/config-original

## Stick in startup script
ADD start.sh /start.sh
RUN chmod +x start.sh

## Expose
EXPOSE 5000

## Startup
CMD ["/start.sh"]
