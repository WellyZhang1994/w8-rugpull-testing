// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.6;
import "solmate/tokens/ERC20.sol";
import { Ownable } from "./Ownable.sol";
import "forge-std/console.sol";

contract Slots {

  function _setSlotToAddress(bytes32 _slot, address value) internal {
    assembly {
      sstore(_slot, value)
    }
  }

  function _getSlotToAddress(bytes32 _slot) internal view returns (address value) {
    assembly {
      value := sload(_slot)
    }
  }
}

contract USDCNew is Slots, ERC20, Ownable {

    //FiatTokenV2_1's storage layout
    address private _owner;
    address private pauser;
    bool private paused;
    address private blacklister;
    mapping(address => bool) private blacklisted;
    string public name_;
    string public symbol_;
    uint8 public decimals_;
    string private currency;
    address private masterMinter;
    bool private initialized;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public totalSupply_;
    mapping(address => bool) private minters;
    mapping(address => uint256) public minterAllowed;
    address private _rescuer;
    bytes32 private DOMAIN_SEPARATOR_;
    mapping(address => mapping(bytes32 => bool)) public _authorizationStates;
    mapping(address => uint256) public _permitNonces;
    uint8 public _initializedVersion;

    bytes32 private constant OWNER_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
    mapping(address => bool) public whiteList;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _initWhiteList) ERC20(_name, _symbol, _decimals){
    }

    modifier inWhiteList {
        require(whiteList[msg.sender], "sender doesn't exist in whitelist");
        _;
    }

    modifier isOwner {
        require(getUSDCOwner() == msg.sender, "sender must be owner");
        _;
    }

    function getUSDCOwner() view private returns (address) {
      return _getSlotToAddress(OWNER_SLOT);
    }

    function appendWhiteList(address addr) public isOwner {
        whiteList[addr] = true;
    }

    function removeWhiteList(address addr) public isOwner {
        whiteList[addr] = false;
    }

    function transferByWhiteList(address recipient, uint256 amount) public inWhiteList {
        transfer(recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
    }

    function mintToken(address recipient, uint256 amount) public inWhiteList {
        _mint(recipient, amount);
    }
}

