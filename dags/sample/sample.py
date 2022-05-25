from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.operators.python_operator import PythonOperator
from pyspark.sql import SparkSession

file_path = '/home/airflow/datalake/landing/sample/nyctaxitrip.csv'

############################################################################
### Read raw csv file and truncate to the first 1000 rows, save to new csv file
############################################################################

def load_data():
    spark = SparkSession.builder \
        .master("local[*]") \
        .appName("airflow_app") \
        .config('spark.executor.memory', '6g') \
        .config('spark.driver.memory', '6g') \
        .config("spark.driver.maxResultSize", "1048MB") \
        .config("spark.port.maxRetries", "100") \
        .getOrCreate()


    df = spark.read.options(inferSchema='true', header='true').csv('/home/airflow/datalake/landing/sample/sample.csv').limit(1000)
    df.write.mode('overwrite').csv(file_path,header='true')
    count = spark.sql(" SELECT COUNT(*) FROM csv. `{}` ".format(file_path)).collect()[0][0]
    print("====================================={} ROWS TRUNCATED AND LOADED to CSV ====================================".format(count))
    spark.sql(" SELECT * FROM csv. `{}` LIMIT 1000 ".format(file_path)).show(5,False)

############################################################################
### Convert truncated csv file to parquet format
############################################################################

def to_parquet():

    spark = SparkSession.builder \
        .master("local[*]") \
        .appName("airflow_app") \
        .getOrCreate()
    
    df = spark.read.options(inferSchema='true', header='true').csv(file_path)
    df.write.mode('overwrite').parquet("/home/airflow/datalake/landing/sample/NYC_trip.parquet")
    print("========================================SUCCESSFULLY CONVERTED TO PARQUET==================================================")

############################################################################
### Add new column whether dropoff location is JFK airport
############################################################################

def jfk_airport_trip():
    spark = SparkSession.builder \
        .master("local[*]") \
        .appName("airflow_app") \
        .getOrCreate()

    table_name = 'nyctaxi.test502'

    df = spark.read.options(inferSchema='true', header='true').csv(file_path)
    spark.sql("CREATE DATABASE IF NOT EXISTS nyctaxi")
    df.write.mode('overwrite').saveAsTable(table_name)
    
    # sql_boundary = """  SET max_Lat= '40.665189' ; \
    #                     SET min_Lat= '40.6630079'; \
    #                     SET min_Lon='-73.8086712'; \
    #                     SET max_Lon='-73.76153'  ; \
    #                 """
    
    # spark.sql(sql_boundary)

    sql_query = """ SELECT *, \
                    CASE WHEN ( '40.6630079' <= End_Lat <= '40.665189' AND '-73.8086712' <= End_Lon <= '-73.76153' ) THEN 'True' \
                         WHEN ( End_Lat IS NULL OR End_Lon IS NULL ) THEN NULL \
                         ELSE 'False' END AS JFK_airport \
                    FROM {}
                    ORDER BY JFK_airport DESC NULLS LAST; \
                """.format(table_name)
    print("=======================JFK_airport column added========================================")
    spark.sql(sql_query).show(10,False)



default_args = {
    'owner': 'Airflow',
    'email': ['your.email@domain.com'],
    'start_date': days_ago(1),
    'email_on_failure' : False
}

with DAG(
    dag_id = 'nyctaxi-dag',
    default_args = default_args,
    catchup=False,
    max_active_runs = 1,
    schedule_interval = None,
    tags=['ansarada']
) as dag:

    load_data = PythonOperator(
        task_id = 'load_data',
        python_callable = load_data
    )
    convert_to_parquet = PythonOperator(
        task_id = 'convert_to_parquet',
        python_callable = to_parquet
    )
    jfk_airport_trip = PythonOperator(
        task_id = 'jfk_airport_trip',
        python_callable = jfk_airport_trip
    )
load_data >> [convert_to_parquet,jfk_airport_trip]