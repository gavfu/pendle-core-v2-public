// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity ^0.8.0;
import "./LiquidYieldToken.sol";

abstract contract LiquidYieldTokenWrap is LiquidYieldToken {
    address public yieldToken;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __lytdecimals,
        uint8 __assetDecimals,
        address[] memory _baseTokens,
        address[] memory _rewardTokens,
        address _yieldToken
    ) LiquidYieldToken(_name, _symbol, __lytdecimals, __assetDecimals, _baseTokens, _rewardTokens) {
        yieldToken = _yieldToken;
    }

    function depositYieldToken(
        address recipient,
        uint256 amountIn,
        uint256 minAmountLytOut
    ) public virtual returns (uint256 amountLytOut);

    function withdrawToYieldToken(
        address recipient,
        uint256 amountLytIn,
        uint256 minAmountYieldOut
    ) public virtual returns (uint256 amountYieldOut);
}