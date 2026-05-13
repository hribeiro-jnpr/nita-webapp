# ********************************************************
#
# Project: nita-webapp
#
# Copyright (c) Juniper Networks, Inc., 2021. All rights reserved.
#
# Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html
#
# SPDX-License-Identifier: Apache-2.0
#
# Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.
#
# ********************************************************

FROM python:3.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV WEBAPP_USER vagrant
ENV WEBAPP_PASS vagrant123
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

WORKDIR /app

RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends \
		gcc \
		pkg-config \
		default-mysql-client \
		default-libmysqlclient-dev \
	&& rm -rf /var/lib/apt/lists/*

COPY nita-yaml-to-excel-22.8/ nita-yaml-to-excel-22.8/
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
	&& pip install --no-cache-dir -r requirements.txt

COPY nita.properties /etc/nita.properties

COPY build-and-test-webapp/ build-and-test-webapp/
RUN mkdir /var/log/nita-webapp
RUN touch /var/log/nita-webapp/server.log

LABEL net.juniper.framework="NITA"

EXPOSE 8000
