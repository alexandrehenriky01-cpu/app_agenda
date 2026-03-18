const {onRequest} = require("firebase-functions/v2/https");

exports.hello = onRequest((req, res) => {
  res.status(200).send("Functions OK!");
});
