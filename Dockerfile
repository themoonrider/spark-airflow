# # DOWNLOAD RAW DATASET
# FROM ubuntu:18.04
# RUN apt-get install -y wget 
# RUN wget https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2009-12.csv -O /home/airflow/datalake/landing/sample/sample.csv


FROM apache/airflow:2.0.1
USER root
RUN apt-get update && apt-get install -y openjdk-11-jre-headless openjdk-11-jdk-headless ca-certificates-java curl

# INSTALL APACHE HADOOP
ENV JAVA_HOME "/usr/lib/jvm/java-11-openjdk-amd64"
ARG HADOOP_VERSION="3.2.1"
ENV HADOOP_HOME "/opt/hadoop"
RUN curl https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar xz -C /opt && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}
ENV HADOOP_COMMON_HOME "${HADOOP_HOME}"
ENV HADOOP_CLASSPATH "${HADOOP_HOME}/share/hadoop/tools/lib/*"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"
ENV PATH "$PATH:${HADOOP_HOME}/bin"
ENV HADOOP_OPTS "$HADOOP_OPTS -Djava.library.path=${HADOOP_HOME}/lib"
ENV HADOOP_COMMON_LIB_NATIVE_DIR "${HADOOP_HOME}/lib/native"
ENV YARN_CONF_DIR "${HADOOP_HOME}/etc/hadoop"

# INSTALL APACHE SPARK
ARG SPARK_VERSION="3.0.0"
ARG PY4J_VERSION="0.10.9"
ENV SPARK_HOME "/opt/spark"
RUN curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz \
    | tar xz -C /opt && mv /opt/spark-${SPARK_VERSION}-bin-without-hadoop ${SPARK_HOME}
ENV PATH "$PATH:${SPARK_HOME}/bin"
ENV LD_LIBRARY_PATH "${HADOOP_HOME}/lib/native"
ENV SPARK_DIST_CLASSPATH "${HADOOP_HOME}/etc/hadoop\
:${HADOOP_HOME}/share/hadoop/common/lib/*\
:${HADOOP_HOME}/share/hadoop/common/*\
:${HADOOP_HOME}/share/hadoop/hdfs\
:${HADOOP_HOME}/share/hadoop/hdfs/lib/*\
:${HADOOP_HOME}/share/hadoop/hdfs/*\
:${HADOOP_HOME}/share/hadoop/yarn/lib/*\
:${HADOOP_HOME}/share/hadoop/yarn/*\
:${HADOOP_HOME}/share/hadoop/mapreduce/lib/*\
:${HADOOP_HOME}/share/hadoop/mapreduce/*\
:${HADOOP_HOME}/share/hadoop/tools/lib/*\
:${HADOOP_HOME}/contrib/capacity-scheduler/*.jar"
ENV PYSPARK_PYTHON "/usr/local/bin/python"
ENV PYTHONPATH "${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-${PY4J_VERSION}-src.zip:${PYTHONPATH}"
ENV SPARK_OPTS "--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info"


# INSTALL LIBS
RUN pip install pyspark==3.0.0
RUN pip install findspark
USER airflow
WORKDIR /home/airflow


# DOWNLOAD RAW DATASET
FROM debian:8
RUN apt-get update && apt-get install -y wget 
RUN wget -O sample.csv -P /home/airflow/datalake/landing/sample https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2009-12.csv

USER airflow
WORKDIR /home/airflow