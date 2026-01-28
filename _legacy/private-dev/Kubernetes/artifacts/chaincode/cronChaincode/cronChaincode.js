/*
Add data to the State

===================== Add new Accounts ==============================
peer chaincode invoke -n cc -C channel1 -c '{"Args":["addAccount","C032699024","TX","3PCH418","A8-5F-E6-05-C3-4D","SCHJ.575596372","1"]}'
peer chaincode invoke -n cc -C channel1 -c '{"Args":["addAccount","A358036353","CA","1OXF345","F0-FD-A4-80-C3-43","BOMC.521511316","1"]}'
peer chaincode invoke -n cc -C channel1 -c '{"Args":["addAccount","B541007088","MI","7DWL777","B7-4A-52-7C-8F-42","OLYT.406781605","1"]}'


peer chaincode invoke -n cc -C channel1 -c '{"Args":["addAccountsCron","accounts30.json"]}'
peer chaincode invoke -n cc -C channel1 -c '{"Args":["addTransactionCron","accounts30.json"]}'

peer chaincode invoke -n cc -C channel1 -c '{"Args":["addAccountsCron_date","accounts100k.json","2018:12:07:02:25:00"]}'
peer chaincode invoke -n cc -C channel1 -c '{"Args":["addTransactionCron_date","accounts100k.json","2018-12-07","3:00"]}'
addAccountsCron_date
*/

const shim = require('fabric-shim');
const util = require('util');
const fs = require('fs');

