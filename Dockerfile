# Use the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.8

# Set environment variables for Spark and Hadoop versions
ARG SPARK_VERSION=3.5.3
ARG HADOOP_VERSION=3

# Install required dependencies and utilities
RUN yum update -y && \
    yum -y update zlib && \
    yum -y install wget && \
    yum -y install yum-plugin-versionlock && \
    yum -y versionlock add java-1.8.0-openjdk-1.8.0.362.b08-0.amzn2.0.1.x86_64 && \
    yum -y install java-1.8.0-openjdk && \
    yum -y install unzip && \
    yum -y install tar && \
    yum -y install procps && \
    yum clean all

# Set Java home environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.412.b08-1.amzn2.0.1.x86_64/jre
ENV PATH=$JAVA_HOME/bin:$PATH

# Remove any existing symlink and create a new one pointing to the correct java binary in JRE
RUN rm -f /usr/bin/java && \
    ln -s /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.412.b08-1.amzn2.0.1.x86_64/jre/bin/java /usr/bin/java

# Set Spark environment variables
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$JAVA_HOME/bin

# Export PYSPARK_PYTHON to specify the Python interpreter for PySpark
ENV PYSPARK_PYTHON=/var/lang/bin/python3

# Download and install Spark
RUN echo "Downloading Spark from: https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    wget https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -P /tmp && \
    tar -xzf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark && \
    rm -f /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Verify Spark installation and set necessary permissions
RUN ls -l /opt/spark

# Download the required Hadoop and AWS SDK JARs
RUN wget -P /opt/spark/jars https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar && \
    wget -P /opt/spark/jars https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.557/aws-java-sdk-bundle-1.12.557.jar

# Install PySpark using pip
RUN pip install pyspark==${SPARK_VERSION}

# spark-class file is setting the memory to 1 GB
COPY spark-class $SPARK_HOME/bin/
RUN chmod -R 755 $SPARK_HOME

# Set up the working directory for Lambda and copy the handler script
COPY sparkLambdaHandler.py /var/task/

# Set the CMD to the Lambda handler function
CMD ["sparkLambdaHandler.lambda_handler"]
