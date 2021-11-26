pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address=>bool) private addressApp;
    uint private fundThreshold;
    uint private creditFactorx10;
    uint private maxCredit;
    uint private delayedStatus;

    struct Airline{
        bool isRegistered;
        mapping(address=>bool) voters;
        uint voterCount;
        bool isFunded;
        uint funds;
    }
    struct Flight{
        bool isRegistered;
        address airlineID; 
        mapping(address=>bool) customerInsured;
        mapping(address=>uint) customerCredit;
        uint8 status;
    }

    mapping(address=>Airline) private airlineList;
    mapping(bytes32=>Flight) private flightList;
    uint private airlineCount;

    constructor() public {
        contractOwner = msg.sender;
        operational = true;
        airlineList[msg.sender].isRegistered = true;
        airlineCount = 1;
        delayedStatus = 20;

        fundThreshold = 10*10^18;
        creditFactorx10 = 15;
        maxCredit = 1.5*10^18;
        addressApp[msg.sender] = true;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(address airlineID);
    event AirlineFunded(address airlineID);
    event FlightRegistered(bytes32 flightKey);
    event StatusUpdate(bytes32 flightKey, uint status);
    event InsurancePayed(bytes32 flightKey, uint status, address customerID);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // High level modifiers
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAppContract() {
        require(addressApp[msg.sender]==true, "This function is not called from an authorized App");
        _;
    }
 
    // Airline modifiers
    modifier requireRegistered(address airlineID) {
        require(airlineList[airlineID].isRegistered, "Airline is not registered");
        _;  
    }
    
    modifier requireNotRegistered(address airlineID) {
        require(!airlineList[airlineID].isRegistered, "Airline is already registered");
        _;  
    }

    modifier requireFunded(address airlineID) {
        require(airlineList[airlineID].isFunded, "Airline is not funded");
        _;  
    }

    modifier requireNotFunded(address airlineID) {
        require(airlineList[airlineID].isFunded, "Airline is already funded");
        _;  
    }
    
    modifier requireNonVoted(address airlineID, address voterID) {
        require(!airlineList[airlineID].voters[voterID], "Airline has already voted");
        _;  
    }
    
    // Customer modifiers
    modifier requireInsured(bytes32 flightKey, address customerID){
        require(flightList[flightKey].customerInsured[customerID], "Customer has not bought insurance");
        _;
    }

    modifier registeredFlight(bytes32 flightKey){
        require(flightList[flightKey].isRegistered, "Flight is not registered");
        _;
    }
    
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function getOwner() external view returns(address) {
        return contractOwner;
    }
    function isOperational() external view returns(bool) {
        return operational;
    }

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function setThreshold(uint newThreshold) external requireContractOwner {
        fundThreshold = newThreshold;
    }
    
    function authorizeCaller(address appID, bool authorized) external requireContractOwner {
        addressApp[appID] = authorized;
    }

    function getAirlineCount() external view returns(uint){
        return airlineCount;
    }
    
    function getVote(address airlineID, address voterID) external view returns(bool){
        return airlineList[airlineID].voters[voterID];
    }

    function getFunds(address airlineID) external view returns(uint){
        return airlineList[airlineID].funds;
    }
    
    function getAirlineRegistered(address airlineID) external view returns(bool){
        return airlineList[airlineID].isRegistered;
    }
    
    function getVoterCount(address airlineID) external view returns(uint){
        return airlineList[airlineID].voterCount;
    }



    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   // FUNCTIONS CALLED BY THE AIRLINES   
    function addVoter(address airlineID, address voterID) external requireIsOperational requireAppContract 
        requireRegistered(voterID) requireFunded(voterID) requireNonVoted(airlineID, voterID) requireNotRegistered(airlineID) {
            airlineList[airlineID].voters[voterID] = true;
            airlineList[airlineID].voterCount++;
    }

    function registerAirline(address airlineID, address voterID) external requireIsOperational requireAppContract requireRegistered(voterID) requireFunded(voterID) requireNotRegistered(airlineID) {
        airlineList[airlineID].isRegistered = true;
        airlineCount++;
        emit AirlineRegistered(airlineID);     
    }

    function addFunds(address airlineID) external payable requireIsOperational requireAppContract{
        airlineList[airlineID].funds = airlineList[airlineID].funds + msg.value;
    }

    function registerFunded(address airlineID) external payable requireIsOperational requireAppContract requireNotFunded(airlineID){
        require(airlineList[airlineID].funds>fundThreshold, "Airline does not have enough funds");
        airlineList[airlineID].isFunded = true;
        emit AirlineFunded(airlineID);
    }

    function registerFlight(bytes32 flightKey, address airlineID) external requireIsOperational requireAppContract requireRegistered(airlineID) requireFunded(airlineID){
        flightList[flightKey].airlineID = airlineID;
        emit FlightRegistered(flightKey);
    }

    function statusFlight(bytes32 flightKey, uint8 status) external requireIsOperational requireAppContract{
        flightList[flightKey].status = status;
        emit StatusUpdate(flightKey,status);
    }




    // FUNCTIONS CALLED BY THE CUSTOMER  
    function buyInsurance(bytes32 flightKey, address customerID) external payable requireIsOperational requireAppContract registeredFlight(flightKey){
        require(flightList[flightKey].customerCredit[customerID] + msg.value*creditFactorx10/uint256(10)<=uint256(maxCredit), "Customer is trying to buy more than the maximum insurance");
        flightList[flightKey].customerCredit[customerID] = flightList[flightKey].customerCredit[customerID] + msg.value*creditFactorx10/uint256(10);

        require(!flightList[flightKey].customerInsured[customerID], "Passanger already insured");
        flightList[flightKey].customerInsured[customerID] = true;
    }

    function payInsurance(bytes32 flightKey, address customerID) external requireIsOperational requireAppContract registeredFlight(flightKey) requireInsured(flightKey, customerID){
        require(flightList[flightKey].status==delayedStatus, "This flight has not experienced any delay");
        uint payment = flightList[flightKey].customerCredit[customerID];
        flightList[flightKey].customerCredit[customerID] = 0;
        customerID.transfer(payment);
        emit InsurancePayed(flightKey,flightList[flightKey].status,customerID);
    }   
}

