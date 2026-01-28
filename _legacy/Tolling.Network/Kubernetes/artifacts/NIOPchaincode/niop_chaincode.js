/*

*/

const shim = require('fabric-shim');
const util = require('util');
const fs = require('fs');

var agency_lookup = {
  'th': 'THEA',
  'tx': 'TxDOT',
  'hc': 'HCTRA',
  'nt': 'NTTA',
  'All agencies': 'xx'
}

var country_lookup = {
  'US': 'United States',
  'CA': 'Canada',
  'MX': 'Mexico',
  '-': 'Plate not in the referenced documentation'
}

var record_lookup = {
  'TB01A': 'Tag Toll - Barrier Type - Adjustment',
  'TC01A': 'Tag Toll - Closed Type - Adjustment',
  'TC02A': 'Tag Toll - Closed Unmatched Type - Adjustment',
  'VB01A': 'Video Toll - Barrier Type - Adjustment',
  'VC01A': 'Video Toll - Closed Type - Adjustment',
  'VC02A': 'Video Toll - Closed Unmatched Type - Adjustment'
}

var disposition_lookup = {
  'P': 'Posted successfully',
  'D': 'Duplicate transaction',
  'I': 'Invalid tag/plate',
  'N': 'Not posted',
  'S': 'System or communication issue',
  'T': 'Transaction content or format error',
  'C': 'Tag/plate not on file',
  'O': 'Transaction too old'
}

var return_lookup = {
  '00': 'Submission successfully received and verified',
  '01': 'Header record does not match detail records',
  '02': 'Detail record found with invalid data',
  '03': 'Sanity check failure',
  '04': 'Reconciliation data does not match transaction data',
  '05': 'Duplicate submission sequence number',
  '07': 'Invalid ZIP file or other file structure defect',
  '10': 'Second acknowledgement of the TVL',
  '11': 'Reconciliation calculations are incorrect',
  '12': 'File received late',
  '13': 'Date/time used for reconciliation reporting'
}
  
