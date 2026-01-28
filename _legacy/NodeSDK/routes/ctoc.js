const router = require('express-promise-router')();
const TXController = require('../controllers/ctoc');
const { enforceJwt } = require("../utils/jwt-utils");

router.use(enforceJwt);
router.route('/')
    .post(TXController.parseModel);
    
router.route('/')
    .post(TXController.handleTx);


module.exports = router;


