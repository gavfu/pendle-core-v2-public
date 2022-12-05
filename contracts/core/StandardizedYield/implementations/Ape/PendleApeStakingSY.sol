// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../../SYBase.sol";
import "../../../../interfaces/IApeStaking.sol";

contract PendleApeStakingSY is SYBase {
    using Math for uint256;

    uint256 public constant APE_COIN_POOL_ID = 0;
    uint256 public constant MIN_APE_DEPOSIT = 10**18;
    uint256 public constant EPOCH_LENGTH = 1 hours;

    address public immutable apeStaking;
    address public immutable apeCoin;

    uint256 private lastRewardClaimedEpoch;

    constructor(
        string memory _name,
        string memory _symbol,
        address _apeCoin,
        address _apeStaking
    )
        SYBase(_name, _symbol, _apeCoin) 
    {
        apeStaking = _apeStaking;
        apeCoin = _apeCoin;
        lastRewardClaimedEpoch = _getCurrentEpochId();
        _safeApproveInf(apeCoin, apeStaking);
    }

    function _deposit(address, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        // Respecting APE's deposit invariant & prevent frontrunning on deployment
        if (amountDeposited < MIN_APE_DEPOSIT) {
            revert Errors.SYApeDepositAmountTooSmall(amountDeposited);
        }

        _harvestAndCompound();

        // As SY Base is pulling the tokenIn first, the totalAsset should exclude user's deposit
        uint256 priorTotalAssetOwned = getTotalAssetOwned() - amountDeposited;

        if (totalSupply() == 0) {
            amountSharesOut = amountDeposited;
        } else {
            // The upcoming calculation can be reduced to amountDeposited.divDown(exchangeRate())
            // The following calculation is choosen instead to minimize precision error
            amountSharesOut = (amountDeposited * totalSupply()) / priorTotalAssetOwned;
        }
    }

    function _redeem(
        address receiver,
        address,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 amountTokenOut) {
        _harvestAndCompound();

        // As SY is burned before calling _redeem(), we should account for priorSupply
        uint256 priorTotalSupply = totalSupply() + amountSharesToRedeem;

        if (amountSharesToRedeem == priorTotalSupply) {
            amountTokenOut = getTotalAssetOwned();
        } else {
            // The upcoming calculation can be reduced to amountSharesToRedeem.mulDown(exchangeRate())
            // The following calculation is choosen instead to minimize precision error
            amountTokenOut = (amountSharesToRedeem * getTotalAssetOwned()) / priorTotalSupply;
        }

        // There might be case when the contract is holding < 1 APE reward and user is withdrawing everything out of it
        if (amountTokenOut > _selfBalance(apeCoin)) {
            IApeStaking(apeStaking).withdrawApeCoin(
                amountTokenOut - _selfBalance(apeCoin),
                address(this)
            );
        }
        _transferOut(apeCoin, receiver, amountTokenOut);
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return getTotalAssetOwned().divDown(totalSupply());
    }

    /*///////////////////////////////////////////////////////////////
                AUTOCOMPOUND FEATURE
    //////////////////////////////////////////////////////////////*/

    function harvestAndCompound() external {
        _harvestAndCompound();
    }

    function getTotalAssetOwned() public view returns (uint256 totalAssetOwned) {
        (uint256 stakedAmount, ) = IApeStaking(apeStaking).addressPosition(address(this));
        uint256 unclaimedAmount = IApeStaking(apeStaking).pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            0
        );
        uint256 floatingAmount = _selfBalance(apeCoin);
        totalAssetOwned = stakedAmount + unclaimedAmount + floatingAmount;
    }

    function _harvestAndCompound() internal {
        // Claim reward
        uint256 currentEpochId = _getCurrentEpochId();
        if (currentEpochId != lastRewardClaimedEpoch) {
            IApeStaking(apeStaking).claimSelfApeCoin();
            lastRewardClaimedEpoch = currentEpochId;
        }

        // Deposit APE
        uint256 amountAssetToCompound = _selfBalance(apeCoin);
        if (amountAssetToCompound >= MIN_APE_DEPOSIT) {
            IApeStaking(apeStaking).depositSelfApeCoin(amountAssetToCompound);
        }
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(address, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (uint256 amountSharesOut)
    {
        if (totalSupply() == 0) {
            amountSharesOut = amountTokenToDeposit;
        } else {
            amountSharesOut = (amountTokenToDeposit * totalSupply()) / getTotalAssetOwned();
        }
    }

    function _previewRedeem(address, uint256 amountSharesToRedeem)
        internal
        view
        override
        returns (uint256 amountTokenOut)
    {
        amountTokenOut = (amountSharesToRedeem * getTotalAssetOwned()) / totalSupply();
    }


    function _getCurrentEpochId() private view returns (uint256) {
        return block.timestamp / EPOCH_LENGTH;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = apeCoin;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = apeCoin;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == apeCoin;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == apeCoin;
    }

    function assetInfo()
        external
        view
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        )
    {
        return (AssetType.TOKEN, apeCoin, IERC20Metadata(apeCoin).decimals());
    }
}