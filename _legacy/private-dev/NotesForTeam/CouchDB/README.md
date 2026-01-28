This document explains how to add new views to Couch DB  and use those views to retrieve data

Couch DB can be accessed from the peer using HTTP requests. CURL is one way to perform HTTP requests. So, I have installed CURL in the container using the below steps.

1. login to the peer1 of org1

   kubectl exec -it blockchain-org1peer1-7bcc8f8b5c-hbfrx -c org1peer1 bash

2. Install curl

   apt-get update

   apt-get install curl

3. I have also installed vi editor and jq

   apt-get install vim

   apt-get install jq

A couch DB design document could contain several views. I have added multiple design documents. The prominent ones are Accounts_DD(you can see this design document in accounts.json)  and  Transactions_DD3 (you can see this design document in transactions.json). Below are some of the commands to add and retrieve data from various views. This is not a complete list but I hope there are sufficient examples to get the general idea

# ACCOUNTS Desgin document
1. command to add the design document

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD --data-binary @accounts.json

2. get data for all agencies from that view

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/all

3. get data for single agency from that view

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"C\"

4. get data for single agency and single date from that view

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"2018:12:15\"]

# TRANSACTIONS Desgin document

1. command to add the design document

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD --data-binary @transactions.json

2. get count of transactions

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/all | jq  '.rows[0] .value'

3. get count of transactions on a date

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/all_date?key=\"2018-11-21\"

4. get count of transactions sent by agency

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency?key=\"A\"

5. get count of transactions received by agency

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency?key=\"B\"

6. get count of transactions sent by agency on a date

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"2018-11-21\"]

7. get count of transactions received by agency on a date

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"B\",\"2018-11-21\"]

8. get count of transactions sent paid or unpaid on date

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date_paid?key=[\"B\",\"2018-11-21\",\"unpaid\"]

9. get count of transactions received paid or unpaid on date

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date_paid?key=[\"B\",\"2018-11-21\",\"unpaid\"]

10. get count of transactions from Agency X to Agency Y

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"B\",\"A\"]

11. get transactions by hour and agency and date

 curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/transactions_agency_date_hour?key=[\"A\",\"2018-11-21\",\"9\"]

# MISCELLANEOUS
1. get list of design documents

curl -X GET http://127.0.0.1:5984/channel1_cc/_all_docs?startkey=\"_design/\"&endkey=\"_design0\"&include_docs=true






# Latest status update

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/ --data-binary @latestStatusUpdate.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD2/_view/all?descending=true"



1. get latest updated account for agency A

DATE2=`date +%Y:%m:%d`


curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value'

2. get list of latest accounts added by agency

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/accounts_list?key=\"A\"&limit=100&descending=true" > agencyAaccounts.json


curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/accounts_list?key=\"B\"&limit=100&descending=true" > agencyBaccounts.json


curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/accounts_list?key=\"C\"&limit=100&descending=true" > agencyCaccounts.json




#  latest transactions

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/ --data-binary @latestTransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/all?descending=true&limit=1"

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"A\"&limit=100&descending=true"

 1.get list of latest transactions added by agency

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"A\"&limit=100&descending=true">agencyAtransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"B\"&limit=100&descending=true">agencyBtransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"C\"&limit=100&descending=true">agencyCtransactions.json


curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/ --data-binary @latestTransactions.json


#  latest transactions by Agency

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/latestTransactionsAgency/ --data-binary @latestTransactionsAgency.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactionsAgency/_view/transaction_detail_A?limit=100&descending=true">agencyAtransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactionsAgency/_view/transaction_detail_B?limit=100&descending=true"

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactionsAgency/_view/transaction_detail_C?limit=100&descending=true"

#   transactions DD Latest
curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DDlatest/ --data-binary @latestTransactions2.json

1.get list of latest transactions added by agency

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DDlatest/_view/transaction_detail?key[\"A\",\"2019-02-07\"]

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DDlatest/_view/transaction_detail?key[\"A\"]


# Money Owed
curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/moneyOwed --data-binary @Money.json

1. get sum of amounts B gets from A (Money that A owes B)

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalAccounts?key=[\"B\",\"A\",\"unpaid\"]

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"B\",\"A\",\"unpaid\"]

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"B\",\"A\",\"unpaid\"]

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"B\",\"A\",\"unpaid\"]


# list accounts

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/listAccounts --data-binary @listAccounts.json

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/listAccounts/_list/result/all?key=\"2019:01:21:00:00:00\"

# list Transactions

curl -X PUT http://127.0.0.1:5984/channel1_cc/_design/listTransactions --data-binary @listTransactions.json

curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/listTransactions/_list/result/all?key=\"2019-01-21\"
