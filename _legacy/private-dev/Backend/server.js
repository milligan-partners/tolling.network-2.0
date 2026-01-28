const http = require('http');
const os = require('os');
const express = require("express");
const app = express();
const fs = require('fs');
const shell = require('shelljs');

const port = process.env.PORT || 8080;

process.on('SIGINT', function() {
  console.log('shutting down...');
  process.exit(1);
});

function welcome(req, res){
  res.json({
       message: "Welcome to tolling.network"
  });
  return;
}

function totalAccounts(req, res){
  let rawdata = fs.readFileSync("accountCount.json");
  let accountCount = {};
  accountCount = JSON.parse(rawdata);
  res.json({
      totalAccounts: accountCount.totalAccounts,
      totalAccountValid: accountCount.totalAccountValid,
      totalAccountInvalid: accountCount.totalAccountInvalid,
      totalAccountsAgencyA: accountCount.totalAccountsAgencyA,
      valdAccountsAgencyA: accountCount.valdAccountsAgencyA,
      invalidAccountsAgencyA: accountCount.invalidAccountsAgencyA,
      totalAccountsAgencyB: accountCount.totalAccountsAgencyB,
      valdAccountsAgencyB: accountCount.valdAccountsAgencyB,
      invalidAccountsAgencyB: accountCount.invalidAccountsAgencyB,
      totalAccountsAgencyC: accountCount.totalAccountsAgencyC,
      valdAccountsAgencyC: accountCount.valdAccountsAgencyC,
      invalidAccountsAgencyC: accountCount.invalidAccountsAgencyC,
  });
  return;
}

function networkOverview(req, res){
  let rawdata = fs.readFileSync("networkView.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({
      Transactions_today: netView.Transactions_today,
      Transactions_AgencyA: netView.Transactions_AgencyA,
      Transactions_AgencyB: netView.Transactions_AgencyB,
      Transactions_AgencyC: netView.Transactions_AgencyC,
      StatusUpdates_today: netView.StatusUpdates_today,
      StatusUpdates_AgencyA: netView.StatusUpdates_AgencyA,
      StatusUpdates_AgencyB: netView.StatusUpdates_AgencyB,
      StatusUpdates_AgencyC: netView.StatusUpdates_AgencyC,
      Current_Accounts: netView.Current_Accounts,
      Current_Accounts_A: netView.Current_Accounts_A,
      Current_Accounts_B: netView.Current_Accounts_B,
      Current_Accounts_C: netView.Current_Accounts_C,
      Transactions_Hour_AgencyA: netView.Transactions_Hour_AgencyA,
      Transactions_Hour_AgencyB: netView.Transactions_Hour_AgencyB,
      Transactions_Hour_AgencyC: netView.Transactions_Hour_AgencyC,
      Transactions_sent_AgencyA: netView.Transactions_sent_AgencyA,
      Transactions_sent_AgencyB: netView.Transactions_sent_AgencyB,
      Transactions_sent_AgencyC: netView.Transactions_sent_AgencyC,
      Transactions_received_AgencyA: netView.Transactions_received_AgencyA,
      Transactions_received_AgencyB: netView.Transactions_received_AgencyB,
      Transactions_received_AgencyC: netView.Transactions_received_AgencyC,
      Updates_By_AgencyA: netView.Updates_By_AgencyA,
      Updates_By_AgencyB: netView.Updates_By_AgencyB,
      Updates_By_AgencyC: netView.Updates_By_AgencyC
    });
  return;
}

function agencyviewA(req, res){
  let rawdata = fs.readFileSync("agencyViewA.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({
    Transactions_today: netView.Transactions_today,
    Transactions_sent: netView.Transactions_sent,
    Transactions_received: netView.Transactions_received,
    Status_Updates_Today: netView.Status_Updates_Today,
    NewAccount: netView.NewAccount,
    Status_change: netView.Status_change,
    Current_Accounts: netView.Current_Accounts,
    Active: netView.Active,
    Inactive: netView.Inactive,
    Transactions_Sent_Summary: netView.Transactions_Sent_Summary,
    Transactions_sentB: netView.Transactions_sentB,
    Transactions_sentC: netView.Transactions_sentC,
    Transactions_Received_Summary: netView.Transactions_Received_Summary,
    Transactions_receivedB: netView.Transactions_receivedB,
    Transactions_receivedC: netView.Transactions_receivedC,
    StatusUpdates_last30: netView.StatusUpdates_last30,
    Summary_by_Account1: netView.Summary_by_Account1,
    Summary_by_Account2: netView.Summary_by_Account2,
    Summary_by_Account3: netView.Summary_by_Account3

    //  Dates: netView.Dates
    });
  return;
}

