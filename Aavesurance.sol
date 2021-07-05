//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;


// Chainlink Price Feeds
import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// Aave
import "./IERC20.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/misc/interfaces/IWETHGateway.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol";

// Uniswap 
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract Aavesurance {
    
    //Chainlink
    AggregatorV3Interface internal priceFeed;

    // Aave 
    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address addressLendingPool;
    IWETHGateway gateway = IWETHGateway(address(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70));
    IERC20 aWETH = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);
    IERC20 aDai = IERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);
    IERC20 dai = IERC20(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    
    // Uniswap 
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // v2 Router
    IUniswapV2Router02 public uniswapRouter;
    address private multiDaiKovan = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD; // Aave DAI
    
    // For smart contract
    struct User {
        address userAddress;
        uint256 amount;
        int256 usdValue; // Chainlink will be used to retrieve this
    }
    
    mapping (address => User) public users;
    
    // Smart contract variables for Aave
    uint256 public depositPercantage = 6666; // 66.66% is deposited into Aave
    
    
    constructor() public payable {
        // Chainlink
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH-USD for Kovan

        // Aave for Kovan
        provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349)); // For Kovan
        addressLendingPool = provider.getLendingPool();
        lendingPool = ILendingPool(address(addressLendingPool));
    
        
        // Uniswap
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }
    
    // 
    // Constract
    // Starts
    // Here
    // 
    
    function calculate(uint256 amount) public view returns (uint256){
        return amount * depositPercantage / 10000;
    }
    
    function calculate33(uint256 amount) public view returns (uint256){
        return amount * 3333 / 10000;
    }
    
    // Chainlink function to get latest prices
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // return (price, priceFeed.decimals());
        return (price / 100000000 );
        // Returns Integer value without decimals
    }
    
    // Deposit Money 
    function depositMoney() public payable {
        // Storing user data in smart contract
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].amount = users[msg.sender].amount + msg.value;
        users[msg.sender].usdValue = getLatestPrice();
        
        // Depositing ETH to WETHGateway which will send WETH to Aave Lending Pool
        // 66.66% of ETH is deposited into Aave directly
        gateway.depositETH{value : calculate(msg.value)}(addressLendingPool,address(this), 0);
        convertEthToDai();
        // shortEth();
    }

    // Approve spending of WETH by pool and withdraw it to contract
    function approve() external payable {
        aWETH.approve(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70, 1000000000000000000000000000000000000);
        gateway.withdrawETH( addressLendingPool, users[msg.sender].amount, address(this));
    }
    
    // Uniswap Swap from Weth to Dai
    function convertEthToDai() public payable {
        uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapETHForExactTokens{ value: calculate33(msg.value) }(getEstimatedETHforDAI( ( calculate33(msg.value) ) )[1], getPathForETHtoDAI(), address(this), deadline);
        
        // refund leftover ETH to user
        // (bool success,) = msg.sender.call{ value: address(this).balance }("");
        // require(success, "refund failed");
    }
    
    function getEstimatedETHforDAI(uint ethAmount) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(ethAmount, getPathForETHtoDAI());
    }
    
    // Uniswap function
    function getPathForETHtoDAI() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = multiDaiKovan;
        
        return path;
    }
    
    function shortEth() public payable {
        dai.approve(address(lendingPool), 1000000000000000000000000000000000000);
        lendingPool.deposit(address(dai), dai.balanceOf(address(this)), address(this),0);
        lendingPool.setUserUseReserveAsCollateral(address(dai), true);
    }
    
    function shortEth2() public payable {
        gateway.borrowETH(addressLendingPool, 1000000000000000, 1, 0);
    }

    receive() external payable { }
}
