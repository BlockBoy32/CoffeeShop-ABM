// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/utils/Address.sol";
import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/utils/Context.sol";
import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/utils/math/SafeMath.sol";

/**
 * @title VestingWallet080
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet080 is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;
    address private immutable _beneficiary;
    uint256 private immutable _startBlock;
    uint256 private immutable _numBlocksDuration;

    /**
     * @dev Set the beneficiary, start blockNumber and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint256 startBlock,
        uint256 numBlocksDuration
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet080: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _startBlock = startBlock;
        _numBlocksDuration = numBlocksDuration;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start blockNumber.
     */
    function startBlock() public view virtual returns (uint256) {
        return _startBlock;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function numBlocksDuration() public view virtual returns (uint256) {
        return _numBlocksDuration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        uint256 releasable = vestedAmount(uint256(block.number*10**18)) - released();
        _released += releasable;
        emit EtherReleased(releasable);
        Address.sendValue(payable(beneficiary()), releasable);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address token) public virtual {
        uint256 releasable = vestedAmount(token, uint256(block.number*10**18)) - released(token);
        _erc20Released[token] += releasable;
        emit ERC20Released(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint256 blockNumber) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), blockNumber);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint256 blockNumber) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), blockNumber);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amout vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint256 blockNumber) internal view virtual returns (uint256) {
        if (blockNumber < startBlock()) {
            return 0;
        } else if (blockNumber > (startBlock() + numBlocksDuration())) {
            return totalAllocation;
        } else {
            return ( totalAllocation * (blockNumber - startBlock()) / numBlocksDuration());
        }
    }
}
