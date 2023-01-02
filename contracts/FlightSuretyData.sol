pragma solidity ^0.4.25;

contract FlightSuretyData {
    struct Airline {
        bool isRegistered;
        string name;
        uint256 amount;
    }

    struct Flight {
        string flightNumber;
        uint256 updatedTimestamp;
        address airline;
        uint8 statusCode;
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

    mapping(bytes32 => Flight) private flights;
    bytes32[] flightsLookup;

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
        _registerFlight(airlineAddress, "FLIGHT_INIT_1");
        _registerFlight(airlineAddress, "FLIGHT_INIT_2");
        _registerFlight(airlineAddress, "FLIGHT_INIT_3");
        _registerFlight(airlineAddress, "FLIGHT_INIT_4");
        _registerFlight(airlineAddress, "FLIGHT_INIT_5");
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

    function registerFlight(address airlineAddress, string flightNumber) external {
        uint256 timestamp = block.timestamp;
        bytes32 flightKey = keccak256(
            abi.encodePacked(airlineAddress, flightNumber, timestamp)
        );

        flights[flightKey] = Flight(
            flightNumber,
            timestamp,
            airlineAddress,
            STATUS_CODE_UNKNOWN
        );

        flightsLookup.push(flightKey);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }
}
