module github.com/milligan-partners/tolling.network-2.0/chaincode/ctoc

go 1.22

require (
	github.com/hyperledger/fabric-chaincode-go v0.0.0-20240124143825-007f35e8ee1b
	github.com/hyperledger/fabric-contract-api-go v1.2.2
	github.com/hyperledger/fabric-protos-go-apiv2 v0.3.4
	github.com/milligan-partners/tolling.network-2.0/chaincode/shared v0.0.0
	github.com/stretchr/testify v1.9.0
)

replace github.com/milligan-partners/tolling.network-2.0/chaincode/shared => ../shared
