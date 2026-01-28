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

  async setTagStatus(stub,args){
    console.log('=====started setting Tag Status record=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let tag = transient.get('tag_status');
    tag = JSON.parse(tag.toBuffer().toString());
    
    tag['tag_serial_number'] = encrypt(tag['tag_serial_number']);
    tag['agency_id'] = Number(tag['agency_id'])
    tag['tag_status'] = status_lookup[tag['tag_status']];
    let tag_acct_info = tag['tag_acct_info'];


    await stub.putPrivateData("tag_serial_number", tag['tag_serial_number'], Buffer.from(JSON.stringify(tag)));
    

    console.info('============= END : Set Tag Status record ===========');
  }
  
  async tagStatusUpdate(stub,args){
    console.log('=====started setting Tag Status update=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let tag = transient.get('tag_status');
    tag = JSON.parse(tag.toBuffer().toString());
    
    tag['tag_serial_number'] = encrypt(tag['tag_serial_number']);
    tag['agency_id'] = Number(tag['agency_id'])
    tag['tag_status'] = status_lookup[tag['tag_status']];
    let tag_acct_info = tag['tag_acct_info'];
    tag['created_at'] = new Date(tag['date'] + " " + tag['time']);
    tag['date'] = new Date(tag['date']);
    tag['date'] =  tag['date'].toISOString().split("T")[0];


    await stub.putPrivateData("tag_serial_number", tag['tag_serial_number'], Buffer.from(JSON.stringify(tag)));
    

    console.info('============= END : Set Tag Status record ===========');
  }
  
  async invalidTagCustomer(stub,args){
    console.log('=====started Invalid Tag Customer update=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let invalid_tag = transient.get('tag_status');
    invalid_tag = JSON.parse(invalid_tag.toBuffer().toString());
    
    invalid_tag['tag_serial_number'] = encrypt(invalid_tag['tag_serial_number']);
    invalid_tag['agency_id'] = Number(invalid_tag['agency_id'])
    invalid_tag['tag_status'] = status_lookup[invalid_tag['tag_status']];
    invalid_tag['cust_last_name'] = encrypt(invalid_tag['cust_last_name']);
    invalid_tag['cust_first_name'] = encrypt(invalid_tag['cust_first_name']);
    invalid_tag['cust_company'] = encrypt(invalid_tag['cust_company']);
    invalid_tag['cust_addr'] = encrypt(invalid_tag['cust_addr']);
    invalid_tag['cust_state'] = encrypt(invalid_tag['cust_state']);
    invalid_tag['cust_zip'] = encrypt(invalid_tag['cust_zip']);


    await stub.putPrivateData("tag_serial_number", tag['tag_serial_number'], Buffer.from(JSON.stringify(tag)));
    

    console.info('============= END : Set Tag Status record ===========');
  }

  async addTransactionData(stub,args){
    console.log('=====started adding Transaction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let transaction_data = transient.get('transaction_data');
    transaction_data = JSON.parse(transaction_data.toBuffer().toString());
    
    let transaction_serial_number = encrypt(transaction_data['transaction_serial_number']);
    transaction_data['created_at'] = new Date(transaction_data['date'] + " " + transaction_data['time']);
    transaction_data['date'] = new Date(transaction_data['date']);
    transaction_data['date'] =  transaction_data['date'].toISOString().split("T")[0];
    transaction_data['facility_ID'] = facility_lookup[transaction_data['facility_ID']];
    transaction_data['transaction_type'] = trxtype_lookup[transaction_data['transaction_type']];
    transaction_data['exit_plaza'] = plaza_lookup[transaction_data['exit_plaza']];
    transaction_data['entry_plaza'] = plaza_lookup[transaction_data['entry_plaza']];
    let exit_plaza = transaction_data.exit_plaza.toLowerCase();
    let entry_plaza = transaction_data.entry_plaza.toLowerCase();
    transaction_data['tag_agency_id'] = agency_lookup[transaction_data['tag_agency_id']];
    transaction_data['tag_serial_number'] = Number(transaction_data['tag_serial_number']);
    transaction_data['read_performance'] = Number(transaction_data['read_performance']);
    transaction_data['write_performance'] = Number(transaction_data['write_performance']);
    transaction_data['tag_pgm_status'] = pgm_status_lookup[transaction_data['tag_pgm_status']];
    transaction_data['lane_mode'] = mode_lookup[transaction_data['lane_mode']];
    transaction_data['validation_status'] = validation_status_lookup[transaction_data['validation_Status']];
    transaction_data['LP_state'] = state_lookup[transaction_data['LP_state']];
    transaction_data['LP_number'] = encrypt(transaction_data['LP_number']);
    transaction_data['class_charged'] = class_lookup[transaction_data['class_charged']];
    transaction_data['actual_axles'] = Number(transaction_data['actual_axles']);
    transaction_data['debit_credit'] = dc_lookup[transaction_data['debit_credit']];
    transaction_data['toll_amount'] = Number(transaction_data['toll_amount']);
    

    try {
      let result = await stub.putPrivateData(entry_plaza + "_transaction_data_entry", transaction_serial_number, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Entry");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData(exit_plaza + "_transaction_data_exit", transaction_serial_number, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Exit");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData("report_transaction", transaction_serial_number, Buffer.from(JSON.stringify(transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }

    console.info('============= END : Added Transaction ===========');
  }
  
  async transactionRecon(stub,args){
    console.log('=====started Transaction Reconciliation=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let transaction_recon = transient.get('transaction_recon');
    transaction_recon = JSON.parse(transaction_recon.toBuffer().toString());
    let transaction_serial_number = encrypt(transaction_recon['transaction_serial_number']);
    
    transaction_recon['post_status'] = post_status_lookup[transaction_recon['post_status']];
    transaction_recon['post_plan'] = post_plan_lookup[transaction_recon['post_plan']];
    transaction_recon['debit_credit'] = dc_lookup[transaction_recon['debit_credit']];
    transaction_recon['owed_amount'] = Number(transaction_recon['owed_amount']);


    await stub.putPrivateData("transaction_serial_number", transaction_recon['transaction_serial_number'], Buffer.from(JSON.stringify(transaction_recon)));
    

    console.info('============= END : Set Transaction reconciliation record ===========');
  }
  
  async correctionFile(stub,args){
    console.log('=====started Correction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let correction = transient.get('correction');
    correction = JSON.parse(correction.toBuffer().toString());
    let corr_reason = encrypt(correction['corr_reason']);
    
    let transaction_serial_number = encrypt(correction['transaction_serial_number']);
    correction['created_at'] = new Date(correction['date'] + " " + correction['time']);
    correction['date'] = new Date(correction['date']);
    correction['date'] =  correction['date'].toISOString().split("T")[0];
    correction['facility_ID'] = facility_lookup[correction['facility_ID']];
    correction['transaction_type'] = trxtype_lookup[correction['transaction_type']];
    correction['exit_plaza'] = plaza_lookup[correction['exit_plaza']];
    correction['entry_plaza'] = plaza_lookup[correction['entry_plaza']];
    let exit_plaza = correction.exit_plaza.toLowerCase();
    let entry_plaza = correction.entry_plaza.toLowerCase();
    correction['tag_agency_id'] = agency_lookup[correction['tag_agency_id']];
    correction['tag_serial_number'] = Number(correction['tag_serial_number']);
    correction['read_performance'] = Number(correction['read_performance']);
    correction['write_performance'] = Number(correction['write_performance']);
    correction['tag_pgm_status'] = pgm_status_lookup[correction['tag_pgm_status']];
    correction['lane_mode'] = mode_lookup[correction['lane_mode']];
    correction['validation_status'] = validation_status_lookup[correction['validation_Status']];
    correction['LP_state'] = state_lookup[correction['LP_state']];
    correction['LP_number'] = encrypt(correction['LP_number']);
    correction['class_charged'] = class_lookup[correction['class_charged']];
    correction['actual_axles'] = Number(correction['actual_axles']);
    correction['debit_credit'] = dc_lookup[correction['debit_credit']];
    correction['toll_amount'] = Number(correction['toll_amount']);
    

    try {
      let result = await stub.putPrivateData(entry_plaza + "_transaction_data_entry", transaction_serial_number, Buffer.from(JSON.stringify(correction)))
      console.info(result.toString());
      console.info("putPrivateData Entry");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData(exit_plaza + "_transaction_data_exit", transaction_serial_number, Buffer.from(JSON.stringify(correction)))
      console.info(result.toString());
      console.info("putPrivateData Exit");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData("report_transaction", transaction_serial_number, Buffer.from(JSON.stringify(correction)))
      console.info(result.toString());
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }


    await stub.putPrivateData("corr_reason", correction['corr_reason'], Buffer.from(JSON.stringify(correction)));
    

    console.info('============= END : Set Correction ===========');
  }
  
  async correctionRecon(stub,args){
    console.log('=====started Correction Reconciliation=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let correction_recon = transient.get('correction_recon');
    correction_recon = JSON.parse(correction_recon.toBuffer().toString());
    let transaction_serial_number = encrypt(correction_recon['transaction_serial_number']);
    
    correction_recon['post_status'] = post_status_lookup[correction_recon['post_status']];
    correction_recon['post_plan'] = post_plan_lookup[correction_recon['post_plan']];
    correction_recon['debit_credit'] = dc_lookup[correction_recon['debit_credit']];
    correction_recon['owed_amount'] = Number(correction_recon['owed_amount']);


    await stub.putPrivateData("transaction_serial_number", correction_recon['transaction_serial_number'], Buffer.from(JSON.stringify(correction_recon)));
    

    console.info('============= END : Set Correction reconciliation record ===========');
  }
  
  async licensePlateFile(stub,args){
    console.log('=====started adding License Plate File=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let license_plate = transient.get('license_plate');
    license_plate = JSON.parse(license_plate.toBuffer().toString());
    
    license_plate['license_state'] = state_lookup[license_plate['license_state']];
    license_plate['license_number'] = encrypt(license_plate['license_number']);
    license_plate['license_type'] = LP_type_lookup[license_plate['license_type']];
    license_plate['tag_agency_id'] = agency_lookup[license_plate['tag_agency_id']];
    license_plate['tag_serial_number'] = Number(license_plate['tag_serial_number']);

    await stub.putState("license_number", license_plate['license_number'], Buffer.from(JSON.stringify(license_plate)));

    console.info('============= END : Added Adjustment/Correction ===========');
  }

  async addNTReconciliation(stub,args){
    console.log('=====started adding Non-Toll Reconciliation=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let nt_recon = transient.get('nt_recon');
    nt_recon = JSON.parse(nt_recon.toBuffer().toString());
    let transaction_serial_number = encrypt(nt_recon['transaction_serial_number']);
    
    nt_recon['post_status'] = post_status_lookup[nt_recon['post_status']];
    nt_recon['post_plan'] = post_plan_lookup[nt_recon['post_plan']];
    nt_recon['debit_credit'] = dc_lookup[nt_recon['debit_credit']];
    nt_recon['owed_amount'] = Number(nt_recon['owed_amount']);


    await stub.putPrivateData("transaction_serial_number", nt_recon['transaction_serial_number'], Buffer.from(JSON.stringify(nt_recon)));

    console.info('============= END : Added Non-Toll Reconciliation ===========');
  }
  
  async addNTTransactionData(stub,args){
    console.log('=====started adding Non-Toll Transaction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let nt_transaction_data = transient.get('nt_transaction_data');
    nt_transaction_data = JSON.parse(nt_transaction_data.toBuffer().toString());
    
    let transaction_serial_number = encrypt(nt_transaction_data['transaction_serial_number']);
    nt_transaction_data['created_at'] = new Date(nt_transaction_data['date'] + " " + nt_transaction_data['time']);
    nt_transaction_data['date'] = new Date(nt_transaction_data['date']);
    nt_transaction_data['date'] =  nt_transaction_data['date'].toISOString().split("T")[0];
    nt_transaction_data['facility_agency'] = facility_lookup[nt_transaction_data['facility_agency']];
    nt_transaction_data['transaction_type'] = trxtype_lookup[nt_transaction_data['transaction_type']];
    nt_transaction_data['exit_plaza'] = plaza_lookup[nt_transaction_data['exit_plaza']];
    nt_transaction_data['entry_plaza'] = plaza_lookup[nt_transaction_data['entry_plaza']];
    let exit_plaza = nt_transaction_data.exit_plaza.toLowerCase();
    let entry_plaza = nt_transaction_data.entry_plaza.toLowerCase();
    nt_transaction_data['tag_agency_id'] = agency_lookup[nt_transaction_data['tag_agency_id']];
    nt_transaction_data['tag_serial_number'] = Number(nt_transaction_data['tag_serial_number']);
    nt_transaction_data['read_performance'] = Number(nt_transaction_data['read_performance']);
    nt_transaction_data['write_performance'] = Number(nt_transaction_data['write_performance']);
    nt_transaction_data['tag_pgm_status'] = pgm_status_lookup[nt_transaction_data['tag_pgm_status']];
    nt_transaction_data['lane_mode'] = mode_lookup[nt_transaction_data['lane_mode']];
    nt_transaction_data['validation_status'] = validation_status_lookup[nt_transaction_data['validation_Status']];
    nt_transaction_data['LP_state'] = state_lookup[nt_transaction_data['LP_state']];
    nt_transaction_data['LP_number'] = encrypt(nt_transaction_data['LP_number']);
    nt_transaction_data['class_charged'] = class_lookup[nt_transaction_data['class_charged']];
    nt_transaction_data['actual_axles'] = Number(nt_transaction_data['actual_axles']);
    nt_transaction_data['debit_credit'] = dc_lookup[nt_transaction_data['debit_credit']];
    nt_transaction_data['toll_amount'] = Number(nt_transaction_data['toll_amount']);
    

    try {
      let result = await stub.putPrivateData(entry_plaza + "_transaction_data_entry", transaction_serial_number, Buffer.from(JSON.stringify(nt_transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Entry");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData(exit_plaza + "_transaction_data_exit", transaction_serial_number, Buffer.from(JSON.stringify(nt_transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData Exit");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData("report_transaction", transaction_serial_number, Buffer.from(JSON.stringify(nt_transaction_data)))
      console.info(result.toString());
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }

    console.info('============= END : Added Non-Toll Transaction ===========');
  }
  
  async addNTCorrectionFile(stub,args){
    console.log('=====started adding Non-Toll Correction=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let nt_corr = transient.get('nt_corr');
    nt_corr = JSON.parse(nt_corr.toBuffer().toString());
    let nt_corr_reason = encrypt(nt_corr['nt_corr_reason']);
    
    let transaction_serial_number = encrypt(nt_corr['transaction_serial_number']);
    nt_corr['created_at'] = new Date(nt_corr['date'] + " " + nt_corr['time']);
    nt_corr['date'] = new Date(nt_corr['date']);
    nt_corr['date'] =  nt_corr['date'].toISOString().split("T")[0];
    nt_corr['facility_agency'] = facility_lookup[nt_corr['facility_agency']];
    nt_corr['transaction_type'] = trxtype_lookup[nt_corr['transaction_type']];
    nt_corr['exit_plaza'] = plaza_lookup[nt_corr['exit_plaza']];
    nt_corr['entry_plaza'] = plaza_lookup[nt_corr['entry_plaza']];
    let exit_plaza = nt_corr.exit_plaza.toLowerCase();
    let entry_plaza = nt_corr.entry_plaza.toLowerCase();
    nt_corr['tag_agency_id'] = agency_lookup[nt_corr['tag_agency_id']];
    nt_corr['tag_serial_number'] = Number(nt_corr['tag_serial_number']);
    nt_corr['read_performance'] = Number(nt_corr['read_performance']);
    nt_corr['write_performance'] = Number(nt_corr['write_performance']);
    nt_corr['tag_pgm_status'] = pgm_status_lookup[nt_corr['tag_pgm_status']];
    nt_corr['lane_mode'] = mode_lookup[nt_corr['lane_mode']];
    nt_corr['validation_status'] = validation_status_lookup[nt_corr['validation_Status']];
    nt_corr['LP_state'] = state_lookup[nt_corr['LP_state']];
    nt_corr['LP_number'] = encrypt(nt_corr['LP_number']);
    nt_corr['class_charged'] = class_lookup[nt_corr['class_charged']];
    nt_corr['actual_axles'] = Number(nt_corr['actual_axles']);
    nt_corr['debit_credit'] = dc_lookup[nt_corr['debit_credit']];
    nt_corr['toll_amount'] = Number(nt_corr['toll_amount']);
    

    try {
      let result = await stub.putPrivateData(entry_plaza + "_transaction_data_entry", transaction_serial_number, Buffer.from(JSON.stringify(nt_corr)))
      console.info(result.toString());
      console.info("putPrivateData Entry");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData(exit_plaza + "_transaction_data_exit", transaction_serial_number, Buffer.from(JSON.stringify(nt_corr)))
      console.info(result.toString());
      console.info("putPrivateData Exit");
    } catch (error) {
      console.error(error);
    }
    
    try {
      let result = await stub.putPrivateData("report_transaction", transaction_serial_number, Buffer.from(JSON.stringify(nt_corr)))
      console.info(result.toString());
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }

    console.info('============= END : Added Non-Toll Correction ===========');
  }
  
  async addNTCorrReconciliation(stub,args){
    console.log('=====started adding Non-Toll Correction Reconciliation=======');
    /*
     First argument should contains the header data and second argument should contain the message data.
    */
    let transient = stub.getTransient();
    let nt_corr_recon = transient.get('nt_corr_recon');
    nt_corr_recon = JSON.parse(nt_corr_recon.toBuffer().toString());
    let transaction_serial_number = encrypt(nt_corr_recon['transaction_serial_number']);
    
    nt_corr_recon['post_status'] = post_status_lookup[nt_corr_recon['post_status']];
    nt_corr_recon['post_plan'] = post_plan_lookup[nt_corr_recon['post_plan']];
    nt_corr_recon['debit_credit'] = dc_lookup[nt_corr_recon['debit_credit']];
    nt_corr_recon['owed_amount'] = Number(nt_corr_recon['owed_amount']);


    await stub.putPrivateData("transaction_serial_number", nt_corr_recon['transaction_serial_number'], Buffer.from(JSON.stringify(nt_corr_recon)));

    console.info('============= END : Added Non-Toll Correction Reconciliation ===========');
  }

  async addAcknowledgement(stub,args){
    console.log('=====started adding Acknowledgement=======');
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