var Chaincode = class {

  //  Standard function to Initialize the chaincode.
  /*
      Two variables are being added to the state.
      1. TRANSACTIONS - This keeps track of the number of transactions present in the ledger.
                        initialised with zero

      2. KRON - This keeps track of number of accounts added to the ledger from the accounts100k.json file.
                If KRON equals 30, it implies that 30,000 accounts have been added to the ledger from the accounts100k.json file.
                It is initialised with 30 as 30,000 accounts were added before this version of the chaincode was installed.
  */
  async Init (stub){
    console.info('=========== Initialize chaincode ===========');
    let allTransactions = {};
    allTransactions.totalTransactions = 52378;
    await stub.putState("TRANSACTIONS", Buffer.from(JSON.stringify(allTransactions)));

    let cron = {};
    cron.count = 92;
    await stub.putState("KRON", Buffer.from(JSON.stringify(cron)));

    return shim.success();
  }

 // Standard function to invoke the chaincode
  async Invoke(stub) {
    let ret = stub.getFunctionAndParameters();
    console.info(ret);
    let method = this[ret.fcn];
    if (!method) {
      console.log('no method of name:' + ret.fcn + ' found');
      return shim.success();
    }
    try {
      let payload = await method(stub, ret.params, this);
      return shim.success(payload);
    } catch (err) {
      console.log(err);
      return shim.error(err);
    }
   }

  // Adds a single account to the ledger.
  /*
  Expects accountID, license plate Jurisdiction, license plate Number, macAddress, tagID and accountStatus as inputs.
  This function also retrieves the current date time and attaches it to the account.
  */
  async addAccount (stub,args) {
    console.log('========Ledger Initialization========');

    // initialise only if 6 parameters passed.
    if (args.length != 6) {
      return shim.error('Incorrect number of arguments. Expecting 6');
    }
    let accountID = args[0];
    let lpJurisdiction = args[1];
    let lpNumber = args[2];
    let macAddress = args[3];
    let tagID = args[4];
    let accountStatus = args[5];


    let account = {};
    account.docType = 'account';
    account.accountID = accountID;
    account.lpJurisdiction = lpJurisdiction;
    account.lpNumber = lpNumber;
    account.macAddress = macAddress;
    account.tagID = tagID;
    account.accountStatus = accountStatus;
    account.parentAgency = args[0].substr(0,1);

    if(args[0].substr(0,1) == "A"){
      await stub.putState("lastUpdateA", account.accountID);
    } else if (args[0].substr(0,1) == "B") {
      await stub.putState("lastUpdateB", account.accountID);
    } else if (args[0].substr(0,1) == "C") {
      await stub.putState("lastUpdateC", account.accountID);
    } else {
      await stub.putState("faultAccount", account.accountID);
    }

    var date = new Date();

    var hour = date.getHours();
    hour = (hour < 10 ? "0" : "") + hour;

    var min  = date.getMinutes();
    min = (min < 10 ? "0" : "") + min;

    var sec  = date.getSeconds();
    sec = (sec < 10 ? "0" : "") + sec;

    var year = date.getFullYear();

    var month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;

    var day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;

    let date_ =  year + ":" + month + ":" + day + ":" + hour + ":" + min + ":" + sec;
    account.date_ = date_;

    await stub.putState(accountID, Buffer.from(JSON.stringify(account)));

    console.info('============= END : Added account ===========');

   }

    // Adds multiple accounts to the ledger by reading the data from a json file .
   /*
     Similar to addAccount but adds multiple accounts at the same time by reading from  a json file
   */
   async InitLedger (stub,args) {
    console.log('========Ledger Initialization========');
    let ret = stub.getFunctionAndParameters();
    console.info(ret);


    let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
    let account = {};
    account = JSON.parse(rawdata);

    var date = new Date();

    var hour = date.getHours();
    hour = (hour < 10 ? "0" : "") + hour;

    var min  = date.getMinutes();
    min = (min < 10 ? "0" : "") + min;

    var sec  = date.getSeconds();
    sec = (sec < 10 ? "0" : "") + sec;

    var year = date.getFullYear();

    var month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;

    var day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;

    let date_ =  year + ":" + month + ":" + day + ":" + hour + ":" + min + ":" + sec;

    let i;
    let key_;
    for(i=0;i<account.length;i++){
        account[i].date_ = date_;
        key_ = account[i].accountID;
        account[i].docType = 'account';
        account[i].parentAgency = key_.substr(0,1);

        await stub.putState(account[i].accountID, Buffer.from(JSON.stringify(account[i])));
    }
    console.info('============= END : Added account ===========');

  }

  // Toggles the account status of an account.
  async changeAccountStatus(stub, args) {
    console.info('============= START : changeAccountStatus ===========');
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let accountAsBytes = await stub.getState(args[0]);
    let account = JSON.parse(accountAsBytes);
    account.accountStatus = args[1];

    await stub.putState(args[0], Buffer.from(JSON.stringify(account)));
    console.info('============= END : changeAccountStatus ===========');
  }

 // retrieves a sinle account from the ledger.
  async queryAccount(stub, args) {
    if (args.length != 1) {
      throw new Error('Incorrect number of arguments. Expecting Account Id ex: C032699024');
    }
    let accountID = args[0];

    let accountAsBytes = await stub.getState(accountID); //get the account from chaincode state
    if (!accountAsBytes || accountAsBytes.toString().length <= 0) {
      throw new Error(accountID + ' does not exist: ');
    }
    console.log(accountAsBytes.toString());
    return accountAsBytes;
  }

  // Adds a sinle transaction to the ledger.
  /*
  expecting accountID, hostAgency, amount, dateTime, vehicleClass, location, transactionStatus.

  Whenever a new transaction is added, the key TRANSACTIONS in the ledger is incremented by 1.
  */
  async addTransaction(stub,args){

    if (args.length != 7) {
        return shim.error('Incorrect number of arguments. Expecting 7');
    }

    // account should exist in the Blockchain
    let accountAsBytes = await stub.getState(args[0]);
    if (!accountAsBytes || accountAsBytes.toString().length <= 0) {
      throw new Error(accountID + ' does not exist: ');
    }

    //Transaction sould not be older than 30 days
    var transaction_date = new Date(args[3]);
      var today = new Date();
      var timeDiff = Math.abs(today.getTime() - transaction_date.getTime());
      var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24));

      if(diffDays > 30){
        throw new Error('Cannot add transactions older than 30 days');
      }

    let staticTransactionAsBytes = await stub.getState("TRANSACTIONS");
    let staticTransactionAsJSON = JSON.parse(staticTransactionAsBytes.toString());
    console.info('============= total transactions so far ===========');
    console.log(staticTransactionAsJSON.totalTransactions);


    let transaction = {}
    transaction.docType = "Transaction";
    transaction.transactionID = staticTransactionAsJSON.totalTransactions + 1;
    transaction.accountID = args[0];
    transaction.hostAgency = args[1];
    transaction.parentAgency = args[0].substr(0,1);
    transaction.amount = args[2];
    transaction.date_ = args[3].substr(0,10); // get the date
    transaction.time_ = args[3].substr(11, ); // get the time
    transaction.vehicleClass = args[4]; // possible values: 2,3,4,5,6
    transaction.location = args[5];
    transaction.transactionStatus = args[6]; // possible values: unpaid, paid and dispute

    await stub.putState(transaction.transactionID.toString(), Buffer.from(JSON.stringify(transaction)));
    staticTransactionAsJSON.totalTransactions = transaction.transactionID;
    await stub.putState("TRANSACTIONS", Buffer.from(JSON.stringify(staticTransactionAsJSON)) );

    console.info('=============Transactions successfully added ===========');


  }

  /*********************************************
   CRON CHAINCODE FUNCTIONS
   1. addAccountsCron
   2. addTransactionCron

   These two functions consume the file accounts100k.json which contains 100k mock accounts.
  **********************************************/


  /*
   This fuction is used by the kubernetes CRON job to add new accounts to the ledger.
   Everytime the cron job runs, this function is adds 1000 new accounts to the ledger.
  */
  async addAccountsCron(stub, args) {
    console.log('========Adding 1000 accounts to ledger========');
    let ret = stub.getFunctionAndParameters();
    console.info(ret);


    let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
    let account = {};
    account = JSON.parse(rawdata);

    var date = new Date();

    var hour = date.getHours();
    hour = (hour < 10 ? "0" : "") + hour;

    var min  = date.getMinutes();
    min = (min < 10 ? "0" : "") + min;

    var sec  = date.getSeconds();
    sec = (sec < 10 ? "0" : "") + sec;

    var year = date.getFullYear();

    var month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;

    var day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;

    let date_ =  year + ":" + month + ":" + day + ":" + hour + ":" + min + ":" + sec;

    let staticCronAsBytes = await stub.getState("KRON");
    let staticCronAsJSON = JSON.parse(staticCronAsBytes.toString());

    //staticTransactionAsJSON.totalTransactions = transaction.transactionID;

    let start = staticCronAsJSON.count*1000;
    let stop = start + 999;
    let key_;

    for(let i=start;i<=stop;i++){
        account[i].date_ = date_;
        key_ = account[i].accountID;
        account[i].docType = 'account';
        account[i].parentAgency = key_.substr(0,1);

        await stub.putState(account[i].accountID, Buffer.from(JSON.stringify(account[i])));
    }
    staticCronAsJSON.count += 1;
    await stub.putState("KRON", Buffer.from(JSON.stringify(staticCronAsJSON)) );

    console.info('============= END : Added account ===========');
  }

  async addAccountsCron_date(stub, args) {
    console.log('========Adding 1000 accounts to ledger========');
    let ret = stub.getFunctionAndParameters();
    console.info(ret);


    let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
    let account = {};
    account = JSON.parse(rawdata);


    let date_ =  args[1];

    let staticCronAsBytes = await stub.getState("KRON");
    let staticCronAsJSON = JSON.parse(staticCronAsBytes.toString());

    //staticTransactionAsJSON.totalTransactions = transaction.transactionID;

    let start = staticCronAsJSON.count*1000;
    let stop = start + 999;
    let key_;

    for(let i=start;i<=stop;i++){
        account[i].date_ = date_;
        key_ = account[i].accountID;
        account[i].docType = 'account';
        account[i].parentAgency = key_.substr(0,1);

        await stub.putState(account[i].accountID, Buffer.from(JSON.stringify(account[i])));
    }
    staticCronAsJSON.count += 1;
    await stub.putState("KRON", Buffer.from(JSON.stringify(staticCronAsJSON)) );

    console.info('============= END : Added account ===========');
  }

  //Adds 35-45 random transactions.
  /*
   An account X is randomly picked from accounts100.json.
   A host agency Y is randomly picked for the above account (X).
   A transaction is eventually added for the account X by  the host agency Y.
  */
  async addTransactionCron(stub, args) {
    console.log('========Adding 1000 transactions to ledger========');
    let ret = stub.getFunctionAndParameters();
    console.info(ret);

    let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
    let account = {};
    account = JSON.parse(rawdata);

    var today = new Date();
    let transaction = {};

    let staticTransactionAsBytes = await stub.getState("TRANSACTIONS");
    let staticTransactionAsJSON = JSON.parse(staticTransactionAsBytes.toString());
    let totalTransactions =  staticTransactionAsJSON.totalTransactions;

    let staticCronAsBytes = await stub.getState("KRON");
    let staticCronAsJSON = JSON.parse(staticCronAsBytes.toString());

    var date = new Date();

    var hour = date.getHours();
    hour = (hour < 10 ? "0" : "") + hour;

    var minutes  = date.getMinutes();
    minutes = (minutes < 10 ? "0" : "") + minutes;

    var sec  = date.getSeconds();
    sec = (sec < 10 ? "0" : "") + sec;

    var year = date.getFullYear();

    var month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;

    var day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;

    let date_ =  year + "-" + month + "-" + day;
    let time_ = hour + ":" + minutes;




    let max = staticCronAsJSON.count*1000 + 999;
    let iMax = Math.floor(Math.random() * (46-35) + 35);



    for(let i=0; i<=iMax; i++)
    {
      //generate a random number between min and max
      let rand = Math.floor(Math.random() * (max-0) + 0);

      transaction.docType = "Transaction";
      transaction.transactionID = totalTransactions + 1;
      transaction.accountID = account[rand].accountID;
      transaction.hostAgency = "SIMULATE THIS";
      transaction.parentAgency = account[rand].accountID.substr(0,1);
      transaction.amount = 2;
      transaction.date_ = date_;
      transaction.time_ = time_;
      transaction.vehicleClass = Math.floor(Math.random() * (7-2) + 2); // generate a number between 2 and 6
      transaction.location = "loc1";
      transaction.transactionStatus = "unpaid";

      // Host agency simulation
      let rand_num =  Math.round(Math.random()) // generates a random number between 0 and 1.
      if(transaction.parentAgency == "A") {
        if(rand_num == 0){
          transaction.hostAgency = "B";
        }
        else {
          transaction.hostAgency = "C";
        }
      }
      else if(transaction.parentAgency == "B") {
        if(rand_num == 0){
          transaction.hostAgency = "A";
        }
        else {
          transaction.hostAgency = "C";
      }
     }
     else{
       if(rand_num == 0){
         transaction.hostAgency = "A";
       }
       else {
         transaction.hostAgency = "B";
       }
     }



      await stub.putState(transaction.transactionID.toString(), Buffer.from(JSON.stringify(transaction)));
      totalTransactions+=1;
    }

    staticTransactionAsJSON.totalTransactions=totalTransactions;
    await stub.putState("TRANSACTIONS", Buffer.from(JSON.stringify(staticTransactionAsJSON)) );

     console.info('=============Successfully added transactions===========');

  }

  async addTransactionCron_date(stub, args) {
    console.log('========Adding 1000 transactions to ledger========');
    let ret = stub.getFunctionAndParameters();
    console.info(ret);

    let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
    let account = {};
    account = JSON.parse(rawdata);

    var today = new Date();
    let transaction = {};

    let staticTransactionAsBytes = await stub.getState("TRANSACTIONS");
    let staticTransactionAsJSON = JSON.parse(staticTransactionAsBytes.toString());
    let totalTransactions =  staticTransactionAsJSON.totalTransactions;

    let staticCronAsBytes = await stub.getState("KRON");
    let staticCronAsJSON = JSON.parse(staticCronAsBytes.toString());


    let date_ =  args[1];
    let time_ = args[2];




    let max = staticCronAsJSON.count*1000 + 999;
    let iMax = Math.floor(Math.random() * (46-35) + 35);



    for(let i=0; i<=iMax; i++)
    {
      //generate a random number between min and max
      let rand = Math.floor(Math.random() * (max-0) + 0);

      transaction.docType = "Transaction";
      transaction.transactionID = totalTransactions + 1;
      transaction.accountID = account[rand].accountID;
      transaction.hostAgency = "SIMULATE THIS";
      transaction.parentAgency = account[rand].accountID.substr(0,1);
      transaction.amount = 2;
      transaction.date_ = date_;
      transaction.time_ = time_;
      transaction.vehicleClass = Math.floor(Math.random() * (7-2) + 2); // generate a number between 2 and 6
      transaction.location = "loc1";
      transaction.transactionStatus = "unpaid";

      // Host agency simulation
      let rand_num =  Math.round(Math.random()) // generates a random number between 0 and 1.
      if(transaction.parentAgency == "A") {
        if(rand_num == 0){
          transaction.hostAgency = "B";
        }
        else {
          transaction.hostAgency = "C";
        }
      }
      else if(transaction.parentAgency == "B") {
        if(rand_num == 0){
          transaction.hostAgency = "A";
        }
        else {
          transaction.hostAgency = "C";
      }
     }
     else{
       if(rand_num == 0){
         transaction.hostAgency = "A";
       }
       else {
         transaction.hostAgency = "B";
       }
     }



      await stub.putState(transaction.transactionID.toString(), Buffer.from(JSON.stringify(transaction)));
      totalTransactions+=1;
    }

    staticTransactionAsJSON.totalTransactions=totalTransactions;
    await stub.putState("TRANSACTIONS", Buffer.from(JSON.stringify(staticTransactionAsJSON)) );

     console.info('=============Successfully added transactions===========');

  }

  // Query a sinle transaction from the ledger.
  async queryTransaction(stub, args) {
    if (args.length != 1) {
      throw new Error('Incorrect number of arguments. Expecting transaction Id ex: 5');
    }
    let transactionID = args[0];

    let transactionAsBytes = await stub.getState(transactionID); //get the account from chaincode state
    if (!transactionAsBytes || transactionAsBytes.toString().length <= 0) {
      throw new Error(transactionID + ' does not exist: ');
    }
    console.log(transactionAsBytes.toString());
    return transactionAsBytes;
  }


  // ===== Example: Parameterized rich query =================================================
  // queryTransactionsByHost queries for transactions based on a passed in host agency.
  // This is an example of a parameterized query where the query logic is baked into the chaincode,
  // and accepting a single query parameter (host agency).
  // Only available on state databases that support rich query (e.g. CouchDB)
  // =========================================================================================

  // query the list of transactions for a given host
  async queryTransactionsByHost(stub, args, thisClass) {

    if (args.length < 1) {
      throw new Error('Incorrect number of arguments. Expecting host name.')
    }

    let hostAgency = args[0];
    let queryString = {};
    queryString.selector = {};
    queryString.selector.docType = 'Transaction';
    queryString.selector.hostAgency = hostAgency;
    let method = thisClass['getQueryResultForQueryString'];
    let queryResults = await method(stub, JSON.stringify(queryString), thisClass);

    const queryResultsArray = Object.keys(queryResults).map(i => queryResults[i]);

    console.info(queryResultsArray);

    let queryResultsAsJSON = JSON.parse(queryResults.toString());

    return queryResults; //shim.success(queryResults);
  }


  // ===== Example: Parameterized rich query =================================================
  // queryTransactionsByDate queries for transactions based on a Date.
  // This is an example of a parameterized query where the query logic is baked into the chaincode,
  // and accepting a single query parameter (host agency).
  // Only available on state databases that support rich query (e.g. CouchDB)
  // =========================================================================================

 // query the list of transactions for a given date
  async queryTransactionsByDate(stub, args, thisClass) {

    if (args.length < 1) {
      throw new Error('Incorrect number of arguments. Expecting Date.')
    }

    let date_ = args[0];
    let queryString = {};
    queryString.selector = {};
    queryString.selector.docType = 'Transaction';
    queryString.selector.date_ = date_;
    let method = thisClass['getQueryResultForQueryString'];
    let queryResults = await method(stub, JSON.stringify(queryString), thisClass);
    return queryResults; //shim.success(queryResults);
  }

  // ===== Example: Parameterized rich query =================================================
  // queryTransactionsByDate queries for transactions based on a Date.
  // This is an example of a parameterized query where the query logic is baked into the chaincode,
  // and accepting a single query parameter (host agency).
  // Only available on state databases that support rich query (e.g. CouchDB)
  // =========================================================================================

  // query list of transactions on a date by a host agency
  async queryTransactionsByAgencyDate(stub, args, thisClass) {

    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting host name, date.')
    }

    let hostAgency = args[0];
    let date_ = args[1];
    let queryString = {};
    queryString.selector = {};
    queryString.selector.docType = 'Transaction';
    queryString.selector.hostAgency = hostAgency;
    queryString.selector.date_ = date_;
    let method = thisClass['getQueryResultForQueryString'];
    let queryResults = await method(stub, JSON.stringify(queryString), thisClass);
    return queryResults; //shim.success(queryResults);
  }

  // =========================================================================================
  // getQueryResultForQueryString executes the passed in query string.
  // Result set is built and returned as a byte array containing the JSON results.
  // =========================================================================================

  // utility function
  async getQueryResultForQueryString(stub, queryString, thisClass) {

    console.info('- getQueryResultForQueryString queryString:\n' + queryString)
    let resultsIterator = await stub.getQueryResult(queryString);
    let method = thisClass['getAllResults'];

    let results = await method(resultsIterator, false);

    return Buffer.from(JSON.stringify(results));
  }

  // utility function
  async getAllResults(iterator, isHistory) {
    let allResults = [];
    while (true) {
      let res = await iterator.next();

      if (res.value && res.value.value.toString()) {
        let jsonRes = {};
        console.log(res.value.value.toString('utf8'));

        if (isHistory && isHistory === true) {
          jsonRes.TxId = res.value.tx_id;
          jsonRes.Timestamp = res.value.timestamp;
          jsonRes.IsDelete = res.value.is_delete.toString();
          try {
            jsonRes.Value = JSON.parse(res.value.value.toString('utf8'));
          } catch (err) {
            console.log(err);
            jsonRes.Value = res.value.value.toString('utf8');
          }
        } else {
          jsonRes.Key = res.value.key;
          try {
            jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
          } catch (err) {
            console.log(err);
            jsonRes.Record = res.value.value.toString('utf8');
          }
        }
        allResults.push(jsonRes);
      }
      if (res.done) {
        console.log('end of data');
        await iterator.close();
        console.info(allResults);
        return allResults;
      }
    }
  }

  // retrieves the history for an account
  async getHistoryforAccount(stub, args, thisClass) {

    if (args.length < 1) {
      throw new Error('Incorrect number of arguments. Expecting 1')
    }
    let accountID = args[0];
    console.info('- start getHistoryforAccount: %s\n',  accountID);

    let resultsIterator = await stub.getHistoryForKey(accountID);
    let method = thisClass['getAllResults'];
    let results = await method(resultsIterator, true);

    return Buffer.from(JSON.stringify(results));
  }

 // retrieves the history for a transaction
  async getHistoryforTransaction(stub, args, thisClass) {

    if (args.length < 1) {
      throw new Error('Incorrect number of arguments. Expecting 1')
    }
    let accountID = args[0];
    console.info('- start getHistoryforTransaction: %s\n',  accountID);

    let resultsIterator = await stub.getHistoryForKey(accountID);
    let method = thisClass['getAllResults'];
    let results = await method(resultsIterator, true);

    return Buffer.from(JSON.stringify(results));
  }

  // utility function
  async getkeysByRange(stub, args, thisClass) {

    if (args.length < 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let startKey = args[0];
    let endKey = args[1];
    //here we are calling a different function from the same class using this class (may be the same object too)
    // If start key and end key are null, all the keys present in the ledger are returned to the iterator.
    let resultsIterator = await stub.getStateByRange(startKey, endKey);
    let method = thisClass['getAllResults']; //storing the function in a variable
    let results = await method(resultsIterator, false); //calling that method using variable and arguments.
    console.info('- No of Accounts: %d\n',  results.length);
    return Buffer.from(JSON.stringify(results));
  }

  // Get count of accounts between a start and end key.
  async getTotalAccounts(stub, args, thisClass) {

    if (args.length < 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let startKey = args[0];
    let endKey = args[1];
    //here we are calling a different function from the same class using this class (may be the same object too)
    // If start key and end key are null, all the keys present in the ledger are returned to the iterator.
    let resultsIterator = await stub.getStateByRange(startKey, endKey);
    let method = thisClass['getAllResults']; //storing the function in a variable
    let results = await method(resultsIterator, false); //calling that method using variable and arguments.
    console.info('- No of Accounts: %d\n',  results.length);
    //let totalAccountsJSON = {};
    //totalAccountsJSON.totalAccounts = results.length;
    return Buffer.from(results.length.toString());
  }

  // query count  of valid and invalid accounts overall
  async getTotalAccountsByStatus(stub, args, thisClass) {

    if (args.length != 1) {
      throw new Error('Incorrect number of arguments. Expecting 1');
    }

    let accountStatus = args[0];

    let queryString = {};
    queryString.selector = {};

    queryString.selector.docType = 'account';
    queryString.selector.accountStatus = accountStatus;

    let method2 = thisClass['getQueryResultForQueryString'];
    let queryResults = await method2(stub, JSON.stringify(queryString), thisClass);

    let queryResultsAsJSON = JSON.parse(queryResults.toString());
    console.info('============= The number of transactions for this agenacy  on this date are: ===========');
    console.info(queryResultsAsJSON.length);

    return Buffer.from(queryResultsAsJSON.length.toString());

  }

  // query valid and invalid accounts for individual agencies
  async getTotalAccountsForAgencyByStatus(stub, args, thisClass) {

    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let parentAgency = args[0];
    let accountStatus = args[1];

    let queryString = {};
    queryString.selector = {};

    queryString.selector.docType = 'account';
    queryString.selector.parentAgency = parentAgency;
    queryString.selector.accountStatus = accountStatus;

    let method2 = thisClass['getQueryResultForQueryString'];
    let queryResults = await method2(stub, JSON.stringify(queryString), thisClass);

    let queryResultsAsJSON = JSON.parse(queryResults.toString());
    console.info('============= The number of transactions for this agenacy and status are: ===========');
    console.info(queryResultsAsJSON.length);

    return Buffer.from(queryResultsAsJSON.length.toString());

  }

  // query the total transactions
  async getTotalTransactions(stub) {
    let staticTransactionAsBytes = await stub.getState("TRANSACTIONS");
    let staticTransactionAsJSON = JSON.parse(staticTransactionAsBytes.toString());
    console.info('============= total transactions so far ===========');
    console.log(staticTransactionAsJSON.totalTransactions);

    return Buffer.from(JSON.stringify(staticTransactionAsJSON));
  }

  // query the account status updates in the last X days
  async queryAccountStatusUpdateCount(stub, args, thisClass) {
    // args[0] = "1" or "30". represents number of days

    if(args.length != 1){
      return shim.error("Incorrect number of arguments, expecting 1");
    }

    let days = parseInt(args[0]); //"1" or "30"

    //1. get a list of accounts
    let accountIterator = await stub.getStateByRange("A", "E");
    let method = thisClass['getAllResults'];
    let accounts = await method(accountIterator, false);

    let count = 0;
    let currTimestamp = Math.floor(Date.now() / 1000);
    let limit = 24 * 3600 * days;

    for(var i=0; i< accounts.length; i++){
      let accountID = accounts[i].Key;
      let historyIterator = await stub.getHistoryForKey(accountID);
      let method = thisClass['getAllResults'];
      let history = await method(historyIterator, true);

      for(var j=0; j<history.length; j++){
        let timestamp_ = parseInt(history[j].Timestamp.seconds.low);
        if(currTimestamp - timestamp_ < limit ){
          count += 1;
        }


      }
    }

    //let countASJSON = {};
    //countASJSON.count = count.toString();
    return Buffer.from(count.toString());



  }

  //input : Host Agency, Parent Agency.
  //query the amount that agency X owes agency Y.
  async queryAmountInvoiceUnpaid(stub, args, thisClass) {
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting host agency, parent agnecy.')
    }

    let hostAgency = args[0];
    let parentAgency = args[1];

    let queryString = {};
    queryString.selector = {};
    queryString.selector.docType = 'Transaction';
    queryString.selector.hostAgency = hostAgency;
    queryString.selector.parentAgency = parentAgency;
    queryString.selector.transactionStatus = 'unpaid';

    let method = thisClass['getQueryResultForQueryString'];
    let queryResults = await method(stub, JSON.stringify(queryString), thisClass);
    let queryResultsAsJSON = JSON.parse(queryResults.toString());

    let i=0;
    let amount = 0;
    while(i < queryResultsAsJSON.length){
      amount += Number(queryResultsAsJSON[i].Record.amount);
      console.info(amount);
      i+=1;
    }
    let fee = 0.08*amount;
    let invoice = amount - fee;

    let resultJSON = {};
    resultJSON.accounts = queryResultsAsJSON.length;
    resultJSON.amount = amount;
    resultJSON.fee = fee;
    resultJSON.invoice = invoice;
    resultJSON.Status = "unpaid";
    return Buffer.from(JSON.stringify(resultJSON));

  }

  //query the amount that agency X paid agency Y.
  async queryAmountInvoicePaid(stub, args, thisClass) {
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting host agency, parent agnecy.')
    }

    let hostAgency = args[0];
    let parentAgency = args[1];

    let queryString = {};
    queryString.selector = {};
    queryString.selector.docType = 'Transaction';
    queryString.selector.hostAgency = hostAgency;
    queryString.selector.parentAgency = parentAgency;
    queryString.selector.transactionStatus = 'paid';

    let method = thisClass['getQueryResultForQueryString'];
    let queryResults = await method(stub, JSON.stringify(queryString), thisClass);
    let queryResultsAsJSON = JSON.parse(queryResults.toString());

    let i=0;
    let amount = 0;
    while(i < queryResultsAsJSON.length){
      amount += Number(queryResultsAsJSON[i].Record.amount);
      console.info(amount);
      i+=1;
    }
    let fee = 0.08*amount;
    let invoice = amount - fee;

    let resultJSON = {};
    resultJSON.accounts = queryResultsAsJSON.length;
    resultJSON.amount = amount;
    resultJSON.fee = fee;
    resultJSON.invoice = invoice;
    resultJSON.Status = "paid";
    return Buffer.from(JSON.stringify(resultJSON));

  }

  // Toggles the date of an account.
  async changeAccountDate(stub, args) {
    console.info('============= START : change Account Date ===========');
    if (args.length != 3) {
      throw new Error('Incorrect number of arguments. Expecting 3');
    }
   // file name, kron number , new date.
   let ret = stub.getFunctionAndParameters();
   console.info(ret);

   let rawdata = fs.readFileSync(args[0]); //argument contains the file name to copy the data from.
   let account = {};
   account = JSON.parse(rawdata);


   let KRONN =  args[1];

   let date_ = args[2];

   //staticTransactionAsJSON.totalTransactions = transaction.transactionID;

   let start = KRONN*1000;
   let stop = start + 999;
   let key_;

   for(let i=start;i<=stop;i++){
       /*account[i].date_ = date_;
       key_ = account[i].accountID;
       account[i].docType = 'account';
       account[i].parentAgency = key_.substr(0,1);
      */
       let accountAsBytes = await stub.getState(account[i].accountID);
       let curr_account = JSON.parse(accountAsBytes);
       curr_account.date_ = date_;

       await stub.putState(curr_account.accountID, Buffer.from(JSON.stringify(curr_account)));
   }
   /*
    let accountAsBytes = await stub.getState(args[0]);
    let account = JSON.parse(accountAsBytes);
    account.accountStatus = args[1];
    */
    //await stub.putState(args[0], Buffer.from(JSON.stringify(account)));
    console.info('============= END : change account date ===========');
  }

  async updateCron(stub, args) {
    console.info('============= START : changeAccountStatus ===========');
    if (args.length != 1) {
      throw new Error('Incorrect number of arguments. Expecting 1');
    }

    let KRONAsBytes = await stub.getState("KRON");
    let KRON = JSON.parse(KRONAsBytes);
    KRON.count = parseInt(args[0]);

    await stub.putState("KRON", Buffer.from(JSON.stringify(KRON)));
    console.info('============= END : changeAccountStatus ===========');
  }

};

shim.start(new Chaincode());
