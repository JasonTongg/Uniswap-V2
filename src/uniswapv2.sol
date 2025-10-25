// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function totalSupply() external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint value) external returns (bool);
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
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

contract TokenSwapContract {
    address public immutable ROUTER;
    IUniswapV2Router public router = IUniswapV2Router(ROUTER);

    uint256 public slippageBasisPoints = 100;

    address public immutable FACTORY;
    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY);

    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event PoolCreated(address tokenA, address tokenB, address pair);
    event LiquidityAdded(address tokenA, address tokenB, uint amountA, uint amountB, uint liquidity);

    constructor(address factoryAddress, address routerAddress) {
        factory = IUniswapV2Factory(factoryAddress);
        router = IUniswapV2Router(routerAddress);
    }
    
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

    function createPool(address tokenA, address tokenB) external returns (address pair) {
        pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = factory.createPair(tokenA, tokenB);
        }
        emit PoolCreated(tokenA, tokenB, pair);
    }

    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB) external returns (uint liquidity) {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        IERC20(tokenA).approve(ROUTER, amountA);
        IERC20(tokenB).approve(ROUTER, amountB);

        uint amountAMin = amountA * (10000 - slippageBasisPoints) / 10000;
        uint amountBMin = amountB * (10000 - slippageBasisPoints) / 10000;

        (, , liquidity) = router.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountAMin,
            amountBMin,
            msg.sender,
            block.timestamp + 300
        );

        emit LiquidityAdded(tokenA, tokenB, amountA, amountB, liquidity);
    }

    function addLiquidityETH(address token, uint amountToken) external payable returns (uint liquidity) {
        IERC20(token).transferFrom(msg.sender, address(this), amountToken);

        IERC20(token).approve(ROUTER, amountToken);

        uint amountAMin = amountToken * (10000 - slippageBasisPoints) / 10000;
        uint amountEthMin = uint(msg.value) * (10000 - slippageBasisPoints) / 10000;

        (, , liquidity) = router.addLiquidityETH{ value: msg.value }(
            token,
            amountToken,
            amountAMin,
            amountEthMin,
            msg.sender,
            block.timestamp + 300
        );

        emit LiquidityAdded(token, address(0), amountToken, msg.value, liquidity);
    }


    function removeLiquidity(address tokenA, address tokenB, uint liquidity)
        external
        returns (uint amountA, uint amountB)
    {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Pool does not exist");

        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(ROUTER, liquidity);

        // Get expected amounts returned by removing liquidity
        // Note: We cannot use getAmountsOut for LP burn, so we read reserves first:
        (uint reserveA, uint reserveB,) = IUniswapV2Pair(pair).getReserves();
        uint totalSupply = IUniswapV2Pair(pair).totalSupply();

        uint expectedA = (liquidity * reserveA) / totalSupply;
        uint expectedB = (liquidity * reserveB) / totalSupply;

        uint amountAMin = expectedA * (10000 - slippageBasisPoints) / 10000;
        uint amountBMin = expectedB * (10000 - slippageBasisPoints) / 10000;

        (amountA, amountB) = router.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            msg.sender,
            block.timestamp + 300
        );
    }


    function removeLiquidityETH(address token, uint liquidity)
        external
        returns (uint amountToken, uint amountETH)
    {
        address pair = factory.getPair(token, router.WETH());
        require(pair != address(0), "Pool does not exist");

        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(ROUTER, liquidity);

        (uint reserveToken, uint reserveWETH,) = IUniswapV2Pair(pair).getReserves();
        uint totalSupply = IUniswapV2Pair(pair).totalSupply();

        uint expectedToken = (liquidity * reserveToken) / totalSupply;
        uint expectedETH = (liquidity * reserveWETH) / totalSupply;

        uint amountTokenMin = expectedToken * (10000 - slippageBasisPoints) / 10000;
        uint amountETHMin = expectedETH * (10000 - slippageBasisPoints) / 10000;

        (amountToken, amountETH) = router.removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            block.timestamp + 300
        );
    }

}