var Chaincode = class {

  // Initialize the chaincode
  async Init (stub){
    console.info('=========== Instantiated fabcar chaincode ===========');
  }

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

  async setTagValidation(stub,args){
    console.log('=====started adding Tag Validation record=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let tag = transient.get('tag_status');
    tag = JSON.parse(tag.toBuffer().toString());
    
    tag['tag_serial_number'] = encrypt(tag['tag_serial_number']);
    tag['LP_number'] = encrypt(tag['LP_number']);
    tag['account_id'] = encrypt(tag['account_id']);
    let date = new Date(tag['date'] + " " + tag['time']);
    tag['created_at'] = date
    tag['date'] = new Date(tag['date']);
    tag['date'] =  tag['date'].toISOString().split("T")[0];
    tag['LP_country'] = country_lookup[tag['LP_country']];
    tag['LP_state'] = state_lookup[tag['LP_state']];
    tag['home_agency_id'] = agency_lookup[tag['home_agency_id']];
    tag['tag_agency_id'] = agency_lookup[tag['tag_agency_id']];


    await stub.putPrivateData("tag_status", tag['tag_serial_number'], Buffer.from(JSON.stringify(tag)));
    await stub.putPrivateData("LP_number", tag['tag_serial_number'], Buffer.from(JSON.stringify(tag)));
    

    console.info('============= END : Added Tag Validation record ===========');
  }

  async addTransactionData(stub,args){
    console.log('=====started adding Transaction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let transaction_data = transient.get('transaction_data');
    transaction_data = JSON.parse(transaction_data.toBuffer().toString());
    let transaction_id = encrypt(transaction_data['transaction_id']);
    transaction_data['LP_number'] = encrypt(transaction_data['LP_number']);
    transaction_data['tag_status'] = encrypt(transaction_data['tag_status']);
    transaction_data['tag_serial_number'] = encrypt(transaction_data['tag_serial_number']);
    transaction_data['created_at'] = new Date(transaction_data['date'] + " " + transaction_data['time']);
    transaction_data['date'] = new Date(transaction_data['date']);
    transaction_data['date'] =  transaction_data['date'].toISOString().split("T")[0];
    
    /*
    transaction_data['record_type'] = record_lookup[transaction_data['record_type']];
    transaction_data['facility_ID'] = 
    transaction_data['facility_description'] = 
    transaction_data['discount'] = Number(transaction_data['discount']);
    transaction_data['invoice'] = toll_charges['amount'] - toll_charges['discount'];
    */
    transaction_data['amount'] = Number(transaction_data['amount'])
    transaction_data['tag_agency_id'] = agency_lookup[transaction_data['tag_agency_id']];
    transaction_data['exit_plaza'] = plaza_lookup[transaction_data['exit_plaza']];
    transaction_data['entry_plaza'] = plaza_lookup[transaction_data['entry_plaza']];
    let exit_plaza = transaction_data.exit_plaza.toLowerCase();
    let entry_plaza = transaction_data.entry_plaza.toLowerCase();
    transaction_data['LP_country'] = country_lookup[transaction_data['LP_country']];
    transaction_data['LP_state'] = state_lookup[transaction_data['LP_state']];

    try {
      let result = await stub.putPrivateData(entry_plaza + "_transaction_data_entry", transaction_id, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Entry");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData(exit_plaza + "_transaction_data_exit", transaction_id, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Exit");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData("report_transaction", transaction_id, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }

    console.info('============= END : Added Transaction ===========');
  }
  
  async addAdjustment(stub,args){
    console.log('=====started adding Adjustment/Correction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let adj_data = transient.get('adj_data');
    adj_data = JSON.parse(adj_data.toBuffer().toString());
    adj_data['record_type'] = record_lookup[adj_data['record_type']];
    /*
    adj_data['correction_reason'] = correction_lookup[adj_data['correction_reason']];
    adj_data['resubmit_reason'] = resubmit_lookup[adj_data['resubmit_reason']];
    */
    adj_data['correction_count'] = Number(adj_data['correction_count'])++;
    adj_data['resubmit_count'] = Number(adj_data['resubmit_count'])++;
    adj_data['from_agency'] = agency_lookup[adj_data['from_agency']];
    adj_data['to_agency'] = agency_lookup[adj_data['to_agency']];
    adj_data['created_at'] = new Date(adj_data['date'] + " " + adj_data['time']);
    adj_data['date'] = new Date(adj_data['date']);
    adj_data['date'] =  adj_data['date'].toISOString().split("T")[0];
    
    adj_data['amount'] = Number(adj_data['amount'])
    adj_data['tag_agency_id'] = agency_lookup[adj_data['tag_agency_id']];
    adj_data['exit_plaza'] = plaza_lookup[adj_data['exit_plaza']];
    adj_data['entry_plaza'] = plaza_lookup[adj_data['entry_plaza']];

    await stub.putState("adjustment_submission", adj_data['transaction_id'], Buffer.from(JSON.stringify(ack_data)));

    console.info('============= END : Added Adjustment/Correction ===========');
  }

  async addTransactionReconciliation(stub,args){
    console.log('=====started adding Reconciliation=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let recon_transaction_data = transient.get('recon_transaction_data');
    recon_transaction_data = JSON.parse(recon_transaction_data.toBuffer().toString());
    recon_transaction_data['transaction_id'] = encrypt(recon_transaction_data['transaction_id']);
    recon_transaction_data['agency_reference_id'] = encrypt(recon_transaction_data['agency_reference_id']);
    recon_transaction_data['adjustment_count'] = Number(recon_transaction_data['adjustment_count'])++;
    recon_transaction_data['resubmit_count'] = Number(recon_transaction_data['resubmit_count'])++;
    recon_transaction_data['recon_home_agency_ID'] = agency_lookup[recon_transaction_data['recon_home_agency_ID']];
    recon_transaction_data['posting_disposition'] = disposition_lookup[recon_transaction_data['posting_disposition']];
    recon_transaction_data['amount'] = Number(recon_transaction_data['amount'])
    
    /* recon_transaction_data['created_at'] = new Date(recon_transaction_data['date'] + " " + recon_transaction_data['time']);
    recon_transaction_data['date'] = new Date(recon_transaction_data['date']);
    recon_transaction_data['date'] = recon_transaction_data['date'].toISOString().split("T")[0];
    */

    await stub.putState(key, Buffer.from(JSON.stringify(recon_transaction_data)));

    console.info('============= END : Added Reconciliation ===========');
  }

  async addAcknowledgement(stub,args){
    console.log('=====started adding Tag Validation data=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let ack_data = transient.get('ack_data');
    ack_data = JSON.parse(ack_data.toBuffer().toString());
    ack_data['submission_type'] = 'ACK';
    ack_data['og_submission_type'] = submission_lookup[ack_data['submission_type']];
    ack_data['NIOP_hub_ID'] = hub_lookup[ack_data['NIOP_hub_ID']];
    ack_data['from_agency'] = agency_lookup[ack_data['from_agency']];
    ack_data['to_agency'] = agency_lookup[ack_data['to_agency']];
    ack_data['created_at'] = new Date(ack_data['date'] + " " + ack_data['time']);
    ack_data['date'] = new Date(ack_data['date']);
    ack_data['date'] =  ack_data['date'].toISOString().split("T")[0];
    ack_data['return_code'] = return_lookup[ack_data['return_code']];

    await stub.putState("report_submission", ack_data['return_code'], Buffer.from(JSON.stringify(ack_data)));

    console.info('============= END : Added Acknowledge ===========');
  }







};

shim.start(new Chaincode());
