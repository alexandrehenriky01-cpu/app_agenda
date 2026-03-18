/* eslint-disable max-len */
const {onRequest} = require("firebase-functions/v2/https");

exports.health = onRequest((req, res) => {
  res.status(200).send("ok");
});