const schema = require("schm");
const translate = require('schm-translate');

const recordTranslate = translate({
  transactionRecord:"TransactionRecord",
  recordType:"RecordType",
  txnReferenceID:"TxnReferenceID",
  exitDateTime:"ExitDateTime",
  facilityID:"FacilityID",
  facilityDesc:"FacilityDesc",
  exitPlaza:"ExitPlaza",
  exitPlazaDesc:"ExitPlazaDesc",
  exitLane:"ExitLane",
  occupancyInd:"OccupancyInd",
  vehicleClass:"VehicleClass",
  tollAmount:"TollAmount",
  discountPlanType:"DiscountPlanType",
  vehicleClassAdj:"VehicleClassAdj",
  systemMatchInd:"SystemMatchInd",
  spare1:"Spare1",
  spare2:"Spare2",
  spare3:"Spare3",
  spare4:"Spare4",
  spare5:"Spare5",
  exitDateTimeTZ:"ExitDateTimeTZ",
  entryDateTimeTZ:"EntryDateTimeTZ",
  entryData:"EntryData",
  entryDateTime:"EntryDateTime",
  entryPlaza:"EntryPlaza",
  entryPlazaDesc:"EntryPlazaDesc",
  entryLane:"EntryLane",
  tagInfo:"TagInfo",
  tagAgencyID:"TagAgencyID",
  tagSerialNo:"TagSerialNo",
  tagStatus:"TagStatus"  ,
  plateInfo:"PlateInfo",
  plateCountry:"PlateCountry",
  plateState:"PlateState",
  plateNumber:"PlateNumber",
  plateType:"PlateType"
})

const tagInfoSchema = schema({
  tagAgencyID: String,
  tagSerialNo: String,
  tagStatus: String
}, recordTranslate);

const entryDataSchema = schema({
  entryDateTime: String,
  entryPlaza: String,
  entryPlazaDesc: String,
  entryLane: String
}, recordTranslate);

const plateInfoSchema = schema({
  plateCountry: String,
  plateState: String,
  plateNumber: String,
  plateType : String
}, recordTranslate);

const recordSchema = schema({
  transactionRecord:String,
  recordType:String,
  txnReferenceID:String,
  exitDateTime:String,
  facilityID:String,
  facilityDesc:String,
  exitPlaza:String,
  exitPlazaDesc:String,
  exitLane:String,
  occupancyInd:String,
  vehicleClass:String,
  tollAmount:String,
  discountPlanType:String,
  vehicleClassAdj:String,
  systemMatchInd:String,
  spare1:String,
  spare2:String,
  spare3:String,
  spare4:String,
  spare5:String,
  exitDateTimeTZ:String,
  entryDateTimeTZ:String,
  entryData:entryDataSchema,
  tagInfo:tagInfoSchema,
  plateInfo:plateInfoSchema
}, recordTranslate);



module.exports.schema = recordSchema;