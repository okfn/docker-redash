FROM python:2

MAINTAINER Keitaro Inc <info@keitaro.info>

ENV TERM=xterm
ENV APP_DIR=/opt/redash
ENV REDASH_VERSION=0.12.0.b2256
ENV REDASH_RELEASE_URL=https://github.com/getredash/redash/releases/download/v0.12.0-rc/redash.${REDASH_VERSION}.tar.gz
ENV REDASH_STATIC_ASSETS_PATH="../rd_ui/dist/"

WORKDIR ${APP_DIR}

# Redash dependencies
RUN apt-get update && \
    apt-get install -y python-pip \
		       python-dev \
		       curl \
  		       build-essential \
	               pwgen \
		       libffi-dev \
	               sudo \
 	 	       git-core \
		       wget \
    		       libpq-dev \
                       libssl-dev \
		       libmysqlclient-dev \
	               freetds-dev \
		       libsasl2-dev && \
    curl https://deb.nodesource.com/setup_4.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create redash system user
RUN useradd --system --comment " " --create-home redash

# Download and setup redash release
RUN curl -SL ${REDASH_RELEASE_URL} | tar -xz && \
    pip install -U setuptools==23.1.0 && \
    pip install -r requirements_all_ds.txt && \
    pip install -r requirements.txt && \
    pip install -U requests && \
    pip install certbot && \
    sudo -u redash -H make deps && \
    rm -rf node_modules \
           rd_ui/node_modules \
           /home/redash/.npm \
           /home/redash/.cache && \
    apt-get purge -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chown -R redash /opt/redash

# Set user and expose port
USER redash
EXPOSE 5000

# Startup script
CMD ["gunicorn", "-b", "0.0.0.0:5000", "--name", "redash", "-w", "4", "--max-requests", "1000", "redash.wsgi:app"]
