import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.account = null;
        this.airlines = [];
        this.passengers = [];
    }

   initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];
            this.account = accts[0];

            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, result) => {
                callback(error, payload);
            });
    }

    registerAirline(airline, name, callback) {

        let self = this;
        console.log('changed to account: ', self.owner)

        self.flightSuretyApp.methods
            .registerAirline(airline, name)
            .send({ from: self.owner, gas: 100000 }, (error, result) => {
                callback(error, result);
            });
    }


    getRegisteredAirlines(callback) {
        console.log("result");
        let self = this;
        self.flightSuretyApp.methods.getRegisteredAirlines().call({}, (error, result) => {
            console.log("result2");
            // console.log(this.web3.utils.hexToAscii(result[0]));
            // console.log(this.web3.utils.hexToAscii('0x4920686176652031303021'));
            callback(error, result);
        });
    }

    fundAirline(address, amount, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fundAirline(address, amount)
            .send({ from: self.owner, gas: 100000 }, (error, result) => {
                callback(error, result);
            });
    }

    getActivatedAirlines(callback) {
        console.log("result");
        let self = this;
        self.flightSuretyApp.methods.getActivatedAirlines().call({}, (error, result) => {
            console.log("result2");
            // console.log(this.web3.utils.hexToAscii(result[0]));
            // console.log(this.web3.utils.hexToAscii('0x4920686176652031303021'));
            callback(error, result);
        });
    }

    registerFlight(number, callback) {
        let self = this;
        console.log('changed to account: ', self.owner)
        self.flightSuretyApp.methods
            .registerFlight(self.owner , number)
            .send({ from: self.owner , gas: 100000}, (error, result) => {
                callback(error,result);
            });
    }

    getRegisteredFlights(callback) {
        console.log("result");
        let self = this;
        self.flightSuretyApp.methods.getRegisteredFlights().call({}, (error, result) => {
            console.log("result2");
            // console.log(this.web3.utils.hexToAscii(result[0]));
            // console.log(this.web3.utils.hexToAscii('0x4920686176652031303021'));
            callback(error, result);
        });
    }

    buyInsurance(flightKey,amount,  callback) {
        let self = this;
        console.log('changed to account: ', self.account)
        self.flightSuretyApp.methods
            .buyInsurance(flightKey, amount)
            .send({ from: self.account , gas: 100000}, (error, result) => {
                callback(error, result);
            });
    }

    payPassenger(callback) {
        let self = this;
        self.flightSuretyApp.methods.payPassenger().send({ from: self.account, gas: 999999999 }, (error, result) => {
            callback(error, result);
        });
    }
}