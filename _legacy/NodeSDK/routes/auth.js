const router = require('express-promise-router')();
const AuthController = require('../controllers/auth');

router.route('/')
    .post(AuthController.authenticate);

module.exports = router;


