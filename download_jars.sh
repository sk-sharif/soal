#!/usr/bin/env bash

FRAMEWORK=$1
SPARK_HOME=$2
HADOOP_VERSION=$3
AWS_SDK_VERSION=$4
DELTA_FRAMEWORK_VERSION=$5

# Ensure directories exist
mkdir -p "${SPARK_HOME}/jars"
mkdir -p "${SPARK_HOME}/conf"

# Configure Spark environment
echo "SPARK_LOCAL_IP=0.0.0.0" > "${SPARK_HOME}/conf/spark-env.sh"
echo "JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm | grep java)/jre" >> "${SPARK_HOME}/conf/spark-env.sh"

# Add S3 configurations (AWS credentials should be handled by Lambda, no need to hardcode them)
echo "spark.hadoop.fs.s3.impl=org.apache.hadoop.fs.s3a.S3AFileSystem" >> "${SPARK_HOME}/conf/spark-env.sh"
echo "spark.hadoop.fs.s3a.endpoint=s3.amazonaws.com" >> "${SPARK_HOME}/conf/spark-env.sh"
echo "spark.hadoop.fs.s3a.connection.maximum=100" >> "${SPARK_HOME}/conf/spark-env.sh"

# Download Hadoop AWS JAR
HADOOP_AWS_VERSION="3.2.4"  # Update to a valid version
echo "Downloading Hadoop AWS JAR..."
wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar -P "${SPARK_HOME}/jars/"
if [ $? -ne 0 ]; then
  echo "Failed to download hadoop-aws-${HADOOP_AWS_VERSION}.jar. Exiting."
  exit 1
fi

# Download AWS SDK JAR
echo "Downloading AWS SDK JAR..."
wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar -P "${SPARK_HOME}/jars/"
if [ $? -ne 0 ]; then
  echo "Failed to download aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar. Exiting."
  exit 1
fi

# Download Delta JARs if framework is specified
IFS=',' read -ra FRAMEWORKS <<< "$FRAMEWORK"
for fw in "${FRAMEWORKS[@]}"; do
    case "$fw" in
        DELTA)
            echo "Downloading Delta Framework JARs..."
            wget -q https://repo1.maven.org/maven2/io/delta/delta-core_2.12/${DELTA_FRAMEWORK_VERSION}/delta-core_2.12-${DELTA_FRAMEWORK_VERSION}.jar -P "${SPARK_HOME}/jars/"
            if [ $? -ne 0 ]; then
                echo "Failed to download delta-core_2.12-${DELTA_FRAMEWORK_VERSION}.jar. Exiting."
                exit 1
            fi
            wget -q https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_FRAMEWORK_VERSION}/delta-storage-${DELTA_FRAMEWORK_VERSION}.jar -P "${SPARK_HOME}/jars/"
            if [ $? -ne 0 ]; then
                echo "Failed to download delta-storage-${DELTA_FRAMEWORK_VERSION}.jar. Exiting."
                exit 1
            fi
            ;;
        *)
            echo "Unknown framework: $fw"
            ;;
    esac
done

# Log downloaded JARs
echo "Downloaded JARs:"
ls -la "${SPARK_HOME}/jars/"
