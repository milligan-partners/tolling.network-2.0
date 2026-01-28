echo "{" > accountCount.json
printf "\"totalAccounts\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccounts", "A", "D"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"totalAccountValid\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsByStatus", "1"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"totalAccountInvalid\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsByStatus", "0"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json


printf "\"totalAccountsAgencyA\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccounts", "A", "B"]}' | awk '/Query Result:/ {printf $3}'>> accountCount.json
echo "," >> accountCount.json

printf "\"validAccountsAgencyA\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "A", "1"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"invalidAccountsAgencyA\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "A", "0"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"totalAccountsAgencyB\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccounts", "B", "C"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"validAccountsAgencyB\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "B", "1"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"invalidAccountsAgencyB\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "B", "0"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"totalAccountsAgencyC\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccounts", "C", "D"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"validAccountsAgencyC\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "C", "1"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
echo "," >> accountCount.json

printf "\"invalidAccountsAgencyC\":" >> accountCount.json
peer chaincode query -C channel1 -n cc -c '{"Args":["getTotalAccountsForAgencyByStatus", "C", "0"]}' | awk '/Query Result:/ {printf $3}' >> accountCount.json
#echo "," >> accountCount.json

echo "}" >> accountCount.json
