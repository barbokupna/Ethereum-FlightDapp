pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    // INterface to the Data Contract
    IFlightSuretyData flightSuretyDataContract;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    uint256 private constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256 private constant PASSANGER_MAX_INSURANCE = 1 ether;
    uint256 private constant AIRLINE_REGISTRATION_VOTE = 4;

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    mapping(address => address[]) airlinesToRegister;

    // Constructor
    constructor(address contractData) public {
        contractOwner = msg.sender;
        flightSuretyDataContract = IFlightSuretyData(contractData);
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
        // Modify to call data contract's status
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

    // Check if the airline being registered is already not registered.
    modifier requireAirlineNOTRegistered(address airlineAddress) {
        (bool isRegistered, ) = flightSuretyDataContract.getAirlineInfo(
            airlineAddress
        );
        require(!isRegistered, "Airline Already Registered");
        _;
    }

    // Check if the airline registering NEW one is Active
    modifier requireAirlineActive(address airlineAddress) {
        (, uint256 amount) = flightSuretyDataContract.getAirlineInfo(
            airlineAddress
        );
        bool isActive = (amount >= AIRLINE_REGISTRATION_FEE);
        require(isActive, "Airline NOT Active. Can't Register New Airline.");
        _;
    }

    // UTLITY FUNCTIONS:
    function isOperational() public returns (bool) {
        return operational;
    }

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    // Register New Airline:
    // - IF Active Airline > 5 => Need Consensus of 50 % of the Active Airline
    function registerAirline(address airlineAddress, string name)
        external
        requireIsOperational
        requireAirlineNOTRegistered(airlineAddress)
        returns (bool success, uint256 votes)
    {
        address[] memory activeAirline = flightSuretyDataContract
            .getRegisteredAirlines();
        if (activeAirline.length <= AIRLINE_REGISTRATION_VOTE) {
            flightSuretyDataContract.registerAirline(airlineAddress, name);
        } else {
            address[] storage votedAirlines = airlinesToRegister[
                airlineAddress
            ];
            for (uint8 i = 0; i < votedAirlines.length; i++) {
                if (votedAirlines[i] == msg.sender) {
                    require(false, "Airline Already Voted!");
                }
            }
            votedAirlines.push(msg.sender);
            if (votedAirlines.length > (activeAirline.length / 2)) {
                flightSuretyDataContract.registerAirline(airlineAddress, name);
            } else {
                require(
                    false,
                    "Consensus of 50% Votes from Active Airlines NOT met."
                );
            }
        }
        return (true, 0);
    }

    // Get Registered Airlines
    function getRegisteredAirlines()
        external
        view
        requireIsOperational
        returns (address[] memory airlineAddresses)
    {
        return flightSuretyDataContract.getRegisteredAirlines();
    }

    // Fund Airline. 10 ETH required to Make it Active.
    function fundAirline(uint256 amount)
        external
        requireIsOperational
        requireAirlineActive(msg.sender)
    {
        // Check value, transfer to contract.
        require(msg.sender.balance >= amount, "Not Enought Funds.");
        address(flightSuretyDataContract).transfer(amount);

        // passengerAddress.transfer((amount)); // NOTE using payable was trowing an ERROR.

        flightSuretyDataContract.fundAirline(msg.sender, amount);
    }

    function getActivatedAirlines()
        external
        view
        requireIsOperational
        returns (address[] memory airlineAddresses)
    {
        return flightSuretyDataContract.getActivatedAirlines();
    }

    function registerFlight(address airlineAddress, string flightNumber)
        external
        requireIsOperational
        requireAirlineActive(msg.sender)
        returns (address votes)
    {
        flightSuretyDataContract.registerFlight(airlineAddress, flightNumber);

        return (airlineAddress);
    }

    function getRegisteredFlights()
        external
        view
        requireIsOperational
        returns (bytes32[] memory)
    {
        return flightSuretyDataContract.getFlightsLookup();
    }

    function buyInsurance(bytes32 flightKey, uint256 amount)
        external
        requireIsOperational
    {
        require(
            amount <= PASSANGER_MAX_INSURANCE,
            "MAX Passenget Insurance to Purchase = 1 Eth"
        );

        require(
            amount <= msg.sender.balance,
            "Not Enought Funds To Purchase The Insurance"
        );
        flightSuretyDataContract.buyInsurance(flightKey, amount, msg.sender);
    }

    function withdrawInsurancePayout() external requireIsOperational {
        flightSuretyDataContract.withdrawInsurancePayout(msg.sender);
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal requireIsOperational {
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
            bytes32 key = keccak256(
                abi.encodePacked(airline, flight, timestamp)
            );
            flightSuretyDataContract.creditPassengerInsurance(key);
        }
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3]) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request" 
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }
        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }
        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;
        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }
    // endregion
}

interface IFlightSuretyData {
    // airline
    function registerAirline(address airlineAddress, string name) external;

    function getRegisteredAirlines() external view returns (address[] memory);

    function fundAirline(address airlineAddress, uint256 amount) external;

    function getActivatedAirlines() external view returns (address[] memory);

    function getAirlineInfo(address airlineAddress)
        external
        view
        returns (bool isRegistered, uint256 amount);

    // flights
    function registerFlight(address airlineAddress, string flightNumber)
        external;

    function getFlightsLookup() external view returns (bytes32[] memory);

    function getFlightInfo(bytes32 key)
        external
        view
        returns (
            string flight,
            uint256 timestamp,
            address airline,
            uint8 statusCode
        );

    // Insurance
    function buyInsurance(
        bytes32 flightKey,
        uint256 amount,
        address buyer
    ) external;

    function creditPassengerInsurance(bytes32 flightKey) external;

    function withdrawInsurancePayout(address passengerAddress) external;
}
