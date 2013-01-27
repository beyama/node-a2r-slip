module.exports = process.env.SLIP_COV ?
  require("./lib-cov/slip") :
  (require.extensions[".coffee"] ? require("./src/slip") : require("./lib/slip"))
