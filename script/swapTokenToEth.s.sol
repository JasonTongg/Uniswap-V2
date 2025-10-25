// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SwapUniToEth is Script {
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        
        vm.startBroadcast(pk);

        address user = vm.addr(pk);
        console.log("Sender:", user);

        uint256 uniBalance = IERC20Minimal(UNI).balanceOf(user);
        require(uniBalance > 0, "No UNI to swap");
        console.log("Your UNI balance:", uniBalance);

        uint256 expectedETH = swapContract.getPriceTokenToETH(UNI, uniBalance);
        console.log("If you swap UNI you will receive approx (wei ETH):");
        console.logUint(uniBalance);
        console.logUint(expectedETH);

        IERC20Minimal(UNI).approve(address(swapContract), uniBalance);
        console.log("Approved swap contract to spend", uniBalance, "UNI");

        swapContract.swapTokenForETH(UNI, uniBalance);
        console.log("Swapped UNI to ETH successfully");

        vm.stopBroadcast();
    }
}
