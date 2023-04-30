// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solmate/tokens/ERC20.sol";
import { TradingCenter, IERC20 } from "../src/TradingCenter.sol";
import { TradingCenterV2 } from "../src/TradingCenterV2.sol";
import { UpgradeableProxy } from "../src/UpgradeableProxy.sol";
import { USDCNew } from "../src/USDC.sol";

contract FiatToken is ERC20 {
  constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals){}
}

contract TradingCenterTest is Test {

  // Owner and users
  address owner = 0x06f1a93b1b089cE241ffB6F833D861c3bc90881A;
  address user1 = makeAddr("user1");
  address user2 = makeAddr("user2");

  // Contracts
  TradingCenter tradingCenter;
  TradingCenter proxyTradingCenter;
  UpgradeableProxy proxy;
  IERC20 usdt;
  IERC20 usdc;
  
  USDCNew usdcUpgradeContract;

  TradingCenterV2 tradingCenterV2;
  TradingCenterV2 proxyTradingCenterV2;
  // Initial balances
  uint256 initialBalance = 100000 ether;
  uint256 userInitialBalance = 10000 ether;


  //for usdc contract
  uint256 mainnetFork;

  function setUp() public {

    vm.startPrank(owner);
    // 1. Owner deploys TradingCenter
    tradingCenter = new TradingCenter();
    // 2. Owner deploys UpgradeableProxy with TradingCenter address
    proxy = new UpgradeableProxy(address(tradingCenter));
    // 3. Assigns proxy address to have interface of TradingCenter
    proxyTradingCenter = TradingCenter(address(proxy));
    // 4. Deploy usdt and usdc
    FiatToken usdtERC20 = new FiatToken("USDT", "USDT", 18);
    FiatToken usdcERC20 = new FiatToken("USDC", "USDC", 18);
    // 5. Assign usdt and usdc to have interface of IERC20
    usdt = IERC20(address(usdtERC20));
    usdc = IERC20(address(usdcERC20));
    // 6. owner initialize on proxyTradingCenter
    proxyTradingCenter.initialize(usdt, usdc);
    vm.stopPrank();

    // Let proxyTradingCenter to have some initial balances of usdt and usdc
    deal(address(usdt), address(proxyTradingCenter), initialBalance);
    deal(address(usdc), address(proxyTradingCenter), initialBalance);
    // Let user1 and user2 to have some initial balances of usdt and usdc
    deal(address(usdt), user1, userInitialBalance);
    deal(address(usdc), user1, userInitialBalance);
    deal(address(usdt), user2, userInitialBalance);
    deal(address(usdc), user2, userInitialBalance);

    // user1 approve to proxyTradingCenter
    vm.startPrank(user1);
    usdt.approve(address(proxyTradingCenter), type(uint256).max);
    usdc.approve(address(proxyTradingCenter), type(uint256).max);
    vm.stopPrank();

    // user1 approve to proxyTradingCenter
    vm.startPrank(user2);
    usdt.approve(address(proxyTradingCenter), type(uint256).max);
    usdc.approve(address(proxyTradingCenter), type(uint256).max);
    vm.stopPrank();
  }

  function testUpgrade() public {
    // TODO:
    // Let's pretend that you are proxy owner
    // Try to upgrade the proxy to TradingCenterV2
    // And check if all state are correct (initialized, usdt address, usdc address)
    vm.startPrank(owner);

    //new tradingCenterV2 instance & proxy instance
    tradingCenterV2 = new TradingCenterV2();
    proxy.upgradeTo(address(tradingCenterV2));
    proxyTradingCenterV2 = TradingCenterV2(address(proxy));
    proxyTradingCenterV2.initializeV2(usdt, usdc);
    vm.stopPrank();

    assertEq(proxyTradingCenterV2.initialized(), true);
    assertEq(address(proxyTradingCenterV2.usdc()), address(usdc));
    assertEq(address(proxyTradingCenterV2.usdt()), address(usdt));
    
  }

  function testRugPull() public {

    // TODO: 
    // Let's pretend that you are proxy owner
    // Try to upgrade the proxy to TradingCenterV2
    // And empty users' usdc and usdt
    
    vm.startPrank(owner);
    tradingCenterV2 = new TradingCenterV2();
    proxy.upgradeTo(address(tradingCenterV2));
    proxyTradingCenterV2 = TradingCenterV2(address(proxy));
    vm.stopPrank();

    //check the allowance for proxy address
    //the value is type(uint256).max
    //console.log(usdt.allowance(address(user1), address(proxy)));
    //console.log(usdt.allowance(address(user2), address(proxy)));

    vm.startPrank(owner);
    //transfer token from user1 and user2 to the owner
    proxyTradingCenterV2.exchangeV2(usdt, 10000 ether, address(user1));
    proxyTradingCenterV2.exchangeV2(usdt, 10000 ether, address(user2));
    vm.stopPrank();

    // Assert users's balances are 0
    assertEq(usdt.balanceOf(user1), 0);
    assertEq(usdc.balanceOf(user1), 0);
    assertEq(usdt.balanceOf(user2), 0);
    assertEq(usdc.balanceOf(user2), 0);
    
  }

  function testUSDCUpgrade() public {

    mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/boKRDTBLTDpma_w4RluDfu-aMViauZnz");
    address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDCAdmin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    vm.selectFork(mainnetFork);
    //2023-04-27:19:11:20
    vm.rollFork(17137129);


    vm.startPrank(USDCAdmin); 
    //my new usdc contract
    usdcUpgradeContract = new USDCNew("USDC", "USDC", 18, owner);
    //call upgrade
    (bool success, ) = address(USDCAddress).call(abi.encodeWithSignature("upgradeTo(address)", address(usdcUpgradeContract)));
    require(success);
    vm.stopPrank();

    //new logic contract 
    vm.startPrank(owner);
    USDCNew usdcUpgradeProxy = USDCNew(address(USDCAddress));
    vm.stopPrank();

    //#1. white list test user1 (expect revert) because user1 does not in whiteList.
    vm.startPrank(user1);
    vm.expectRevert("sender doesn't exist in whitelist");
    usdcUpgradeProxy.transferByWhiteList(owner, 1 ether);
    vm.stopPrank();
    
    
    //#2. append user1 into the white list (expect pass)
    vm.startPrank(owner);
    usdcUpgradeProxy.appendWhiteList(address(user1));
    vm.stopPrank();

    
    //#3. test user1 can mintToken after the user1 be appended to white list
    vm.startPrank(user1);
    usdcUpgradeProxy.mintToken(address(user1), 1 ether);
    vm.stopPrank();
    assertEq(usdcUpgradeProxy.balanceOf(user1), 1 ether);

    //#4 test user1 can transfer token to owner
    //user1 has 1 ether and transfer 1 ether to owner
    vm.startPrank(user1);
    usdcUpgradeProxy.approve(owner, 1 ether);
    usdcUpgradeProxy.transferByWhiteList(owner, 1 ether);
    vm.stopPrank();
    assertEq(usdcUpgradeProxy.balanceOf(user1), 0 ether);
    assertEq(usdcUpgradeProxy.balanceOf(owner), 1 ether);

    //#5 owner remove user1 from whitelist
    //expect revert after user1 is not in whitelist
    vm.startPrank(owner);
    usdcUpgradeProxy.removeWhiteList(user1);
    vm.stopPrank();
    vm.startPrank(user1);
    vm.expectRevert("sender doesn't exist in whitelist");
    usdcUpgradeProxy.mintToken(address(user1), 1 ether);
    vm.stopPrank();
  }
}