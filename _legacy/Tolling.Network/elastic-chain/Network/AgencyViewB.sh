DATE=`date +%Y-%m-%d`
DATE2=`date +%Y:%m:%d`
echo "{" > agencyViewB.json

Transactions_sent=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today=$((Transactions_sent + Transactions_received))

NewAccount=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"B\",\"$DATE2\"]| jq  '.rows[0] .value')
Status_change=0
Status_Updates_Today=$((NewAccount+Status_change))

Current_Accounts=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"B\"| jq  '.rows[0] .value')
Active=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"B\"| jq  '.rows[0] .value')
Inactive="0"

printf "\"Transactions_today\":" >> agencyViewB.json
printf $Transactions_today  >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Transactions_sent\":" >> agencyViewB.json
printf $Transactions_sent >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Transactions_received\":" >> agencyViewB.json
printf $Transactions_received >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Status_Updates_Today\":" >> agencyViewB.json
printf $Status_Updates_Today >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"NewAccount\":" >> agencyViewB.json
printf $NewAccount >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Status_change\":" >> agencyViewB.json
printf $Status_change >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Current_Accounts\":" >> agencyViewB.json
printf $Current_Accounts >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Active\":" >> agencyViewB.json
printf $Active >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Inactive\":" >> agencyViewB.json
printf $Inactive>> agencyViewB.json
echo "," >> agencyViewB.json



########################################################Transactions sent Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Sent_Summary\":[" >> agencyViewB.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewB.json
   printf "\"Date\":" >> agencyViewB.json
   printf "\"$DATE\"" >> agencyViewB.json
   printf "," >> agencyViewB.json
   printf "\"Transactions\":" >> agencyViewB.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewB.json
   printf "," >> agencyViewB.json
   printf "\"Transactions_Paid\":" >> agencyViewB.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date_paid?key=[\"B\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewB.json
   printf "}" >> agencyViewB.json
   if (( counter!=30 )); then
    printf "," >> agencyViewB.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewB.json
echo "," >> agencyViewB.json

########################################################Transactions between other agencies ########################################################

printf "\"Transactions_sentA\":" >> agencyViewB.json
printf "{" >> agencyViewB.json
printf "\"accounts\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"amount\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"fee\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"invoice\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"Status\":" >> agencyViewB.json
printf "\"unpaid"\" >> agencyViewB.json
printf "}," >> agencyViewB.json

printf "\"Transactions_sentC\":" >> agencyViewB.json
printf "{" >> agencyViewB.json
printf "\"accounts\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"amount\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"fee\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"invoice\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"Status\":" >> agencyViewB.json
printf "\"unpaid"\" >> agencyViewB.json
printf "}," >> agencyViewB.json

# printf "\"Transactions_sentA\":" >> agencyViewB.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "B", "A"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewB.json
# echo "," >> agencyViewB.json
#
# printf "\"Transactions_sentC\":" >> agencyViewB.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "B", "C"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewB.json
# echo "," >> agencyViewB.json



########################################################Transactions received Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Received_Summary\":[" >> agencyViewB.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewB.json
   printf "\"Date\":" >> agencyViewB.json
   printf "\"$DATE\"" >> agencyViewB.json
   printf "," >> agencyViewB.json
   printf "\"Transactions\":" >> agencyViewB.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"B\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewB.json
   printf "," >> agencyViewB.json
   printf "\"Transactions_Paid\":" >> agencyViewB.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date_paid?key=[\"B\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewB.json
   printf "}" >> agencyViewB.json
   if (( counter!=30 )); then
    printf "," >> agencyViewB.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewB.json
echo "," >> agencyViewB.json

########################################################Transactions between other agencies ########################################################

printf "\"Transactions_receivedA\":" >> agencyViewB.json
printf "{" >> agencyViewB.json
printf "\"accounts\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"amount\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"fee\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"invoice\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"Status\":" >> agencyViewB.json
printf "\"unpaid"\" >> agencyViewB.json
printf "}," >> agencyViewB.json

printf "\"Transactions_receivedC\":" >> agencyViewB.json
printf "{" >> agencyViewB.json
printf "\"accounts\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"amount\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"fee\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"invoice\":" >> agencyViewB.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewB.json
printf "," >> agencyViewB.json
printf "\"Status\":" >> agencyViewB.json
printf "\"unpaid"\" >> agencyViewB.json
printf "}," >> agencyViewB.json
# printf "\"Transactions_receivedA\":" >> agencyViewB.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "A", "B"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewB.json
# echo "," >> agencyViewB.json
#
# printf "\"Transactions_receivedC\":" >> agencyViewB.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "C", "B"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewB.json
# echo "," >> agencyViewB.json

########################################################Status update ########################################################

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30\":[" >> agencyViewB.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewB.json
   printf "\"Date\":" >> agencyViewB.json
   printf "\"$DATE\"" >> agencyViewB.json
   printf "," >> agencyViewB.json
   printf "\"status_updates\":" >> agencyViewB.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"B\",\"$DATE2\"]  | jq  '.rows[0] .value' >> agencyViewB.json
   printf "}" >> agencyViewB.json
   if (( counter!=30 )); then
    printf "," >> agencyViewB.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewB.json
echo "," >> agencyViewB.json

#########################summary of accounts##########################

printf "\"Summary_by_Account1\":[" >> agencyViewB.json
printf "\"B490326284\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewB.json
printf "]" >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Summary_by_Account2\":[" >> agencyViewB.json
printf "\"B834436929\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewB.json
printf "]" >> agencyViewB.json
echo "," >> agencyViewB.json

printf "\"Summary_by_Account3\":[" >> agencyViewB.json
printf "\"B913274676\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewB.json
printf "]" >> agencyViewB.json
#echo "," >> agencyViewB.json

echo "}" >> agencyViewB.json
