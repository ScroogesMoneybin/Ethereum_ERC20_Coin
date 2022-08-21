pragma solidity 0.8.12;
import {MinosERC20} from "./Minos-ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";
import {FixedPoint} from "./FixedPointLibrary.sol";

contract StableCoin is MinosERC20 {
    using FixedPoint for uint;
    DepositorCoin public depositorCoin;
    uint public feeRatePercent;
    Oracle public oracle;
    uint public constant INITIAL_COLLATERAL_RATIO_PERCENTAGE = 10;

    error InitialDpcCollateralRatioError(string message, uint minDepositAmount);

    constructor(uint _feeRatePercent, Oracle _oracle) MinosERC20("StableCoin","STC") { 
        feeRatePercent= _feeRatePercent;
        oracle = _oracle;
    }

    function mint() public payable {
        uint fee = _getFee(msg.value);
        uint remainingEth= msg.value-fee;
        uint mintedStableCoinAmount = remainingEth*oracle.getPrice(); 
        // Amount of ether from buyer times price of Ether in dollars
        
        _mint(msg.sender, mintedStableCoinAmount);

    }

    // function hasDepositors() public view returns (bool) {
    //     return depositorCoin.totalSupply()>0;
    // }

    function _getFee(uint ethAmount) private view returns (uint) {
        bool hasDepositors=address(depositorCoin)!=address(0) && depositorCoin.totalSupply()>0;
        //This makes sure there are Depositors to receive the fees, since fees go to holders of DepositorCoins.
        if (!hasDepositors) {
            return 0;
        }

        return ((feeRatePercent*ethAmount)/100);
    }

    function burn(uint burnedStableCoinAmount) public {
        int deficitOrSurplusUSD = _getDeficitSurplusInUSD();
        require(deficitOrSurplusUSD>=0, "STC: Cannot burn while in deficit");

        _burn(msg.sender, burnedStableCoinAmount);

        uint refundableEther = burnedStableCoinAmount/oracle.getPrice();
        uint fee = _getFee(refundableEther);
        uint PayedOutEther = refundableEther-fee;
        (bool success,)=msg.sender.call{value:PayedOutEther}(""); 
        //this pays out ether without sending ABI data. Transaction parameters are in {} annd function parameters are in ()
        require(success,"STC:Burn refund transaction failed");
    }

    function _getDeficitSurplusInUSD() private view returns (int) {
        // Tells us the value of Depositor surplus/deficit available to depositors
        uint ethContractBalanceUSD = (address(this).balance - msg.value)*oracle.getPrice();
        uint totalSTCBalanceUSD = totalSupply;
        int deficitOrSurplus = int(ethContractBalanceUSD)-int(totalSTCBalanceUSD);
        return deficitOrSurplus;
    }

    function _getDPCinUSDPrice(uint surplusUSD) private view returns (FixedPoint.Wad) {
        //return depositorCoin.totalSupply()/surplusUSD;  
        // Instead of this, we use FixedPoint Library Wad to calculate to avoid fixed point issues
        return FixedPoint.fromFraction(depositorCoin.totalSupply(),surplusUSD);
    }

    function depositCollateralBuffer() public payable {
        int deficitOrSurplusUSD = _getDeficitSurplusInUSD();

        if (deficitOrSurplusUSD<=0) {
            uint deficitInUSD = uint(deficitOrSurplusUSD * (-1));
            uint usdInEthPrice = oracle.getPrice();
            uint deficitInEth = deficitInUSD/usdInEthPrice;
            
            uint requiredInitialSurplusInUSD=(INITIAL_COLLATERAL_RATIO_PERCENTAGE  * totalSupply)/100;
            uint requiredInitialSurplusInEth = requiredInitialSurplusInUSD/usdInEthPrice;
            if (msg.value < deficitInEth + requiredInitialSurplusInEth) { 
            uint minDepositAmount = deficitInEth + requiredInitialSurplusInEth;
            revert InitialDpcCollateralRatioError("STC: Initial collateral ratio not met. Minimum amount is:",minDepositAmount);
            }

            uint newInitialSurplusInEth = msg.value - deficitInEth;
            uint newInitialSurplusInUSD = newInitialSurplusInEth*usdInEthPrice;
            depositorCoin = new DepositorCoin();
            uint mintDepositorCoinAmount =  newInitialSurplusInUSD;
            depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
            return;

        }
        uint surplusUSD = uint(deficitOrSurplusUSD);
        FixedPoint.Wad dpcInUSDPrice = _getDPCinUSDPrice(surplusUSD);
        uint mintDPCAmount = ((msg.value.MultWad(dpcInUSDPrice))/oracle.getPrice());

        depositorCoin.mint(msg.sender,mintDPCAmount);
    }

    function withdrawCollateralBuffer(uint burnDPCAmount) public {
        require(depositorCoin.balances(msg.sender)>=burnDPCAmount, "STC: Sender has insufficient Depositor Coin Funds");
        
        depositorCoin.burn(msg.sender, burnDPCAmount);

        int deficitOrSurplusUSD = _getDeficitSurplusInUSD();
        require(deficitOrSurplusUSD>0, "STC: No funds to withdraw");

        uint surplusUSD = uint(deficitOrSurplusUSD);
        FixedPoint.Wad dpcInUSDPrice = _getDPCinUSDPrice(surplusUSD);
        uint refundUSD = burnDPCAmount.MultWad(dpcInUSDPrice);
        uint refundEth = refundUSD/oracle.getPrice();

        (bool success,) = msg.sender.call{value: refundEth}("");
        require(success,"STC: Withdraw refund transaction failed");
    }
}