pragma solidity ^0.4.25;

contract FlightSuretyData {
    struct Airline {
        bool isRegistered;
        string name;
        uint256 amount;
    }

    struct Flight {
        string flightNumber;
        //  uint256 updatedTimestamp;
        address airline;
        uint8 statusCode;
    }

    struct Insurance {
        address passenger;
        uint256 amount;
        uint256 creditAmount;
    }

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    uint256 private constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint8 private constant STATUS_CODE_UNKNOWN = 0;

    mapping(address => Airline) airlinesRegistered;
    address[] private airlinesRegisteredLookup;
    address[] private airlinesActivatedLookup;

    mapping(bytes32 => Flight) flights;
    bytes32[] flightsLookup;

    mapping(bytes32 => Insurance[]) insuranceBought;
    mapping(address => uint256) passengerAmountToCollect;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address airlineAddress, string airlineName) public {
        contractOwner = msg.sender;
        _registerAirline(airlineAddress, airlineName);

        // initial 1st 5 flights
        string memory flightNumber = "FLIGHT_INIT_1";
        _registerFlight(airlineAddress, flightNumber);

        //   _registerFlight(airlineAddress, "FLIGHT_INIT_2");
        //   _registerFlight(airlineAddress, "FLIGHT_INIT_3");
        //   _registerFlight(airlineAddress, "FLIGHT_INIT_4");
        //   _registerFlight(airlineAddress, "FLIGHT_INIT_5");
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address airlineAddress, string name) external {
        _registerAirline(airlineAddress, name);
    }

    function _registerAirline(address airlineAddress, string name) private {
        // first ariline
        airlinesRegistered[airlineAddress] = Airline(true, name, 0);
        airlinesRegisteredLookup.push(airlineAddress);
    }

    function getRegisteredAirlines() external view returns (address[] memory) {
        return airlinesRegisteredLookup;
    }

    function getAirlineInfo(address airlineAddress)
        external
        view
        requireIsOperational
        returns (bool isRegistered, uint256 amount)
    {
       return (airlinesRegistered[airlineAddress].isRegistered, airlinesRegistered[airlineAddress].amount);
    }

    function fundAirline(address airlineAddress, uint256 amount) external {
        airlinesActivatedLookup.push(airlineAddress);

        uint256 currentAmount = airlinesRegistered[airlineAddress].amount +
            amount;
        airlinesRegistered[airlineAddress].amount = currentAmount;
        if (currentAmount >= AIRLINE_REGISTRATION_FEE) {
            airlinesActivatedLookup.push(airlineAddress);
        }
    }

    function getActivatedAirlines() external view returns (address[] memory) {
        return airlinesActivatedLookup;
    }

    function registerFlight(address airlineAddress, string flightNumber)
        external
    {
        _registerFlight(airlineAddress, flightNumber);
    }

    function _registerFlight(address airlineAddress, string flightNumber)
        private
    {
        // uint256 timestamp = block.timestamp;
        bytes32 flightKey = keccak256(
            abi.encodePacked(airlineAddress, flightNumber)
        );

        flights[flightKey] = Flight(
            flightNumber,
            //    timestamp,
            airlineAddress,
            STATUS_CODE_UNKNOWN
        );

        flightsLookup.push(flightKey);
    }

    function getFlightsLookup() external view returns (bytes32[] memory) {
        return flightsLookup;
    }

    function buyInsurance(
        bytes32 flightKey,
        uint256 amount,
        address buyer
    ) external payable {
        Insurance[] storage  ins = insuranceBought[flightKey];

        ins.push(Insurance(buyer, amount, 0));
    }

    function creditPassengerInsurance(bytes32 flightKey) external {
        Insurance[] storage ins = insuranceBought[flightKey];
        for (uint8 i = 0; i <= ins.length; i++) {
            ins[i].creditAmount = ins[i].amount + (ins[i].amount) / 2;
            ins[i].amount = 0;
            passengerAmountToCollect[ins[i].passenger] = ins[i].creditAmount;
        }
    }

    // Withdraw Funds to Insured Passanger Account.
    function withdrawInsurancePayout(address passengerAddress) external {
        uint256 amount = passengerAmountToCollect[passengerAddress];
        passengerAmountToCollect[passengerAddress] = 0;

        passengerAddress.transfer((amount)); // NOTE using payable was trowing an ERROR.
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    //  COMMENTED OUt Since it was causing compiler errors.
    //function() external payable {
    //    fund();
    // }
}
