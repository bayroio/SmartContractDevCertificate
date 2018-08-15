/*
* Author: Edgar Herrador
* Date: August 15, 2018
* Version: 1.0
*/

pragma solidity ^0.4.24;

/// @title Supply Chain Network for Luxury Watches.
contract LuxuryWatch {
    //It will represent a Watch Manufacturer
    struct Manufacturer {
        string name;
        address manufacturerAddress;
    }
    
    //This a type for a Watch Dealer
    struct Dealer {
        string name;
        string country;
        address dealerAddress;
    }
    
    //This a type for a Customer
    struct Customer {
        string name;
        string nationality;
        address customerAddress;
    }
    
    //It is our main Asset
    struct Watch {
        uint id;
        string sku;
        string model;
        uint diameter;
        uint256 dealer_price;
        uint256 customer_price;
        bool departure;
        bool arrival;
        address manufacturer;
        address dealer;
        address customer;
    }
    
    address owner;
    
    mapping(address => Manufacturer) public manufacturers;
    mapping(address => Dealer) public dealers;
    mapping(address => Customer) public customers;
    mapping(string => bool) watches_sku; //Is used to know if a sku (watch) exist.
    mapping(string => uint) watches_id;  //Is used to know which is the index to access the watch struct into the watches array
    
    Watch[] public watches;  //In this array we can save all the watches manufactured by the Watch Manufactures
    uint total_watches;      //When a new watch is created this counter is incremented by 1. And is used like a index asociated to watches_id mapping structure
    
    event ThrowError (string message);
    
    modifier onlyOwner { 
        if (msg.sender == owner) 
            _; 
        else
            emit ThrowError ("You does not permissions to execute this service");
    }
    
    modifier onlyManufacturer { 
        if (manufacturers[msg.sender].manufacturerAddress == msg.sender)
            _;
        else
          emit ThrowError ("You does not permissions to execute this service");
    }
    
    modifier onlyDealer { 
        if (dealers[msg.sender].dealerAddress == msg.sender) 
            _; 
        else
            emit ThrowError ("You does not permissions to execute this service");   
    }
    
    modifier onlyCustomer { 
        if (customers[msg.sender].customerAddress == msg.sender) 
            _;
        else
            emit ThrowError ("You does not permissions to execute this service");
    }
    
    constructor () payable public {
        owner = msg.sender;
        total_watches = 0;
    }
    
    /*
    Create a new Manufacturer
    */
    function newManufacturer(string _manufacturerName) payable public returns(bool success) {
        require(bytes(_manufacturerName).length > 0, "You must assign a value to the input parameter _manufacturerName");
        require(msg.value >= 5 ether, "Manufacturer registration cost is 5 Ether");

        manufacturers[msg.sender].name = _manufacturerName;
        manufacturers[msg.sender].manufacturerAddress = msg.sender;

        if (msg.value > 5 ether)
            msg.sender.transfer (msg.value - 5 ether);
        
        return true;
    }
    
    /*
    Create a new Watch Dealer
    */
    function newDealer(string _dealerName, string _country) payable public returns(bool success) {
        require(bytes(_dealerName).length > 0, "You must assign a value to the input parameter _dealerName");
        require(bytes(_country).length > 0, "You must assign a value to the input parameter _country");
        require(msg.value >= 3 ether, "Dealer registration cost is 3 Ether");
        
        dealers[msg.sender].name = _dealerName;
        dealers[msg.sender].country = _country;
        dealers[msg.sender].dealerAddress = msg.sender;
            
        if (msg.value > 3 ether)
            msg.sender.transfer(msg.value - 3 ether);
        
        return true;
    }
    
    /*
    Create a new Customer
    */
    function newCustomer(string _customerName, string _nationality) payable public returns(bool success) {
        require(bytes(_customerName).length > 0, "You must assign a value to the input parameter _customerName");
        require(bytes(_nationality).length > 0, "You must assign a value to the input parameter _nationality");
        require(msg.value >= 1 ether, "Customer registration cost is 1 Ether");
        
        customers[msg.sender].name = _customerName;
        customers[msg.sender].nationality = _nationality;
        customers[msg.sender].customerAddress = msg.sender;
        
        if (msg.value > 1 ether)
            msg.sender.transfer(msg.value - 1 ether);
        
        return true;
    }
    
    /*
    The Manufacturer will use this function when you have created a new watch and want to register it on the network. 
    The input data that the function receives is the SKU, Model, and Diameter. 
    The function is "payable", the manufacturer has to pay 1 Ether, if he pays more it is returned. 
    The paid Ether stays as funds for the smart contract.
    */
    function newWatchManufactured (string _sku, string _model, uint _diameter) payable onlyManufacturer public returns (bool success) {
        require(bytes(_sku).length > 0, "You must assign a value to the input parameter _sku");
        require(bytes(_model).length > 0, "You must assign a value to the input parameter _model");
        require(_diameter >= 30 && _diameter < 50, "You must assign a value greater than or equal to 30");
        require(msg.value >= 1 ether, "Service cost is 1 Ether");
        require(!watches_sku[_sku], "The SKU already exists");
        
        watches.push(Watch({id:total_watches, sku: _sku, model: _model, diameter: _diameter, dealer_price: 0,
            customer_price: 0, departure: false, arrival: false,
            manufacturer: msg.sender, dealer: address(0), customer: address(0)}));
        
        watches_sku[_sku] = true;
        watches_id[_sku] = total_watches;
        total_watches += 1;
            
        if (msg.value > 1 ether)
            msg.sender.transfer(msg.value - 1 ether);
        
        return true;
    }
    
    /*
    This function will allow the Manufacturer to indicate that a watch has been sent to the Distributor or Dealer for sale. 
    The entry data is SKU, dealer price (always greater than 5 Ether) and the address of the distributor. 
    The function is "payable", the manufacturer has to pay 1 Ether, if he pays more it is returned. 
    The paid Ether stays as funds for the smart contract.
    */
    function watchMovementDeparture(string _sku, uint256 _dealer_price, address _distributor) payable onlyManufacturer public returns (bool success) {
        require(msg.value >= 1 ether, "Service cost is 1 Ether");
        require(bytes(_sku).length > 0, "You must assign a value to the input parameter _sku");
        require(_dealer_price > 5, "A value greater than 5 is necessary for dealer price");
        require(_distributor != address(0x0), "You need to specify the address of the dealer");
        require(watches_sku[_sku], "the watch with the associated SKU must exist in order to assign it to a dealer");

        watches[watches_id[_sku]].dealer = _distributor;
        watches[watches_id[_sku]].dealer_price = _dealer_price * (1 ** 18);
        watches[watches_id[_sku]].departure = true;
            
        if (msg.value > 1 ether)
            msg.sender.transfer(msg.value - 1 ether);
    
        return true;
    }
    
    /*
    This function will be used by the Distributor or Dealer to indicate that the watch was received. 
    The input parameter is SKU. The function is "payable", the distributor has to pay 1 Ether, if you pay more it is returned. 
    The paid Ether stays as funds for the smart contract.
    */
    function watchMovementArrival(string _sku) payable onlyDealer public returns (bool success) {
        require(bytes(_sku).length > 0, "You must assign a value to the input parameter _sku");
        require(msg.value >= 1 ether, "Service cost is 1 Ether");
        require(watches_sku[_sku], "the watch with the associated SKU must exist in order to indicate that it was received by the distributor");

        watches[watches_id[_sku]].arrival = true;
            
        if (msg.value > 1 ether)
            msg.sender.transfer(msg.value - 1 ether);
        
        return true;
    }
    
    /*
    The Distributor will register a watch for sale. The public price that the distributor assigns to the watch is greater than the distribution price assigned 
    by the manufacturer to the same watch. The input parameters are SKU and PublicPrice. 
    The function is "payable", the distributor has to pay 1 Ether, if you pay more it is returned. The paid Ether stays as background for the smart contract.
    */
    function registerWatchForSale(string _sku, uint256 _customer_price) payable onlyDealer public returns (bool success) {
        require(msg.value >= 1 ether, "Service cost is 1 Ether");
        require(bytes(_sku).length > 0, "You must assign a value to the input parameter _sku");
        require(_customer_price > 5, "A value greater than 1 is necessary for customer price");
        require(watches_sku[_sku], "the watch with the associated SKU must exist in order to register it for sale");

        if (watches[watches_id[_sku]].dealer_price >= _customer_price)
            revert();
            
        if (watches[watches_id[_sku]].arrival == false)
            revert();
        
        watches[watches_id[_sku]].customer_price = _customer_price * (1 ** 18);

        if (msg.value > 1 ether)
            msg.sender.transfer(msg.value - 1 ether);
        
        return true;
    }
    
    /*
    A customer can buy a watch. The function is "payable", if he pays more it is returned. 
    1 Ether remains as background for the smart contract. The remaining Ethers are distributed as follows: 
    50% for the Distributor or Dealer and 50% for the Manufacturer.
    */
    function buyWatch(string _sku) payable onlyCustomer public returns (bool success) {
        require(bytes(_sku).length > 0, "You must assign a value to the input parameter _sku");
        require(watches_sku[_sku], "the watch with the associated SKU must exist in order to sell it");
        //require(msg.value == watches[watches_id[_sku]].customer_price, "You are paying more Ethers than the clock costs");
        
        watches[watches_id[_sku]].customer = msg.sender;
        
        //uint256 _balance;
        /*if (msg.value > watches[watches_id[_sku]].customer_price * (1 ** 18)) {
            //_balance = msg.value - (watches[watches_id[_sku]].customer_price * (1 ** 18));
            //msg.sender.transfer(_balance * (1 ** 18));
            msg.sender.transfer(msg.value - (watches[watches_id[_sku]].customer_price * (1 ** 18)));
            watches[watches_id[_sku]].manufacturer.transfer((msg.value - 1 ether)/2);
            watches[watches_id[_sku]].dealer.transfer((msg.value - 1 ether)/2);
            
            return true;
        }*/
        
        watches[watches_id[_sku]].manufacturer.transfer((msg.value - 1 ether)/2);
        watches[watches_id[_sku]].dealer.transfer((msg.value - 1 ether)/2);
        
        return true; 
    }
    
    /*
    This function allows to withdraw money and transfer it to the network owner.
    */
    function withDraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    /*
    This function allows to withdraw money and transfer it to the network owner, and eliminate the contract
    */
    function destructNetwork() onlyOwner public {
        selfdestruct(owner);
    }
}