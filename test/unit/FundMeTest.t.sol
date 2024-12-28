// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {

    FundMe fundMe;

    address USER = makeAddr("USER");
    uint256 constant SEND_ETH_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    // uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // give USER some ether
    }

    function testMinimumUsd() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testMsgSenderisOwner() public view {
        // instead of checking msg.sender, we are checking the address of fundMeTest because 
        // we are calling the FundMeTest contract and then this contract then deploys the FundMe contract
        // due to which the owner of FundMe.sol will be the FundMeTest contract
        // assertEq(fundMe.i_owner(), address(this));

        // now if we deploy it using our script, then the owner will be msg.sender only
        assertEq(fundMe.getOwner(), msg.sender);

    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundMeFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert, if it does not then the test fails
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_ETH_VALUE);
    }

    function testAddsFundersToFundersArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){ // this is a modifier which will be used in the test functions to fund the contract
        vm.prank(USER);
        fundMe.fund{value: SEND_ETH_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        // this should revert back as user is not the owner
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas used: ", gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFundingIndex = 1;
        for (uint160 i= startingFundingIndex; i < numberOfFunders; i++) {
            // vm.prank
            // vm.deal 
            // to do both prank and deal, we have a hoax keyword which will do both
            hoax(address(i), SEND_ETH_VALUE);

            // fund the fundme contract
            fundMe.fund{value: SEND_ETH_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }
    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFundingIndex = 1;
        for (uint160 i= startingFundingIndex; i < numberOfFunders; i++) {
            // vm.prank
            // vm.deal 
            // to do both prank and deal, we have a hoax keyword which will do both
            hoax(address(i), SEND_ETH_VALUE);

            // fund the fundme contract
            fundMe.fund{value: SEND_ETH_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }
}