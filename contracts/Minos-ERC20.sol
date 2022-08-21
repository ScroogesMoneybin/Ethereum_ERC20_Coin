pragma solidity 0.8.12;

contract MinosERC20 {
    uint public totalSupply;
    string public name;
    string public symbol;
    //uint8 public decimals;  (We don't include this state var. 
    //Instead we use the function decimals() to hardcode it. Cheaper from gas use perspective.)

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    mapping(address=>uint) public balances; 
    //public mapping autogenerates function to return balance of owner for us to call later

    mapping(address => mapping(address=>uint)) public allowance;
    //maps from owner to spender address to the allowance value
    //public mapping creates a function for us

    constructor(string memory _name, string memory _symbol) {
        name=_name;
        symbol=_symbol;
       
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    

    function _transfer(address sender,address recipient, uint amount) private returns (bool) {
        require(recipient!=address(0), "ERC20: transfer to the zero address"); 
        //So we don't send money and lose it at zero address

        uint senderBalance=balances[sender];
        require(senderBalance>=amount, "ERC20: transfer amount exceeds balance");
        balances[sender]=senderBalance-amount;
        balances[recipient]+=amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        uint currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance>=amount,"ERC20: transfer amount exceeds balance available");
        allowance[sender][msg.sender]=currentAllowance-amount;

        emit Approval(sender,msg.sender, allowance[sender][msg.sender]);

        return _transfer(sender, recipient, amount);
    }

    function allowSpender(address spender, uint amount) public returns (bool) {
        require(spender!=address(0), "ERC20: cannot transfer to the zero address"); 
        allowance[msg.sender][spender]=amount;
        //person who calls this function allows spender address to spend the amount on their behalf

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    

    function _mint(address to, uint amount) internal {
        //We need _mint and _burn to be internal, not private, so they can be inherited by other contracts to make the StableCoin.
         require(to!=address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balances[to] +=amount;

        emit Transfer(address(0), to, amount);
    }
    function deposit() public payable {
        _mint(msg.sender,msg.value);
        
    }

    function _burn(address sender,uint amount) internal {
        require(sender != address(0), "ERC20: burn from the zero address");
        totalSupply-=amount;
        balances[sender]-=amount;

        emit Transfer(sender, address(0), amount);
    }

    function redeem(uint amount) public {
        allowSpender(address(this),amount);
        uint currentAllowance = allowance[msg.sender][address(this)];
        require(currentAllowance>=amount,"ERC20: transfer amount exceeds balance available");
        allowance[msg.sender][address(this)]=currentAllowance-amount;

        emit Approval(msg.sender,address(this), allowance[msg.sender][address(this)]);

        _transfer(msg.sender, address(this), amount);
        _burn(address(this),amount);
        
    }
    
}