# Work explanation

1. **Prerequisite** \
You should have docker installed on your local machine

2. **How to see the result** \
Clone the repo to your local \
Run the command: `docker-compose up -d --build` \
Open web browser on: `http://localhost:8080/` \
You will see a job called `nyxtaxi_dag` \
Turn the job `OFF` --> `ON` \
You can trigger DAG to see the result again. \
I have named the task according to your question:
- convert to parquet (Convert CSV file to parquet format)
- jkf_airport_trip (Added column named JFK_airport (boolean) to check if drop-off location is JFK airport)

Task 1 answer parquet file can be found in datalake/landing/sample/NYC_trip.parquet \
Task 2 answer can be found under =====================JFK_airport column added====================== section in the `log`. \

3. **Work explaination**
Docker-Compose: 
- 1 Airflow Webserver + Scheduler (Local Executor) and 1 postgresSQL database (for Airflow). \

Dockerfile:
- Use wget download NYC dataset. 
- Build Airflow from Docker image
- Build and install Hadoop
- Build and install Spark 

4. **Additional Notes**
