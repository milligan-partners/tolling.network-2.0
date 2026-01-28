FROM sebp/elk:671
WORKDIR ${LOGSTASH_HOME}

RUN gosu logstash bin/logstash-plugin install logstash-input-couchdb_changes

ADD config/01-couchdb-input.conf /etc/logstash/conf.d/01-couchdb-input.conf
ADD config/30-output.conf /etc/logstash/conf.d/30-output.conf
