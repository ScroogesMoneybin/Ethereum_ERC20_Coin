pragma solidity 0.8.12;
import {MinosERC20} from "./Minos-ERC20.sol";

contract DepositorCoin is MinosERC20 {
    address public owner;

    constructor()  MinosERC20("DepositorCoin","DPC") {
        owner = msg.sender;
    }

    function mint(address to, uint amount) public {
        require(msg.sender==owner, "DPC: Only owner can mint");
        _mint(to, amount);
    }

    function burn(address from, uint amount) public {
        require(msg.sender==owner, "DPC: Only owner can burn");
        _burn(from, amount);
    }
}