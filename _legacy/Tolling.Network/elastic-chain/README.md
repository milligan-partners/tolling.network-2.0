# elastic-chain

This repository contains the boilerplate code to generate a Hyperledge chaincode defined in the CTOCchaincode file.

All the services are containerized using docker and docker-compose.
If you are running this for the first time, make sure you follow the instructions to install Docker and Hyperledger in your machine:

- https://docs.docker.com/install/linux/docker-ce/ubuntu/
- https://docs.docker.com/compose/install/
- https://hyperledger-fabric.readthedocs.io/en/release-1.4/install.html

Python 3.5+ is also a requirement but it's usually bindles with most Linux/Mac Os distribution:
If that's not the case: https://tecadmin.net/install-python-3-5-on-ubuntu/

After you installed python, you will also need to install the dependencies

``` bash
    cd data_generation
    pip3 install -r requirements.txt
``` 

The first thing to do is to create the elk (Elastic-search, Kibana, Logstash) stack docker image.


``` bash
    cd ../elk
    docker build . -t elk
```

Then go back to the repo root and run the start.sh file. This will startup the chaincode, spawn 4 nodes and generate an small amount of data.

``` bash
    cd ../
    bash start.sh
```
If you need to generate more data, basically run the following command

``` bash
    bash data_generation/generate_data.sh <n_elements> <start_date> <end_date>
```
The following example will generate 1000 transaction between 5days ago and today 

``` bash
    bash data_generation/generate_data.sh 1000 -5d now
```

Be mindfull that inserting a lot of data can take a long time, so it's better to generate few examples and let the base grow organically over time.

Check if elastic search correctly indexed the data. If not, you may need to restart the elk container and wait few minutes

``` bash
    CHANNEL_NAME=ctocchannel, COMPOSE_PROJECT_NAME=ctocproject docker-compose restart elk
```

In order to config the data generation to create data every day, we will set a cronjob


``` bash
    crontab -e
```

A text editor will appear. Add the following line and them save the file

    0 0 * * * bash <path_to_repo>/data_generation/generate_data.sh 1000 -5d now

In order to use elastic search with Tableau, you need to configure Dremio.
You can use the queries created at http://104.154.229.199:9047/ as a reference. The user is milpar and the password is in LastPass folder "Shared-Tableau"

In the example, I added a new elastic search source with the following details

host: elk 
port: 9200

Dremio will pool the existing tables and adapt to the tabular format.
To share with Tableau, you will need to create an Space, add as many Datasets (basically a dataset is a view on the elasticsearch data) as it's necessary.

More on Dremio here: https://docs.dremio.com/working-with-datasets/concepts.html