function agencyviewB(req, res){
  let rawdata = fs.readFileSync("agencyViewB.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({
    Transactions_today: netView.Transactions_today,
    Transactions_sent: netView.Transactions_sent,
    Transactions_received: netView.Transactions_received,
    Status_Updates_Today: netView.Status_Updates_Today,
    NewAccount: netView.NewAccount,
    Status_change: netView.Status_change,
    Current_Accounts: netView.Current_Accounts,
    Active: netView.Active,
    Inactive: netView.Inactive,
    Transactions_Sent_Summary: netView.Transactions_Sent_Summary,
    Transactions_sentA: netView.Transactions_sentA,
    Transactions_sentC: netView.Transactions_sentC,
    Transactions_Received_Summary: netView.Transactions_Received_Summary,
    Transactions_receivedA: netView.Transactions_receivedA,
    Transactions_receivedC: netView.Transactions_receivedC,
    StatusUpdates_last30: netView.StatusUpdates_last30,
    Summary_by_Account1: netView.Summary_by_Account1,
    Summary_by_Account2: netView.Summary_by_Account2,
    Summary_by_Account3: netView.Summary_by_Account3
      //Dates: netView.Dates
    });
  return;
}

function agencyviewC(req, res){
  let rawdata = fs.readFileSync("agencyViewC.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({
    Transactions_today: netView.Transactions_today,
    Transactions_sent: netView.Transactions_sent,
    Transactions_received: netView.Transactions_received,
    Status_Updates_Today: netView.Status_Updates_Today,
    NewAccount: netView.NewAccount,
    Status_change: netView.Status_change,
    Current_Accounts: netView.Current_Accounts,
    Active: netView.Active,
    Inactive: netView.Inactive,
    Transactions_Sent_Summary: netView.Transactions_Sent_Summary,
    Transactions_sentA: netView.Transactions_sentA,
    Transactions_sentB: netView.Transactions_sentB,
    Transactions_Received_Summary: netView.Transactions_Received_Summary,
    Transactions_receivedA: netView.Transactions_receivedA,
    Transactions_receivedB: netView.Transactions_receivedB,
    StatusUpdates_last30: netView.StatusUpdates_last30,
    Summary_by_Account1: netView.Summary_by_Account1,
    Summary_by_Account2: netView.Summary_by_Account2,
    Summary_by_Account3: netView.Summary_by_Account3
      //Dates: netView.Dates
    });
  return;
}

