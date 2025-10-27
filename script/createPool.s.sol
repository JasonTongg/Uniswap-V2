// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract SwapSepoliaScript is Script {
    address constant TOKENB = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant TOKENA = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        swapContract.createPool(TOKENA, TOKENB);

        vm.stopBroadcast();
    }
}
