// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // before start broadcast, not a 'real' transaction
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();
        // after start broadcast, 'real' transaction
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        // after stop broadcast, not a 'real' transaction
        return fundMe;
    }
}