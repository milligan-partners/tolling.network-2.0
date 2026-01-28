const router = require('express-promise-router')();
const TXController = require('../controllers/tx');
const { enforceJwt } = require("../utils/jwt-utils");

router.use(enforceJwt);
router.use(TXController.parseModel);

router.route('/account/:accountID')
	.get(TXController.getAccount);

router.route('/account')
    .post(TXController.addAccount);

router.route('/account/')
    .put(TXController.changeAccountStatus);
    
router.route('/transaction/:transactionId')
    .get(TXController.getTransaction);

router.route('/transaction')
    .post(TXController.addTransaction);

router.route('/transaction')
    .get(TXController.queryTransaction);

router.use(TXController.sendResult);

module.exports = router;


