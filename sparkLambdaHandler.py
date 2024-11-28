import os
from pyspark.sql import SparkSession

def lambda_handler(event, context):
    try:
        # Set environment variables
        os.environ["JAVA_HOME"] = "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.412.b08-1.amzn2.0.1.x86_64/jre"
        os.environ["SPARK_HOME"] = "/opt/spark"
        os.environ["PYSPARK_PYTHON"] = "/var/lang/bin/python3.8"

        # Initialize SparkSession
        spark = SparkSession.builder \
            .appName("LambdaSparkExample") \
            .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
            .config("spark.hadoop.fs.s3a.endpoint", "s3.amazonaws.com") \
	        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "com.amazonaws.auth.DefaultAWSCredentialsProviderChain") \
            .config("spark.executor.memory", "1g") \
            .config("spark.driver.bindAddress", "127.0.0.1") \
            .config("spark.driver.memory", "1g") \
            .getOrCreate()

        print("Spark session initialized successfully.")

        # Example: Read data from S3
        input_s3_path = "s3a://soal-bucket/input-folder/"
        output_s3_path = "s3a://soal-bucket/output-folder/"
        print(f"Reading data from {input_s3_path}")
        df = spark.read.format("csv").option("header", "true").load(input_s3_path)

        # Perform a simple transformation
        df.printSchema()
        df.show()

        # Write transformed data back to S3
        print(f"Writing data to {output_s3_path}")
        df.write.mode("overwrite").format("parquet").save(output_s3_path)

        print("Data processing completed successfully.")
        return {
            "statusCode": 200,
            "body": "Data processing completed successfully."
        }

    except Exception as e:
        print(f"Error occurred: {e}")
        return {
            "statusCode": 500,
            "body": f"Error: {str(e)}"
        }

if __name__ == "__main__":
    # Simulate AWS Lambda event and context
    event = {}  # Replace with your test event if needed
    context = None  # Context is not necessary for local debugging

    # Call the handler directly for testing
    response = lambda_handler(event, context)
    print("Handler Response:", response)
