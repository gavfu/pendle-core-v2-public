// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

struct SwapData {
    SwapType swapType;
    address extRouter;
    bytes extCalldata;
    bool needScale;
}

struct SwapDataExtra {
    address tokenIn;
    address tokenOut;
    uint256 minOut;
    SwapData swapData;
}

enum SwapType {
    NONE,
    KYBERSWAP,
    ODOS,
    // ETH_WETH not used in Aggregator
    ETH_WETH
}

interface IPSwapAggregator {
    event SwapSingle(SwapType indexed swapType, address indexed tokenIn, uint256 amountIn);

    function swap(address tokenIn, uint256 amountIn, SwapData calldata swapData) external payable;

    function swapMultiOdos(address[] calldata tokensIn, SwapData calldata swapData) external payable;
}
