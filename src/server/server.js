import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
import "babel-polyfill";



let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

var oraclesArray = [];



// Oracle Registration
async function registerOracles() {
  // ARRANGE
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call();

  // register 1 oracle for each address in ganache 
  let acct = await web3.eth.getAccounts();
  const ORACLES_COUNT = (acct.length < 20) ? acct.length : 20;

  for (let a = 0; a < ORACLES_COUNT; a++) {

    try {
      console.log(acct[a])
      await flightSuretyApp.methods.registerOracle().send({ from: acct[a], value: fee, gas: 300000 });
      let result = await flightSuretyApp.methods.getMyIndexes().call({ from: acct[a] });
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);

      oraclesArray.push({ address: acct[a], value: [result[0], result[1], result[2]] });
      // console.log(oraclesArray[a].address)
      // console.log(oraclesArray[0].value[0])
    } catch (e) {
      console.log('ERROR: Oracle registerOracles Message', e);
    }
  }

}


flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) {
    console.log(error)
  }
  else {
    console.log(event)

    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

    var statusCodes = [
      STATUS_CODE_UNKNOWN, STATUS_CODE_ON_TIME, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_WEATHER, STATUS_CODE_LATE_TECHNICAL, STATUS_CODE_LATE_OTHER
    ];

    // loop though the array to find index of the oracle requested. 
    for (let i = 0; i < oraclesArray.length; i++) {
      if (oraclesArray[i].value.includes(event.returnValues.index)) {

        console.log(oraclesArray[i]);
        var randomStatus = Math.floor(Math.random() * 5);

        try {
          let result = event.returnValues;
          flightSuretyApp.methods.submitOracleResponse(
            parseInt(result.index),
            result.airline,
            result.flight,
            result.timestamp,
            statusCodes[randomStatus]).send(
              { from: oraclesArray[i].address, gas: 300000 });
          console.log("Worked OK");

        } catch (e) {
          console.log('ERROR: Oracle submitOracleResponse', oraclesArray[i].address, result.index, result.airline, result.flight, result.timestamp, statusCodes[randomStatus])
          console.log('ERROR: Oracle submitOracleResponse Message: ', e);
        }

      }
    }
  }
});

registerOracles();
const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;


