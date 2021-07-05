//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/misc/interfaces/IWETHGateway.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol";

contract Aavesurance {
    address arbiter;
    address depositor;
    address beneficiary;
    
        ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address addressLendingPool;
    
    // Mainnet
    // IWETHGateway gateway = IWETHGateway(0xDcD33426BA191383f1c9B431A342498fdac73488);
    // IERC20 aWETH = IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);
    
    //Kovan
    IWETHGateway gateway = IWETHGateway(address(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70));
    IERC20 aWETH = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);
    

    constructor(address _arbiter, address _beneficiary) public payable {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
        
        provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349)); // For Kovan
        addressLendingPool = provider.getLendingPool();
        lendingPool = ILendingPool(address(addressLendingPool));
    }
    
    function depositMoney() public payable {
        gateway.depositETH{value : msg.value}(addressLendingPool,address(this), 0);
    }

    function approve() external payable {
        require(msg.sender == arbiter);
        aWETH.approve(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70, 100e18);

        gateway.withdrawETH( addressLendingPool, type(uint256).max, address(this));
    }

    receive() external payable { }
}
