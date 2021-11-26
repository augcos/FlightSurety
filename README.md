# Fligth Surety Project
## Introduction
This code is part of the Flight Surety Project for the Blockchain Developer Nanodegree by Udacity. The goal of this project is to implement a decentralized app on the ethereum network. For this project, a flight purchasing and insurace system was developed and deployed to a local ethereum blockchain.

## Development
The project vas developed using the following software:
```
Node.js         v10.19.0
npm             v8.1.1
Truffle         v5.4.14
OpenZeppelin    v2.3.0
Solidity        v0.5.16
```

## How to install?
Before running this project in your local system, you will need to have Node.js, npm and Truffle preinstalled. After cloning this repository, run the following command to install all the necessary dependencies:
```
npm install
```

## Test the project
If you want to modify the testing of the project, you can modify the TestSupplyChain.js file in the Test folder. To test the project, run the following commands:
```
truffle compile
truffle test
``` 

## Run the project
First start the Truffle development enviroment. Run the following command, which will launch a local ethereum blockchain on 127.0.0.1:9454 as well as the development enviroment:
```
truffle develop
```
Next, compile the code and deploy from the Truffle development enviroment using the following commands:
```
compile
migrate --reset
```
Then, run the frontend from the terminal using the command:
```
npm run dev
```

### Run DApp locally
After exiting the truffle command line run the following command to launch the frontend:
```
    npm run dev
```


