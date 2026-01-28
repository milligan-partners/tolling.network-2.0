/*
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
*/

const shim = require('fabric-shim');
const util = require('util');

var agency_lookup = {
  'at': 'BATA',
  'gg': 'Golden Gate Bridge',
  'sd': 'SANDAG',
  'sr': 'SR-91',
  'tc': 'TCA',
  'cv': 'CTV',
  'la': 'LA Metro',
  'All agencies': 'xx'
}

var tag_type_lookup = {
  'I': -1,
  'V': 0,
  'N': 1
}

var Chaincode = class {

  // Initialize the chaincode
  async Init(stub) {
    console.info('========= example02 Init =========');
    return shim.success(Buffer.from("Deu Certo"));
  }

  async Invoke(stub) {
    let ret = stub.getFunctionAndParameters();
    console.info(ret);
    let method = this[ret.fcn];
    if (!method) {
      console.info('no method of name:' + ret.fcn + ' found');
      return shim.success();
    }
    try {
      let payload = await method(stub, ret.params);
      return shim.success(payload);
    } catch (err) {
      console.info(err);
      return shim.error(err);
    }
  }



  async queryTollCharges(stub, args) {
    let tag_id = encrypt(args[0]);
    let source = "TCA";
    let result = await stub.getPrivateData(source.toLowerCase() + "_toll_charges_source", tag_id);
    console.info(result);

    return result;
  }

  async queryTollPrivateCharges(stub, args) {
    let tag_id = encrypt(args[0]);
    let source = "BATA";
    let result = await stub.getPrivateData(source.toLowerCase() + "_toll_charges_destination", tag_id);
    console.info(result);

    return result;
  }

  async addTollCharges(stub, args){
    console.info('============= END : adding toll charges record ===========');
    console.log("Toll Charges");
    let transient = stub.getTransient();
    console.info(transient);
    let toll_charges = transient.get('toll_charges');
    console.info(toll_charges);
    toll_charges = JSON.parse(toll_charges.toString());
    let tag_id = encrypt(toll_charges['tag_id']);
    toll_charges['created_at'] = new Date(toll_charges['date'] + " " + toll_charges['time']);
    toll_charges['date'] = new Date(toll_charges['date']);
    toll_charges['date'] =  toll_charges['date'].toISOString().split("T")[0];
    let transaction_id = toll_charges['transaction_id'];
    toll_charges['amount'] = Number(toll_charges['amount']);
    toll_charges['fee'] = Number(toll_charges['fee']);
    toll_charges['invoice'] = toll_charges['amount'] - toll_charges['fee'];
    toll_charges['source'] = agency_lookup[toll_charges['source']];
    toll_charges['destination'] = agency_lookup[toll_charges['destination']];
    let source = toll_charges.source.toLowerCase();
    let destination = toll_charges.destination.toLowerCase();

    try {
      let result = await stub.putPrivateData(source + "_toll_charges_source", transaction_id, Buffer.from(JSON.stringify(toll_charges)))
      console.info(result.toString());
      console.info("putPrivateData Source");
    } catch (error) {
      console.error(error);
    }

    try {
      let result = await stub.putPrivateData(destination + "_toll_charges_destination", transaction_id, Buffer.from(JSON.stringify(toll_charges)))
      console.info(result.toString());
      console.info("putPrivateData TollChargesDestination");
    } catch (error) {
      console.error(error);
    }

    try {
      let result = await stub.putPrivateData("report_transaction", transaction_id, Buffer.from(JSON.stringify(toll_charges)))
      console.info("putPrivateData report_transaction");
    } catch (error) {
      console.error(error);
    }

    console.info('============= END : successfully added toll charges record ===========');
    return Buffer.from("OK");
  }

  async addReconTollCharges(stub,args){
    console.info('============= END : adding Reconciled Toll charges record ===========');

    let transient = stub.getTransient();
    let recon_toll_charges = transient.get('recon_toll_charges');
    recon_toll_charges = JSON.parse(recon_toll_charges.toString());
    recon_toll_charges['tag_id'] = encrypt(recon_toll_charges['tag_id']);
    let source = recon_toll_charges.source.toLowerCase();
    let destination = recon_toll_charges.destination.toLowerCase();

    await stub.putPrivateData(source + "recon_source", recon_toll_charges['tag_id'], Buffer.from(JSON.stringify(recon_toll_charges)))
    await stub.putPrivateData(destination + "recon_destination", recon_toll_charges['tag_id'], Buffer.from(JSON.stringify(recon_toll_charges)))
    await stub.putState(key, Buffer.from(JSON.stringify(recon_toll_charges)));

    console.info('============= END : successfully added Recon toll charges record ===========');


  }

  async setTagStatus(stub,args) {
    console.info('============= END : adding Tag status record ===========');
    console.log("Tag Status")
    let transient = stub.getTransient();
    console.log(transient);
    let tag = transient.get('tag_status');
    console.log(tag);
    tag = JSON.parse(tag.toString());

    tag['tag_id'] = encrypt(tag['tag_id']);
    tag['account_id'] = encrypt(tag['account_id']);
    let date = new Date(tag['date'] + " " + tag['time']);
    tag['created_at'] = date
    tag['date'] = new Date(tag['date']);
    tag['date'] =  tag['date'].toISOString().split("T")[0];
    tag['source'] = agency_lookup[tag['source']];
    tag['destination'] = agency_lookup[tag['destination']];

    
    await stub.putPrivateData("tag_status", tag['tag_id'], Buffer.from(JSON.stringify(tag)));
    await stub.putPrivateData("report_tag_status", tag['tag_id'], Buffer.from(JSON.stringify(tag)));

    console.info('============= END : successfully added  tag status record ===========');
  }

  async addPaybyPlate(stub,args) {
    console.info('============= END : adding  pay by plate record ===========');

    let transient = stub.getTransient();
    let pay_by_plate = transient.get('pay_by_plate');
    pay_by_plate = JSON.parse(pay_by_plate.toString());
    pay_by_plate['plate'] = encrypt(pay_by_plate['plate']);
    pay_by_plate['state'] = encrypt(pay_by_plate['state']);
    
    let source = pay_by_plate.source.toLowerCase();
    let destination = pay_by_plate.destination.toLowerCase();

    await stub.putPrivateData(source + "pay_by_plate_source", pay_by_plate.plate + pay_by_plate.state, Buffer.from(JSON.stringify(pay_by_plate)))
    await stub.putPrivateData(destination + "pay_by_plate_destination", pay_by_plate.plate + pay_by_plate.state, Buffer.from(JSON.stringify(pay_by_plate)))

    // //Detail record
    // let pay_by_plate.license_plate = args[0];_source", 
    // let pay_by_plate.tran_number = Number(args[1]);
    // let pay_by_plate.state = args[2];
    // let pay_by_plate.tran_amt = Number(args[3]);
    // let pay_by_plate.entry_tran_date = args[4];
    // let pay_by_plate.entry_tran_time = args[5];
    // let pay_by_plate.entry_plaza = args[6];
    // let pay_by_plate.entry_lane = args[7];
    // let pay_by_plate.exit_tran_date = args[8];
    // let pay_by_plate.exit_tran_time = args[9];
    // let pay_by_plate.exit_plaza = args[10];
    // let pay_by_plate.exit_lane = args[11];
    // let pay_by_plate.axle_count = Number(args[12]);
    // let pay_by_plate.vehicle_type = Number(args[13]);

    // // Header record from file. In the future, check if some of these can be omitted
    // let pay_by_plate.fileType = "PAYBYPLATE";
    // let pay_by_plate.sequence_number = Number(args[14]);
    // let pay_by_plate.business_date = args[15];
    // let pay_by_plate.source = args[16];
    // let pay_by_plate.destination = args[16];
    // let pay_by_plate.create_date = args[17];
    // let pay_by_plate.create_time = args[18];
    // let pay_by_plate.version = args[19];
    console.info('============= END : successfully added  pay by plate record ===========');


  }

  async addReconPaybyPlate(stub,args) {
   console.info('============= END : adding  recon pay by plate recon record ===========');

    let transient = stub.getTransient();
    let recon_pay_by_plate = transient.get('recon_pay_by_plate');
    recon_pay_by_plate = JSON.parse(recon_pay_by_plate.toString());
    recon_pay_by_plate['plate'] = encrypt(recon_pay_by_plate['plate']);
    recon_pay_by_plate['state'] = encrypt(recon_pay_by_plate['state']);
    let source = recon_pay_by_plate.source.toLowerCase();
    let destination = recon_pay_by_plate.destination.toLowerCase();

    await stub.putPrivateData(source + "recon_pay_by_plate_source", recon_pay_by_plate.plate + recon_pay_by_plate.state, Buffer.from(JSON.stringify(recon_pay_by_plate)))
    await stub.putPrivateData(destination + "recon_pay_by_plate_destination", recon_pay_by_plate.plate + recon_pay_by_plate.state, Buffer.from(JSON.stringify(recon_pay_by_plate)))

   //Detail record
  //  let recon_pay_by_plate.license_plate = args[0];
  //  let recon_pay_by_plate.tran_number = Number(args[1]);
  //  let recon_pay_by_plate.state = args[2];
  //  let recon_pay_by_plate.tran_amt = Number(args[3]);
  //  let recon_pay_by_plate.entry_tran_date = args[4];
  //  let recon_pay_by_plate.entry_tran_time = args[5];
  //  let recon_pay_by_plate.entry_plaza = args[6];
  //  let recon_pay_by_plate.entry_lane = args[7];
  //  let recon_pay_by_plate.exit_tran_date = args[8];
  //  let recon_pay_by_plate.exit_tran_time = args[9];
  //  let recon_pay_by_plate.exit_plaza = args[10];
  //  let recon_pay_by_plate.exit_lane = args[11];
  //  let recon_pay_by_plate.axle_count = Number(args[12]);
  //  let recon_pay_by_plate.post_amt = Number(args[13]);
  //  let recon_pay_by_plate.recon_code = args[14];

  //  // Header record from file. In the future, check if some of these can be omitted
  //  let recon_pay_by_plate.fileType = "PLATERECON";
  //  let recon_pay_by_plate.sequence_number = Number(args[15]);
  //  let recon_pay_by_plate.business_date = args[16];
  //  let recon_pay_by_plate.source = args[17];
  //  let recon_pay_by_plate.destination = args[18];
  //  let recon_pay_by_plate.create_date = args[19];
  //  let recon_pay_by_plate.create_time = args[20];
  //  let recon_pay_by_plate.version = args[21];

  //  let key = 'R' + recon_pay_by_plate.tran_number.toString()

  //  await stub.putState(key, Buffer.from(JSON.stringify(recon_pay_by_plate)));
   console.info('============= END : successfully added  pay by plate recon record ===========');

  }


  async addLicensePlateStatus(stub,args) {
    console.info('============= END : adding license plate status record ===========');

    let transient = stub.getTransient();
    let license_plate_status = transient.get('license_plate_status');
    license_plate_status = JSON.parse(license_plate_status.toString());
    license_plate_status['tag_id'] = encrypt(license_plate_status['plate'] + license_plate_status['state']);
    license_plate_status['plate'] = encrypt(license_plate_status['plate']);
    license_plate_status['state'] = encrypt(license_plate_status['state']);
    license_plate_status['account_id'] = encrypt(license_plate_status['account_id']);
    license_plate_status['type'] = 'license_plate_status';
    let date = new Date(license_plate_status['create_date'] + " " + license_plate_status['create_time']);
    license_plate_status['created_at'] = date
    license_plate_status['create_date'] = new Date(license_plate_status['create_date']);
    license_plate_status['create_date'] =  license_plate_status['create_date'].toISOString().split("T")[0];
    license_plate_status['readable_source'] = agency_lookup[license_plate_status['source']]
    license_plate_status['readable_destination'] = agency_lookup[license_plate_status['destination']]

    await stub.putPrivateData("report_tag_status", license_plate_status['tag_id'], Buffer.from(JSON.stringify(license_plate_status)))
    console.info('============= END : successfully added license plate status record ===========');
  }

};

function encrypt(arg) {
  return arg
}

shim.start(new Chaincode());