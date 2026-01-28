const fs = require("fs");
const jwt = require("jsonwebtoken");

// use 'utf8' to get string instead of byte array  (512 bit key)
var privateKEY = fs.readFileSync("./keys/private.key", "utf8");
var publicKEY = fs.readFileSync("./keys/public.key", "utf8");
module.exports = {
  sign: (payload) => {
    return jwt.sign(payload, privateKEY, {
      algorithm:  "RS256"
    });
  },
  verify: (token) => {
    try {
      return jwt.verify(token, publicKEY,{
        algorithm:  ["RS256"]
       });
    } catch (err) {
      console.log(err);
      return false;
    }
  },
  parseJwt: (req, res, next) => {
    let token = req.headers.authorization;
    req.locals = req.locals || {};

    if (token == undefined) {
      return next();
    }

    token = req.headers.authorization
      .split("Bearer")
      .pop()
      .trim();
      
    
    req.locals.auth_token = token;
    var verify = module.exports.verify(token, publicKEY);
    console.log('verify');
    console.log(verify);
    req.locals.payload = verify
    console.log(req.locals.payload);
    next();
  },
  enforceJwt: (req, res, next) => {
    if(!req.locals.payload) {
      res.send(401);
      return;
    }
    next()
  },
  decode: token => {
    return jwt.decode(token, { complete: true });
    //returns null if token is invalid
  }
};
