# set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
export CHANNEL_NAME=ctocchannel
export COMPOSE_PROJECT_NAME=ctocproject

toll_charges="toll_charges.json"
tags="tags.json"
index=$1
create_toll () {
    echo Starting TX i: $2
    local i=$1
    local toll_charge=$(echo -n $i | base64 | tr -d \\n)
    [[ ! -z "$DEBUG" ]] && echo $toll_charge
    docker exec cli peer chaincode invoke -o orderer.ruuftop.com:7050 \
    --peerAddresses peer0.tca.com:7051 \
    --peerAddresses peer0.bata.com:7051 \
    --peerAddresses peer0.sandag.com:7051 \
    -C ctocchannel -n ctoc_cc -c '{"Args":["addTollCharges"]}' --transient "{\"toll_charges\":\"$toll_charge\"}"
    echo Done TX i: $2
}

create_tags () {
    echo Starting Tag i: $2
    local i=$1
    local tag_status=$(echo -n $i | base64 | tr -d \\n)
    [[ ! -z "$DEBUG" ]] && echo $tag_status
    docker exec cli peer chaincode invoke -o orderer.ruuftop.com:7050 \
    --peerAddresses peer0.tca.com:7051 \
    --peerAddresses peer0.bata.com:7051 \
    --peerAddresses peer0.sandag.com:7051 \
    -C ctocchannel -n ctoc_cc -c '{"Args":["setTagStatus"]}' --transient "{\"tag_status\":\"$tag_status\"}"
    echo Done Tag i: $2
}
i=0
N=128

for row in $(jq -c ".[$index]" $tags); do 
    i=$((i+1))
    ((j=i%N)); ((j==0)) && wait
    create_tags $row $i &
done

wait

i=0

for row in $(jq -c ".[$index]" $toll_charges); do 
    i=$((i+1))
    ((j=i%N)); ((j==0)) && wait
    create_toll $row $i &
done

wait