function ledgerView(req, res){
  let rawdata = fs.readFileSync("ledgerView.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({
    Transactions_sent_AgencyA: netView.Transactions_sent_AgencyA,
    Transactions_received_AgencyA: netView.Transactions_received_AgencyA,
    Transactions_sent_AgencyB: netView.Transactions_sent_AgencyB,
    Transactions_received_AgencyB: netView.Transactions_received_AgencyB,
    Transactions_sent_AgencyC: netView.Transactions_sent_AgencyC,
    Transactions_received_AgencyC: netView.Transactions_sent_AgencyC,
    Transactions_last30_AgencyA: netView.Transactions_last30_AgencyA,
    Transactions_last30_AgencyB: netView.Transactions_last30_AgencyB,
    Transactions_last30_AgencyC:netView.Transactions_last30_AgencyC,
    Transactions_allTime_AgencyA: netView.Transactions_allTime_AgencyA,
    Transactions_allTime_AgencyB: netView.Transactions_allTime_AgencyB,
    Transactions_allTime_AgencyC: netView.Transactions_allTime_AgencyC,
    Transactions_allTime_A_B: netView.Transactions_allTime_A_B,
    Transactions_allTime_A_C: netView.Transactions_allTime_A_C,
    Transactions_allTime_B_C: netView.Transactions_allTime_B_C,
    MostRecent_Transaction1: netView.MostRecent_Transaction1,
    MostRecent_Transaction2: netView.MostRecent_Transaction2,
    MostRecent_Transaction3: netView.MostRecent_Transaction3,
    NewAccount_AgencyA: netView.NewAccount_AgencyA,
    StatusUpdate_AgencyA: netView.StatusUpdate_AgencyA,
    NewAccount_AgencyB: netView.NewAccount_AgencyB,
    StatusUpdate_AgencyB: netView.StatusUpdate_AgencyB,
    NewAccount_AgencyC:netView.NewAccount_AgencyC,
    StatusUpdate_AgencyC:netView.StatusUpdate_AgencyC,
    StatusUpdates_last30_AgencyA: netView.StatusUpdates_last30_AgencyA,
    StatusUpdates_last30_AgencyB: netView.StatusUpdates_last30_AgencyB,
    StatusUpdates_last30_AgencyC: netView.StatusUpdates_last30_AgencyC,
    StatusUpdates_allTime_AgencyA: netView.StatusUpdates_allTime_AgencyA,
    StatusUpdates_allTime_AgencyB: netView.StatusUpdates_allTime_AgencyB,
    StatusUpdates_allTime_AgencyC: netView.StatusUpdates_allTime_AgencyC,
    MostRecent_StatusUpdate1: netView.MostRecent_StatusUpdate1,
    MostRecent_StatusUpdate2: netView.MostRecent_StatusUpdate2,
    MostRecent_StatusUpdate3: netView.MostRecent_StatusUpdate3
      //Dates: netView.Dates
    });
  return;
}

function lastestAccountsA(req, res){
  let rawdata = fs.readFileSync("agencyAaccounts.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function lastestAccountsB(req, res){
  let rawdata = fs.readFileSync("agencyBaccounts.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function lastestAccountsC(req, res){
  let rawdata = fs.readFileSync("agencyCaccounts.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function lastestTransactionsA(req, res){
  let rawdata = fs.readFileSync("agencyAtransactions.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function lastestTransactionsB(req, res){
  let rawdata = fs.readFileSync("agencyBtransactions.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function lastestTransactionsC(req, res){
  let rawdata = fs.readFileSync("agencyCtransactions.json");
  let netView = {};
  netView = JSON.parse(rawdata);
  res.json({rows: netView.rows});

  return;
}

function runScripts(req, res){
    shell.exec('./networkView.sh',{shell: '/bin/bash'});
    shell.exec('./ledgerView.sh',{shell: '/bin/bash'});
    shell.exec('./AgencyViewA.sh',{shell: '/bin/bash'});
    shell.exec('./AgencyViewB.sh',{shell: '/bin/bash'});
    shell.exec('./AgencyViewC.sh',{shell: '/bin/bash'});

    console.log("success");

    res.json({
         message: "Data updated!"
    });

    return;
}

app.get("/", function(req, res){
    console.log("New Connection requested for Peer1 Org1!");
    welcome(req, res);
});

app.get("/currentAccounts", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    totalAccounts(req, res);
});

app.get("/networkView", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    networkOverview(req, res);
});

app.get("/agencyviewA", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    agencyviewA(req, res);
});

app.get("/agencyviewB", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    agencyviewB(req, res);
});

app.get("/agencyviewC", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    agencyviewC(req, res);
});

app.get("/ledgerView", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    ledgerView(req, res);
});

app.get("/lastestAccountsA", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestAccountsA(req, res);
});

app.get("/lastestAccountsB", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestAccountsB(req, res);
});

app.get("/lastestAccountsC", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestAccountsC(req, res);
});

app.get("/lastestTransactionsA", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestTransactionsA(req, res);
});

app.get("/lastestTransactionsB", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestTransactionsB(req, res);
});

app.get("/lastestTransactionsC", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    lastestTransactionsC(req, res);
});

app.get("/runScripts", function(req, res){
    //res.writeHead(200);
    console.log("Request for Total Accounts");
    runScripts(req, res);
});

/* start server */
app.listen(port, () => {
    console.log(`Server started at port: ${port}`);
});
