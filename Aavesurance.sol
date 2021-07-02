// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.6.12;

// Chainlink Price Feeds
import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// Aave
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/misc/interfaces/IWETHGateway.sol";

contract Aavesurance {
    
        
    // references to Aave LendingPoolProvider and LendingPool
    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address addressLendingPool;
    
    // WETH Gateway to handle ETH deposits into protocol
    IWETHGateway public wethGateway; 

    
    AggregatorV3Interface internal priceFeed;
    
    constructor() public {
        // Chainlink
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH-USD for Kovan
        
        // Aave
        provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349)); // For Kovan
        addressLendingPool = provider.getLendingPool();
        lendingPool = ILendingPool(address(addressLendingPool));
        // Retrieve WETH Gateway
        wethGateway = IWETHGateway(address(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70));
        // Retrieve Price Oracle
        // priceOracle = IPriceOracle(address(0xb8be51e6563bb312cbb2aa26e352516c25c26ac1));
    }
    
    struct User {
        address userAddress;
        uint256 amount;
        int256 usdValue; // Chainlink will be used to retrieve this
    }
    
    mapping (address => User) public users;
    
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // return (price, priceFeed.decimals());
        return (price);
    }
    
    function deposit() public payable {
        // users.push(User(msg.sender, msg.value, (msg.value * 2000)));
        
        address onBehalfOf = msg.sender; 
        uint16 referralCode = 0; // referralCode 0 is like none
        address wethAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); // Kovan WETH
        
        wethGateway.depositETH{value: msg.value}(addressLendingPool,address(this), referralCode);
        
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].amount = msg.value;
        users[msg.sender].usdValue = getLatestPrice();
    

    }
    
    function withdraw() public payable {
        
        // uint256 amount = users[msg.sender].amount;
        
        wethGateway.withdrawETH(addressLendingPool, 100000000000000 , address(this));
        
        // (bool success,) = msg.sender.call{value: amount}("");
        
        // require(success, "Failed to send Ether");
        
    }
}
