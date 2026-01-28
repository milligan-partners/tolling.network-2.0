DATE=`date +%Y-%m-%d`
DATE2=`date +%Y:%m:%d`
echo "{" > agencyViewA.json

Transactions_sent=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today=$((Transactions_sent + Transactions_received))

NewAccount=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]| jq  '.rows[0] .value')
Status_change=0
Status_Updates_Today=$((NewAccount+Status_change))

Current_Accounts=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"A\"| jq  '.rows[0] .value')
Active=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"A\"| jq  '.rows[0] .value')
Inactive="0"

printf "\"Transactions_today\":" >> agencyViewA.json
printf $Transactions_today  >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Transactions_sent\":" >> agencyViewA.json
printf $Transactions_sent >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Transactions_received\":" >> agencyViewA.json
printf $Transactions_received >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Status_Updates_Today\":" >> agencyViewA.json
printf $Status_Updates_Today >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"NewAccount\":" >> agencyViewA.json
printf $NewAccount >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Status_change\":" >> agencyViewA.json
printf $Status_change >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Current_Accounts\":" >> agencyViewA.json
printf $Current_Accounts >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Active\":" >> agencyViewA.json
printf $Active >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Inactive\":" >> agencyViewA.json
printf $Inactive>> agencyViewA.json
echo "," >> agencyViewA.json



########################################################Transactions sent Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Sent_Summary\":[" >> agencyViewA.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewA.json
   printf "\"Date\":" >> agencyViewA.json
   printf "\"$DATE\"" >> agencyViewA.json
   printf "," >> agencyViewA.json
   printf "\"Transactions\":" >> agencyViewA.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewA.json
   printf "," >> agencyViewA.json
   printf "\"Transactions_Paid\":" >> agencyViewA.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date_paid?key=[\"A\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewA.json
   printf "}" >> agencyViewA.json
   if (( counter!=30 )); then
    printf "," >> agencyViewA.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewA.json
echo "," >> agencyViewA.json

########################################################Transactions between other agencies ########################################################

printf "\"Transactions_sentB\":" >> agencyViewA.json
printf "{" >> agencyViewA.json
printf "\"accounts\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"amount\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"fee\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"invoice\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"A\",\"B\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"Status\":" >> agencyViewA.json
printf "\"unpaid"\" >> agencyViewA.json
printf "}," >> agencyViewA.json

printf "\"Transactions_sentC\":" >> agencyViewA.json
printf "{" >> agencyViewA.json
printf "\"accounts\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"amount\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"fee\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"invoice\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"A\",\"C\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"Status\":" >> agencyViewA.json
printf "\"unpaid"\" >> agencyViewA.json
printf "}," >> agencyViewA.json




# printf "\"Transactions_sentB\":" >> agencyViewA.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "A", "B"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewA.json
# echo "," >> agencyViewA.json
#
# printf "\"Transactions_sentC\":" >> agencyViewA.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "A", "C"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewA.json
# echo "," >> agencyViewA.json



########################################################Transactions received Summary ########################################################

DATE=`date +%Y-%m-%d`
counter=1
printf "\"Transactions_Received_Summary\":[" >> agencyViewA.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewA.json
   printf "\"Date\":" >> agencyViewA.json
   printf "\"$DATE\"" >> agencyViewA.json
   printf "," >> agencyViewA.json
   printf "\"Transactions\":" >> agencyViewA.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"A\",\"$DATE\"]  | jq  '.rows[0] .value' >> agencyViewA.json
   printf "," >> agencyViewA.json
   printf "\"Transactions_Paid\":" >> agencyViewA.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date_paid?key=[\"A\",\"$DATE\",\"paid\"]  | jq  '.rows[0] .value' >> agencyViewA.json
   printf "}" >> agencyViewA.json
   if (( counter!=30 )); then
    printf "," >> agencyViewA.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewA.json
echo "," >> agencyViewA.json

########################################################Transactions between other agencies ########################################################
printf "\"Transactions_receivedB\":" >> agencyViewA.json
printf "{" >> agencyViewA.json
printf "\"accounts\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"amount\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"fee\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"invoice\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"B\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"Status\":" >> agencyViewA.json
printf "\"unpaid"\" >> agencyViewA.json
printf "}," >> agencyViewA.json

printf "\"Transactions_receivedC\":" >> agencyViewA.json
printf "{" >> agencyViewA.json
printf "\"accounts\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/totalTransactions?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"amount\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/amountOwed?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"fee\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/fee?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"invoice\":" >> agencyViewA.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/moneyOwed/_view/invoice?key=[\"C\",\"A\",\"unpaid\"] | jq  '.rows[0] .value' >> agencyViewA.json
printf "," >> agencyViewA.json
printf "\"Status\":" >> agencyViewA.json
printf "\"unpaid"\" >> agencyViewA.json
printf "}," >> agencyViewA.json

# printf "\"Transactions_receivedB\":" >> agencyViewA.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "B", "A"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewA.json
# echo "," >> agencyViewA.json
#
# printf "\"Transactions_receivedC\":" >> agencyViewA.json
# peer chaincode query -C channel1 -n cc -c '{"Args":["queryAmountInvoiceUnpaid", "C", "A"]}' | awk '/Query Result:/ {printf $3}' >> agencyViewA.json
# echo "," >> agencyViewA.json

########################################################Status update ########################################################

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30\":[" >> agencyViewA.json
  while(( counter!= 31)); do
   printf "{" >> agencyViewA.json
   printf "\"Date\":" >> agencyViewA.json
   printf "\"$DATE\"" >> agencyViewA.json
   printf "," >> agencyViewA.json
   printf "\"status_updates\":" >> agencyViewA.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]  | jq  '.rows[0] .value' >> agencyViewA.json
   printf "}" >> agencyViewA.json
   if (( counter!=30 )); then
    printf "," >> agencyViewA.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> agencyViewA.json
echo "," >> agencyViewA.json

#########################summary of accounts##########################

DATE2=`date +%Y:%m:%d`

printf "\"Summary_by_Account1\":[" >> agencyViewA.json
printf "\"A078434084\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewA.json
printf "]" >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Summary_by_Account2\":[" >> agencyViewA.json
printf "\"A055843399\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewA.json
printf "]" >> agencyViewA.json
echo "," >> agencyViewA.json

printf "\"Summary_by_Account3\":[" >> agencyViewA.json
printf "\"A464422240\", \"0\", \"21-Nov-2018\", \"1\"  " >> agencyViewA.json
printf "]" >> agencyViewA.json
#echo "," >> agencyViewA.json

echo "}" >> agencyViewA.json
