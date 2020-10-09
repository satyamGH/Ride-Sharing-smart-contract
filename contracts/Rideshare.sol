pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

contract Rideshare is ERC20, Ownable{  

    address public arbiter;

    struct RideOffer{ 
        address driver;
        uint state;
        uint createdAt;
        uint confirmedAt;
        uint deadlineAt;
        uint departAt;
        uint capacity;
        uint long1;
        uint lat1;
        uint long2;
        uint lat2;
        uint minFee;
        mapping (address => RideSeeker) passengers; 
        address[] passengerAccts;
    }

    struct RideSeeker {
        address passenger;
        uint state;
        uint confirmedAt;
        uint long1;
        uint lat1;
        uint long2;
        uint lat2;
        uint maxFee;
    } 
  
    RideOffer[] public rides; 
    
    mapping (address => uint) passengerRideCount;
    mapping (address => uint) reputation; 
    mapping (address => uint) reputationCount;

    mapping (address => uint) passengerID; 

  
    function createRide(
        uint _confirmedAt,
        uint _deadlineAt,
        uint _departAt,
        uint _capacity,
        uint _long1,
        uint _lat1,
        uint _long2,
        uint _lat2,
        uint _minFee) 
        public{
        address[] memory _passengerAccts;
        
        payReputation();

        rides.push(RideOffer(
            msg.sender, 
            1,
            block.timestamp, 
            _confirmedAt, 
            _deadlineAt, 
            _departAt, 
            _capacity, 
            _long1, 
            _lat1, 
            _long2, 
            _lat2, 
            _minFee,  
            _passengerAccts));
    }//"Ride offer created";
 
    function joinRide(
        uint _long1, 
        uint _lat1, 
        uint _long2, 
        uint _lat2, 
        uint _rideNumber)
        public {         
        require(passengerRideCount[msg.sender] == 0, "Ride already joined.");

        payReputation();
        
        RideOffer storage selectRide = rides[_rideNumber];
        rides[_rideNumber].passengerAccts.push(msg.sender)-1;
        RideSeeker storage passenger = selectRide.passengers[msg.sender];
        passenger.passenger = msg.sender;
        passenger.confirmedAt = block.timestamp;
        passenger.long1 = _long1;
        passenger.lat1 = _lat1;
        passenger.long2 = _long2;
        passenger.lat2 = _lat2;

        passengerID[msg.sender] = selectRide.passengerAccts.length;
        passengerRideCount[msg.sender]++;

    }//"Passenger joined ride. Waiting for departure";

    function verifyTripStartPassenger(uint _rideNumber) public {
        uint _passengerID = passengerID[msg.sender];
        require(msg.sender == rides[_rideNumber].passengerAccts[_passengerID], "Sender not authorized.");
        //require(that the passenger coordinates are nearby the agreed starting location)
        rides[_rideNumber].passengers[msg.sender].state == 2;
        while(rides[_rideNumber].state != 2){
            depositFeeToContract(_rideNumber);
        }
    }//Passenger is ready to depart.;

    function verifyTripStartDriver(uint _rideNumber) public view {
        require(msg.sender == rides[_rideNumber].driver, "Sender not authorized.");
        //require(that the driver coordinates are in the same area as the passenger coordinates)
        rides[_rideNumber].state == 2;
    }//"Driver is ready to depart.;
    
    function depositFeeToContract(uint _rideNumber) public payable {
        require(rides[_rideNumber].passengers[msg.sender].state == 2 && rides[_rideNumber].state == 2);
        require(msg.value >= rides[_rideNumber].minFee, "Funds not sufficient."); 
    
        transfer(address(this), msg.value); 
        rides[_rideNumber].state == 3;
        rides[_rideNumber].passengers[msg.sender].state == 3;
    }

    function verifyTripEndPassenger(uint _rideNumber) public view{
        //require(that the driver coordinates are in the same area as the end location)
        rides[_rideNumber].passengers[msg.sender].state == 4;
    }//"Trip ended. Passenger has no disputes. Waiting on driver inspection";


    function verifyTripEndDriver(uint _rideNumber) public {
        require(msg.sender == rides[_rideNumber].driver, "Sender not authorized");
        rides[_rideNumber].passengers[msg.sender].state == 4;
        transfer(rides[_rideNumber].driver, address(this).balance);
    }//"Trip ended. No disputes. Funds successfully transferred";

    function payReputation() internal {
        reputation[msg.sender] = reputation[msg.sender] - 5; 
    }

    /* When there is arbitry
    function payoutSeller(uint _rideNumber) public {
        require (msg.sender == arbiter || msg.sender == rides[_rideNumber].passengers[msg.sender], "Sender not authorized");
        transfer(rides[_rideNumber].driver, address(this).balance);
        
    }
    function refundBuyer(uint _rideNumber) public {
        require (msg.sender == arbiter, "Sender not authorized");
        address  to = rides[_rideNumber].passengers[rides[_rideNumber].passengerAccts(passengerID)];
        transfer(to, address(this).balance);
        
    }*/

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }



}

