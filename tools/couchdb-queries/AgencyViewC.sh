DATE=`date +%Y-%m-%d`
DATE2=`date +%Y:%m:%d`
echo "{" > agencyViewC.json

Transactions_sent=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today=$((Transactions_sent + Transactions_received))

NewAccount=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"$DATE2\"]| jq  '.rows[0] .value')
Status_change=0
Status_Updates_Today=$((NewAccount+Status_change))

Current_Accounts=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"C\"| jq  '.rows[0] .value')
Active=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"C\"| jq  '.rows[0] .value')
Inactive="0"

printf "\"Transactions_today\":" >> agencyViewC.json
printf $Transactions_today  >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Transactions_sent\":" >> agencyViewC.json
printf $Transactions_sent >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Transactions_received\":" >> agencyViewC.json
printf $Transactions_received >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Status_Updates_Today\":" >> agencyViewC.json
printf $Status_Updates_Today >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"NewAccount\":" >> agencyViewC.json
printf $NewAccount >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Status_change\":" >> agencyViewC.json
printf $Status_change >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Current_Accounts\":" >> agencyViewC.json
printf $Current_Accounts >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Active\":" >> agencyViewC.json
printf $Active >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Inactive\":" >> agencyViewC.json
printf $Inactive>> agencyViewC.json
echo "," >> agencyViewC.json



########################################################Transactions sent Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Sent_Summary\":[" >> agencyViewC.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewC.json
   printf "\"Date\":" >> agencyViewC.json
   printf "\"$DATE\"" >> agencyViewC.json
   printf "," >> agencyViewC.json
   printf "\"Transactions\":" >> agencyViewC.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewC.json
   printf "," >> agencyViewC.json
   printf "\"Transactions_Paid\":" >> agencyViewC.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date_paid?key=[\"C\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewC.json
   printf "}" >> agencyViewC.json
   if (( counter!=30 )); then
    printf "," >> agencyViewC.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewC.json
echo "," >> agencyViewC.json

########################################################Transactions between other agencies ########################################################

printf "\"Transactions_sentA\":" >> agencyViewC.json
printf "{" >> agencyViewC.json
printf "\"accounts\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"amount\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"fee\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"invoice\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"Status\":" >> agencyViewC.json
printf "\"unpaid"\" >> agencyViewC.json
printf "}," >> agencyViewC.json

printf "\"Transactions_sentB\":" >> agencyViewC.json
printf "{" >> agencyViewC.json
printf "\"accounts\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"amount\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"fee\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"invoice\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"C\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"Status\":" >> agencyViewC.json
printf "\"unpaid"\" >> agencyViewC.json
printf "}," >> agencyViewC.json
# printf "\"Transactions_sentA\":" >> agencyViewC.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "C", "A"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewC.json
# echo "," >> agencyViewC.json
#
# printf "\"Transactions_sentB\":" >> agencyViewC.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "C", "B"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewC.json
# echo "," >> agencyViewC.json



########################################################Transactions received Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Received_Summary\":[" >> agencyViewC.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewC.json
   printf "\"Date\":" >> agencyViewC.json
   printf "\"$DATE\"" >> agencyViewC.json
   printf "," >> agencyViewC.json
   printf "\"Transactions\":" >> agencyViewC.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"C\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewC.json
   printf "," >> agencyViewC.json
   printf "\"Transactions_Paid\":" >> agencyViewC.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date_paid?key=[\"C\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewC.json
   printf "}" >> agencyViewC.json
   if (( counter!=30 )); then
    printf "," >> agencyViewC.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewC.json
echo "," >> agencyViewC.json

########################################################Transactions between other agencies ########################################################

printf "\"Transactions_receivedA\":" >> agencyViewC.json
printf "{" >> agencyViewC.json
printf "\"accounts\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"amount\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"fee\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"invoice\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"Status\":" >> agencyViewC.json
printf "\"unpaid"\" >> agencyViewC.json
printf "}," >> agencyViewC.json

printf "\"Transactions_receivedB\":" >> agencyViewC.json
printf "{" >> agencyViewC.json
printf "\"accounts\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"amount\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"fee\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"invoice\":" >> agencyViewC.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"B\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewC.json
printf "," >> agencyViewC.json
printf "\"Status\":" >> agencyViewC.json
printf "\"unpaid"\" >> agencyViewC.json
printf "}," >> agencyViewC.json

# printf "\"Transactions_receivedA\":" >> agencyViewC.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "A", "C"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewC.json
# echo "," >> agencyViewC.json
#
# printf "\"Transactions_receivedB\":" >> agencyViewC.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "B", "C"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewC.json
# echo "," >> agencyViewC.json

########################################################Status update ########################################################

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30\":[" >> agencyViewC.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewC.json
   printf "\"Date\":" >> agencyViewC.json
   printf "\"$DATE\"" >> agencyViewC.json
   printf "," >> agencyViewC.json
   printf "\"status_updates\":" >> agencyViewC.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"$DATE2\"]  | jq  '.rows[0] .value' >> agencyViewC.json
   printf "}" >> agencyViewC.json
   if (( counter!=30 )); then
    printf "," >> agencyViewC.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewC.json
echo "," >> agencyViewC.json

#########################summary of accounts##########################

printf "\"Summary_by_Account1\":[" >> agencyViewC.json
printf "\"C191055322\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewC.json
printf "]" >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Summary_by_Account2\":[" >> agencyViewC.json
printf "\"C178210020\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewC.json
printf "]" >> agencyViewC.json
echo "," >> agencyViewC.json

printf "\"Summary_by_Account3\":[" >> agencyViewC.json
printf "\"C009107103\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewC.json
printf "]" >> agencyViewC.json
#echo "," >> agencyViewC.json

echo "}" >> agencyViewC.json
