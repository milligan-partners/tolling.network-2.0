#######get list of latest transactions added by agency######
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"A\"&limit=100&descending=true">agencyAtransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"B\"&limit=100&descending=true">agencyBtransactions.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestTransactions_DD/_view/transaction_detail?key=\"C\"&limit=100&descending=true">agencyCtransactions.json

#######get list of latest accounts added by agency######
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD2/_view/accounts_list?key=\"A\"&limit=100&descending=true" > agencyAaccounts.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD2/_view/accounts_list?key=\"B\"&limit=100&descending=true" > agencyBaccounts.json

curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD2/_view/accounts_list?key=\"C\"&limit=100&descending=true" > agencyCaccounts.json
