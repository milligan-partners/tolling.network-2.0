DATE=`date +%Y-%m-%d`
DATE2=`date +%Y:%m:%d`

echo "{" > networkView.json
printf "\"Transactions_today\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/all_date?key=\"$DATE\" | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_AgencyA\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_AgencyB\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_AgencyC\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"StatusUpdates_today\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/date?key=\"$DATE2\" | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"StatusUpdates_AgencyA\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"A\",\"$DATE2\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"StatusUpdates_AgencyB\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"B\",\"$DATE2\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"StatusUpdates_AgencyC\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency_date?key=[\"C\",\"$DATE2\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Current_Accounts\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/all | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Current_Accounts_A\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"A\" | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Current_Accounts_B\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"B\" | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Current_Accounts_C\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Accounts_DD/_view/agency?key=\"C\" | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

declare -a arr=("00:00" "01:00" "02:00" "03:00" "04:00" "05:00" "06:00" "07:00" "08:00" "09:00" "10:00" "11:00" "12:00" "13:00" "14:00" "15:00" "16:00" "17:00" "18:00" "19:00" "20:00" "21:00" "22:00" "23:00")
counter=0

printf "\"Transactions_Hour_AgencyA\":[" >> networkView.json
  for i in "${arr[@]}";
  do
   printf "{" >> networkView.json
   printf "\"Hour\":" >> networkView.json
   printf "\"$counter\"" >> networkView.json
   printf "," >> networkView.json
   printf "\"Transactions\":" >> networkView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/transactions_agency_date_hour?key=[\"A\",\"$DATE\",\"$i\"] | jq  '.rows[0] .value' >> networkView.json
   printf "}" >> networkView.json
   if (( counter!=23 )); then
    printf "," >> networkView.json
  fi
  ((counter++))
 done
printf "]" >> networkView.json
echo "," >> networkView.json

counter=0

printf "\"Transactions_Hour_AgencyB\":[" >> networkView.json
  for i in "${arr[@]}";
  do
   printf "{" >> networkView.json
   printf "\"Hour\":" >> networkView.json
   printf "\"$counter\"" >> networkView.json
   printf "," >> networkView.json
   printf "\"Transactions\":" >> networkView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/transactions_agency_date_hour?key=[\"B\",\"$DATE\",\"$i\"] | jq  '.rows[0] .value' >> networkView.json
   printf "}" >> networkView.json
   if (( counter!=23 )); then
    printf "," >> networkView.json
  fi
  ((counter++))
 done
printf "]" >> networkView.json
echo "," >> networkView.json

counter=0

printf "\"Transactions_Hour_AgencyC\":[" >> networkView.json
  for i in "${arr[@]}";
  do
   printf "{" >> networkView.json
   printf "\"Hour\":" >> networkView.json
   printf "\"$counter\"" >> networkView.json
   printf "," >> networkView.json
   printf "\"Transactions\":" >> networkView.json
   curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/transactions_agency_date_hour?key=[\"C\",\"$DATE\",\"$i\"] | jq  '.rows[0] .value' >> networkView.json
   printf "}" >> networkView.json
   if (( counter!=23 )); then
    printf "," >> networkView.json
  fi
  ((counter++))
 done
printf "]" >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_sent_AgencyA\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_received_AgencyA\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"A\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_sent_AgencyB\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_received_AgencyB\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"B\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_sent_AgencyC\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/sent_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Transactions_received_AgencyC\":" >> networkView.json
curl -g -X GET http://127.0.0.1:5984/channel1_cc/_design/Transactions_DD/_view/received_agency_date?key=[\"C\",\"$DATE\"] | jq  '.rows[0] .value' >> networkView.json
echo "," >> networkView.json

printf "\"Updates_By_AgencyA\":[" >> networkView.json
printf "{" >> networkView.json
printf "\"Last_Update\":" >> networkView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"A\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> networkView.json
printf "}" >> networkView.json
printf "," >> networkView.json
printf "{" >> networkView.json
printf "\"Type_of_Update\":" >> networkView.json
printf "\"New Account Added\"" >> networkView.json
printf "}" >> networkView.json
printf "]" >> networkView.json
echo "," >> networkView.json

printf "\"Updates_By_AgencyB\":[" >> networkView.json
printf "{" >> networkView.json
printf "\"Last_Update\":" >> networkView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"B\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> networkView.json
printf "}" >> networkView.json
printf "," >> networkView.json
printf "{" >> networkView.json
printf "\"Type_of_Update\":" >> networkView.json
printf "\"New Account Added\"" >> networkView.json
printf "}" >> networkView.json
printf "]" >> networkView.json
echo "," >> networkView.json

printf "\"Updates_By_AgencyC\":[" >> networkView.json
printf "{" >> networkView.json
printf "\"Last_Update\":" >> networkView.json
curl -g -X GET "http://127.0.0.1:5984/channel1_cc/_design/latestStatusUpdate_DD/_view/agency_date?key=[\"C\",\"$DATE2\"]&limit=1"| jq  '.rows[0] .value' >> networkView.json
printf "}" >> networkView.json
printf "," >> networkView.json
printf "{" >> networkView.json
printf "\"Type_of_Update\":" >> networkView.json
printf "\"New Account Added\"" >> networkView.json
printf "}" >> networkView.json
printf "]" >> networkView.json


echo "}" >> networkView.json
