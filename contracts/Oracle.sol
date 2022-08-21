pragma solidity 0.8.12;

contract Oracle {
    address public owner;
    uint private price;

    constructor () {
        owner = msg.sender;
       
    }

    function getPrice() public view returns (uint) {
        return price;
    }

    function setPrice(uint newPrice) public {
        require(msg.sender == owner,"Oracle must be used by owner");
        price = newPrice;
    }
}