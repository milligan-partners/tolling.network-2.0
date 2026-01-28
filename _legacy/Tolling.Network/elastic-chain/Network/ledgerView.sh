DATE=`date +%Y-%m-%d`
DATE2=`date +%Y:%m:%d`
echo "{" > ledgerView.json

Transactions_sent_AgencyA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received_AgencyA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today_AgencyA=$((Transactions_sent_AgencyA + Transactions_received_AgencyA))

printf "\"Transactions_today_AgencyA\":" >> ledgerView.json
printf $Transactions_today_AgencyA >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_sent_AgencyA\":" >> ledgerView.json
printf $Transactions_sent_AgencyA >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_received_AgencyA\":" >> ledgerView.json
printf $Transactions_received_AgencyA >> ledgerView.json
echo "," >> ledgerView.json

Transactions_sent_AgencyB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received_AgencyB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today_AgencyB=$((Transactions_sent_AgencyB + Transactions_received_AgencyB))

printf "\"Transactions_today_AgencyB\":" >> ledgerView.json
printf $Transactions_today_AgencyB >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_sent_AgencyB\":" >> ledgerView.json
printf $Transactions_sent_AgencyB >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_received_AgencyB\":" >> ledgerView.json
printf $Transactions_received_AgencyB >> ledgerView.json
echo "," >> ledgerView.json

Transactions_sent_AgencyC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_received_AgencyC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value')
Transactions_today_AgencyC=$((Transactions_sent_AgencyC + Transactions_received_AgencyC))

printf "\"Transactions_today_AgencyC\":" >> ledgerView.json
printf $Transactions_today_AgencyC >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_sent_AgencyC\":" >> ledgerView.json
printf $Transactions_sent_AgencyC >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_received_AgencyC\":" >> ledgerView.json
printf $Transactions_received_AgencyC >> ledgerView.json
echo "," >> ledgerView.json


DATE=`date +%Y-%m-%d`
counter=1

printf "\"Transactions_last30_AgencyA\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"Transactions\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

DATE=`date +%Y-%m-%d`
counter=1

printf "\"Transactions_last30_AgencyB\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"Transactions\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

DATE=`date +%Y-%m-%d`
counter=1

printf "\"Transactions_last30_AgencyC\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"Transactions\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
  fi
  ((counter++))
  DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_allTime_AgencyA\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency?key=\"A\" | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_allTime_AgencyB\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency?key=\"B\" | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

printf "\"Transactions_allTime_AgencyC\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency?key=\"C\" | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

AB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"A\",\"B\"] | jq  '.rows[0] .value')
BA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"B\",\"A\"] | jq  '.rows[0] .value')

printf "\"Transactions_allTime_A_B\":" >> ledgerView.json
printf $((AB+BA)) >> ledgerView.json
echo "," >> ledgerView.json

AC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"A\",\"C\"] | jq  '.rows[0] .value')
CA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"C\",\"A\"] | jq  '.rows[0] .value')

printf "\"Transactions_allTime_A_C\":" >> ledgerView.json
printf $((AC+CA)) >> ledgerView.json
echo "," >> ledgerView.json

