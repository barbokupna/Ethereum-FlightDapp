# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

- **Install dependencies**: `npm install`
- **Compile contracts**: `truffle compile`
- **Migrate contracts to local network**: `truffle migrate --reset`
- **Run tests**: `npm test` (executes `truffle test ./test/flightSurety.js`)
- **Run a single test file**: `truffle test ./test/flightSurety.js`
- **Start the DApp client**: `npm run dapp`
- **Start the oracle server**: `npm run server`
- **Build production DApp**: `npm run dapp:prod`

## High‑Level Architecture

- **Contracts**
  - `FlightSuretyApp.sol` – Core application logic, handles airline registration, flight registration, oracle interaction, insurance purchase and payout. Delegates data storage to `FlightSuretyData.sol`.
  - `FlightSuretyData.sol` – Persists state: airlines, flights, insurance policies, and payout balances. Provides getter functions used by the app contract.
  - Separation of concerns keeps business logic (App) distinct from data storage (Data).

- **Frontend (DApp client)** – Located in `src/dapp/`. Uses Web3.js to interact with the App contract. UI components allow users to:
  - Register airlines and fund them.
  - Register flights.
  - Purchase insurance.
  - Trigger oracle requests and withdraw payouts.

- **Backend (Oracle server)** – `src/server/` runs an Express server that connects to the local Ganache node via WebSocket. It:
  - Registers a set of oracle accounts (up to 20).
  - Listens for `OracleRequest` events emitted by the contract.
  - Randomly selects a status code and submits `submitOracleResponse` on behalf of a matching oracle.

- **Tooling**
  - Truffle manages compilation, migration, and testing.
  - Webpack bundles the DApp client for development (`npm run dapp`) and production (`npm run dapp:prod`).
  - `webpack.config.dapp.js` and `webpack.config.server.js` define entry points and hot‑module replacement for rapid iteration.

## Workflow Overview
1. **Start a local blockchain** (Ganache) on `http://127.0.0.1:7545`.
2. Run `npm install` to fetch Node dependencies.
3. Compile and migrate contracts: `truffle compile && truffle migrate --reset`.
4. Launch the DApp client: `npm run dapp` (served on `http://localhost:8080`).
5. In a separate terminal, start the oracle server: `npm run server` (listens on port 3000).
6. Use the UI to register airlines, fund them, register flights, buy insurance, and trigger oracles.
7. Run tests with `npm test` to verify contract behavior.

## Important Notes
- The contracts use Solidity ^0.4.25, so the compiler version must match (`solc` version `^0.4.24`).
- The app contract relies on the data contract address passed in the constructor; migration scripts ensure the correct linking.
- Oracle registration occurs automatically on server start; the server registers up to 20 accounts from Ganache.
- Insurance payout logic credits 1.5× the insured amount and allows the passenger to withdraw via `withdrawInsurancePayout`.

## Resources
- Project README provides a quick start guide and high‑level description.
- Truffle documentation for migration, testing, and network configuration.
- OpenZeppelin contracts are available but not currently imported due to Solidity version constraints.
