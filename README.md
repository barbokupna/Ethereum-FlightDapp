# Ethereum-FlightSurety
![BlockchainFlight](readmeImage.jpg)
This is an example of Flight delay insurance Dapp.
Passengers can purchase insurance prior to a flight and if the flight is delayed they will be paid 1.5 times the amount paid for the insurance.


## Table of Contents

* [Features](#features)
* [Requirements](#Requirements)
* [Development](#development)
* [Deployment](#deployment)
* [Resources](#resources)

## Features

* Oracles provide status flight.
* Separation of concerns: DataContract for data persistence and AppContract for app logic and Oracles interaction.
* Dapp client to trigger contract calls.
* Server App to simulate Oracles.

## Requirements:

* Airlines: 
    - First Airline registered when the contract is deployed
    - Only existing airlines can register new airline until there is four registered airlines
    - Starting with the fifth airline registration requires multi-party consensus of 50%.
    - Airline can be registered but can't participate until it submits funding of 10Eth. 
    
* Passengers:
    - May pay up to 1 Eth for flight insurance
    - If flight is delayed due to airline fault, the passenger gets his/her account credited for 1.5 times the amount paid
    - Funds are transferred from the contract to passenger wallet only when the withdrawal  is initiated by the passenger

* Oracles:
    - Implemented as a server app
    - On startup 20+ oracles are registered and their assigned indexes are persisted in memory
    - Client Dapp is used to trigger flight status which generates Oracle request event captured by server
    - Server loops identifies oracles for which the requests applies and calls into the app logic to initiate status update

## Development

* Versions: 
    - Truffle v5.7.1 (core: 5.7.1)
    - Ganache v7.6.0
    - Solidity - ^0.4.24 (solc-js)
    - Node v14.21.2
    - Web3.js v1.8.1

* Build/Run Locally:
    - use ganache or truffle to run it 
    - npm install
    - truffle compile
    - truffle migrate -reset

    - npm run dapp 
    - npm run server
    
# Resources
* [Remix - Solidity IDE](https://remix.ethereum.org/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Truffle Framework](https://truffleframework.com/)
* [Ganache - One Click Blockchain](https://truffleframework.com/ganache)
* [Open Zeppelin ](https://openzeppelin.org/)
* [UML](https://medium.com/@kccmeky/how-to-create-uml-class-diagram-from-your-solidity-contract-6bc050016da8)

