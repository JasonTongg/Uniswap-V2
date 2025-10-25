// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SwapTokenToToken is Script {
    address constant TOKEN_OUT = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant TOKEN_IN = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        address user = vm.addr(pk);
        console.log("Sender:", user);

        uint256 balanceIn = IERC20Minimal(TOKEN_IN).balanceOf(user);
        require(balanceIn > 0, "No tokenIn balance");
        console.log("Your tokenIn balance:", balanceIn);

        uint256 expectedOut = swapContract.getPriceTokenToToken(TOKEN_IN, TOKEN_OUT, balanceIn);
        console.log("Swap preview:");
        console.log("TokenIn:", balanceIn);
        console.log("Expected TokenOut:", expectedOut);

        IERC20Minimal(TOKEN_IN).approve(address(swapContract), balanceIn);
        console.log("Approved tokenIn to swap contract");

        swapContract.swapToken(TOKEN_IN, TOKEN_OUT, balanceIn);
        console.log("Swap tokenIn to tokenOut successful");

        vm.stopBroadcast();
    }
}
