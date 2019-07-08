pragma solidity ^ 0.5 .0;

/*
    The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
 */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint PRICE_TICKET = 100 wei;
    constructor() public {
        owner = msg.sender;
    }
    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public eventID;
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Buyers {
        address[] buyersAddresses;
        mapping(address => uint) amountOfTickets;
    }

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        Buyers buyers;
        bool isOpen;
    }
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory website, uint numberOfTickets) public onlyOwner returns(uint) {
        Buyers memory buyers;
        Event memory newEvent = Event(description, website, numberOfTickets, 0, buyers, true);
        uint newEventID = eventID;
        events[newEventID] = newEvent;
        emit LogEventAdded(description, website, numberOfTickets, newEventID);
        eventID += 1;
        return newEventID;
    }
    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventID) public view returns(string memory description, string memory website, uint numberOfTickets, uint sales, bool isOpen) {
        return (events[_eventID].description, events[_eventID].website, events[_eventID].totalTickets, events[_eventID].sales, events[_eventID].isOpen);
    }
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventID, uint numberOfTickets) payable public {
        require(events[_eventID].isOpen == true, "Selected event is not open");
        require(msg.value >= PRICE_TICKET * numberOfTickets, "Msg.value is insufficient");
        require(events[_eventID].totalTickets >= numberOfTickets, "Insufficiente tickets available");
        Event storage selectedEvent = events[_eventID];
        selectedEvent.buyers.amountOfTickets[msg.sender] += numberOfTickets;
        selectedEvent.buyers.buyersAddresses.push(msg.sender);
        selectedEvent.sales += numberOfTickets;
        selectedEvent.totalTickets -= numberOfTickets;
        // To avoid integer underflow on transfer value
        if (msg.value > PRICE_TICKET * numberOfTickets) {
            msg.sender.transfer(msg.value - (PRICE_TICKET * numberOfTickets));
        }
        emit LogBuyTickets(msg.sender, _eventID, numberOfTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventID) public {
        Event storage selectedEvent = events[_eventID];
        require(selectedEvent.buyers.amountOfTickets[msg.sender] > 0, "Msg.sender don't have any tickets for selected event");
        uint refundedTickets = selectedEvent.buyers.amountOfTickets[msg.sender];
        selectedEvent.sales -= refundedTickets;
        selectedEvent.buyers.amountOfTickets[msg.sender] -= refundedTickets;
        msg.sender.transfer(refundedTickets * PRICE_TICKET);
        emit LogGetRefund(msg.sender, _eventID, refundedTickets);
    }
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventID) public view returns(uint) {
        return events[_eventID].buyers.amountOfTickets[msg.sender];
    }
    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventID) public onlyOwner {
        events[_eventID].isOpen = false;
        uint balanceToTransfer = events[_eventID].sales * PRICE_TICKET;
        owner.transfer(balanceToTransfer);
        emit LogEndSale(owner, balanceToTransfer, _eventID);
    }
}