BC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"B\",\"C\"] | jq  '.rows[0] .value')
CB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_received_agency?key=[\"C\",\"B\"] | jq  '.rows[0] .value')

printf "\"Transactions_allTime_B_C\":" >> ledgerView.json
printf $((BC+CB)) >> ledgerView.json
echo "," >> ledgerView.json

printf "\"MostRecent_Transaction1\":[" >> ledgerView.json
printf "\"C148626354\", \"C\", \"A\", \"2\", \"0.16\", \"1.84\", \"Unpaid\" " >> ledgerView.json
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"MostRecent_Transaction2\":[" >> ledgerView.json
printf "\"B780956727\", \"B\", \"A\", \"2\", \"0.16\", \"1.84\", \"Unpaid\" " >> ledgerView.json
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"MostRecent_Transaction3\":[" >> ledgerView.json
printf "\"A132241273\", \"A\", \"C\", \"2\", \"0.16\", \"1.84\", \"Unpaid\" " >> ledgerView.json
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"NewAccount_AgencyA\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"A\",\"$DATE2\"] | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

printf "\"StatusUpdate_AgencyA\":" >> ledgerView.json
echo "0" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"NewAccount_AgencyB\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"B\",\"$DATE2\"] | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

printf "\"StatusUpdate_AgencyB\":" >> ledgerView.json
echo "0" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"NewAccount_AgencyC\":" >> ledgerView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"$DATE2\"] | jq  '.rows[0] .value' >> ledgerView.json
echo "," >> ledgerView.json

printf "\"StatusUpdate_AgencyC\":" >> ledgerView.json
echo "0" >> ledgerView.json
echo "," >> ledgerView.json

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30_AgencyA\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"status_updates\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30_AgencyB\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"status_updates\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"B\",\"$DATE2\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

DATE2=`date +%Y:%m:%d`
DATE=`date +%Y-%m-%d`
counter=1

printf "\"StatusUpdates_last30_AgencyC\":[" >> ledgerView.json
  while(( counter!= 31)); do
   printf "{" >> ledgerView.json
   printf "\"Date\":" >> ledgerView.json
   printf "\"$DATE\"" >> ledgerView.json
   printf "," >> ledgerView.json
   printf "\"status_updates\":" >> ledgerView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"$DATE2\"]  | jq  '.rows[0] .value' >> ledgerView.json
   printf "}" >> ledgerView.json
   if (( counter!=30 )); then
    printf "," >> ledgerView.json
   fi
   ((counter++))
   DATE2=$(date +%Y:%m:%d -d "$DATE - 1 day")
   DATE=$(date +%Y-%m-%d -d "$DATE - 1 day")
 done
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

statusUpdates_allTime_AgencyA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"A\" | jq  '.rows[0] .value')
statusUpdates_allTime_AgencyB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"B\" | jq  '.rows[0] .value')
statusUpdates_allTime_AgencyC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"C\" | jq  '.rows[0] .value')
#statusUpdates_allTime_AgencyA=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/statusUpdates_agency_alltime?key=\"A\" | jq  '.rows[0] .value')
#statusUpdates_allTime_AgencyB=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/statusUpdates_agency_alltime?key=\"B\" | jq  '.rows[0] .value')
#statusUpdates_allTime_AgencyC=$(curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/statusUpdates_agency_alltime?key=\"C\" | jq  '.rows[0] .value')


printf "\"StatusUpdates_allTime_AgencyA\":" >> ledgerView.json
printf $statusUpdates_allTime_AgencyA >> ledgerView.json
echo "," >> ledgerView.json

printf "\"StatusUpdates_allTime_AgencyB\":" >> ledgerView.json
printf $statusUpdates_allTime_AgencyB >> ledgerView.json
echo "," >> ledgerView.json

printf "\"StatusUpdates_allTime_AgencyC\":" >> ledgerView.json
printf $statusUpdates_allTime_AgencyC >> ledgerView.json
echo "," >> ledgerView.json

DATE2=`date +%Y:%m:%d`

printf "\"MostRecent_StatusUpdate1\":[" >> ledgerView.json
printf "\"A\"," >> ledgerView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> ledgerView.json
printf ",\"New Account Added\"  " >> ledgerView.json
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"MostRecent_StatusUpdate2\":[" >> ledgerView.json
printf "\"B\"," >> ledgerView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"B\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> ledgerView.json
printf ",\"New Account Added\"  " >> ledgerView.json
printf "]" >> ledgerView.json
echo "," >> ledgerView.json

printf "\"MostRecent_StatusUpdate3\":[" >> ledgerView.json
printf "\"C\"," >> ledgerView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"C\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> ledgerView.json
printf ",\"New Account Added\"  " >> ledgerView.json
printf "]" >> ledgerView.json
#echo "," >> ledgerView.json










echo "}" >> ledgerView.json
