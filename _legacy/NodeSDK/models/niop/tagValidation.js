const schema = require("schm");
const translate = require('schm-translate')

const tagTranslate = translate({
  homeAgencyID: "HomeAgencyID",
  tagAgencyID: "TagAgencyID",
  tagSerialNumber: "TagSerialNumber",
  tagStatus: "TagStatus",
  discountPlans: "DiscountPlans",
  discountPlanType: "DiscountPlanType",
  discountPlanStart: "DiscountPlanStart",
  discountPlanEnd: "DiscountPlanEnd",
  tagType: "TagType",
  tagClass: "TagClass",
  tvlPlateDetails: "TVLPlateDetails",
  plateCountry: "PlateCountry",
  plateState: "PlateState",
  plateNumber: "PlateNumber",
  plateType: "PlateType",
  plateEffectiveFrom: "PlateEffectiveFrom",
  plateEffectiveTo: "PlateEffectiveTo",
  tvlAccountDetails: "TVLAccountDetails",
  accountNumber: "AccountNumber",
  fleetIndicator: "FleetIndicator"
})

const discountPlanSchema = schema({
    discountPlanType: String,
    discountPlanStart: String,
    discountPlanEnd: String
  }, tagTranslate);

const tvlPlateDetailsSchema = schema({
    plateCountry: String,
    plateState: String,
    plateNumber: String,
    plateType: String,
    plateEffectiveFrom: String,
    plateEffectiveTo: String
  }, tagTranslate);

const tvlAccountDetailsSchema = schema({
    accountNumber: String,
    fleetIndicator: String
  }, tagTranslate);


const tvlValidationSchema = schema({
  homeAgencyID: String,
  tagAgencyID: String,
  tagSerialNumber: String,
  tagStatus: String,
  discountPlans: discountPlanSchema,
  tagType: String,
  tagClass: String,
  tvlPlateDetails: tvlPlateDetailsSchema,
  tvlAccountDetails: tvlAccountDetailsSchema,
}, tagTranslate);

module.exports.schema = tvlValidationSchema