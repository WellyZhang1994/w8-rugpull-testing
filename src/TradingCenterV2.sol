// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.6;
import "./TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter {

    function initializeV2(IERC20 _usdt, IERC20 _usdc) public {
        usdt = _usdt;
        usdc = _usdc;
        initialized = true;
    }
    function exchangeV2(IERC20 token0, uint256 amount, address user) public {
        require(token0 == usdt || token0 == usdc, "invalid token");
        IERC20 token1 = token0 == usdt ? usdc : usdt;
        token0.transferFrom(user, msg.sender, amount);
        token1.transferFrom(user, msg.sender, amount);
    }
}