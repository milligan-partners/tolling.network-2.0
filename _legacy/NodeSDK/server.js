"use strict";

// Imports
const express = require("express");
const path = require("path");

//Routes
const tx = require("./routes/tx");
const niop = require("./routes/niop");
const ctoc = require("./routes/ctoc");
const auth = require("./routes/auth");
const { parseJwt } = require("./utils/jwt-utils");

// Constants
const PORT = 8080;
const HOST = "0.0.0.0";

// Body parsers
var bodyParser = require('body-parser');
require('body-parser-xml')(bodyParser);

// App
const app = express();
app.set("view engine", "ejs");

app.get("/", async (req, res) => {
  res.sendFile(path.join(__dirname + "/views/index.html"));
});

app.use(bodyParser.urlencoded({ extended: false }));  
app.use(bodyParser.json());
app.use(bodyParser.xml({
	xmlParseOptions: {
	normalize: true,     // Trim whitespace inside text nodes
    explicitArray: false, // Only put nodes in array if >1
  }
}));

app.use(parseJwt);
app.use("/api/tx", tx);
app.use("/api/niop", niop);
app.use("/api/ctoc", ctoc);
app.use("/api/auth", auth);

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
