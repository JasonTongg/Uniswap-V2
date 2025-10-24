// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract TokenSwapContract {
    address public constant ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;
    IUniswapV2Router public router = IUniswapV2Router(ROUTER);

    uint256 public slippageBasisPoints = 100;

    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    function _getMinAmountOut(address[] memory path, uint256 amountIn) internal view returns (uint256) {
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256 estimated = amountsOut[amountsOut.length - 1];
        return (estimated * (10000 - slippageBasisPoints)) / 10000;
    }

    function swapToken(address tokenIn, address tokenOut, uint256 amountIn) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(ROUTER, amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256 amountOutMin = _getMinAmountOut(path, amountIn);

        uint256[] memory amounts =
            router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amounts[1]);
    }

    function swapETHForToken(address tokenOut) external payable {
        require(msg.value > 0, "No ETH");

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenOut;

        uint256 amountOutMin = _getMinAmountOut(path, msg.value);

        router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, address(0), tokenOut, msg.value, amountOutMin);
    }

    function swapTokenForETH(address tokenIn, uint256 amountIn) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(ROUTER, amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router.WETH();

        uint256 amountOutMin = _getMinAmountOut(path, amountIn);

        uint256[] memory amounts =
            router.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, tokenIn, address(0), amountIn, amounts[1]);
    }

    function getPriceETHtoToken(address tokenOut, uint256 amountETHIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenOut;
        return router.getAmountsOut(amountETHIn, path)[1];
    }

    function getPriceTokenToETH(address tokenIn, uint256 amountTokenIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router.WETH();
        return router.getAmountsOut(amountTokenIn, path)[1];
    }

    function getPriceTokenToToken(address tokenIn, address tokenOut, uint256 amountTokenIn)
        external
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return router.getAmountsOut(amountTokenIn, path)[1];
    }

    function setSlippageBP(uint256 newSlippageBasisPoints) external {
        require(newSlippageBasisPoints <= 1000, "Max 10%");
        slippageBasisPoints = newSlippageBasisPoints;
    }
}
