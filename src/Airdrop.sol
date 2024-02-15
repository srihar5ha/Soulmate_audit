// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ISoulmate} from "./interface/ISoulmate.sol";
import {ILoveToken} from "./interface/ILoveToken.sol";
import {IVault} from "./interface/IVault.sol";

/// @title Airdrop Contract for LoveToken.
/// @author n0kto
contract Airdrop {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Airdrop__CoupleIsDivorced();
    error Airdrop__PreviousTokenAlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant daysInSecond = 3600 * 24;

    ILoveToken public immutable loveToken;
    ISoulmate public immutable soulmateContract;
    IVault public immutable airdropVault;

    mapping(address owner => uint256 alreadyClaimed) private _claimedBy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenClaimed(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(
        ILoveToken _loveToken,
        ISoulmate _soulmateContract,
        IVault _airdropVault
    ) {
        loveToken = _loveToken;
        soulmateContract = _soulmateContract;
        airdropVault = _airdropVault;
    }

    // Both partner of a couple can claim their own token every days.
    // Financiary dependency is important in a couple.

    /// @notice Claim tokens. Every person who have a Soulmate NFT token can claim 1 LoveToken per day.
    function claim() public {
        // No LoveToken for people who don't love their soulmates anymore.
        if (soulmateContract.isDivorced()) revert Airdrop__CoupleIsDivorced();

        // Calculating since how long soulmates are reunited
        uint256 numberOfDaysInCouple = (block.timestamp -
            soulmateContract.idToCreationTimestamp(
                soulmateContract.ownerToId(msg.sender)
            )) / daysInSecond;

        uint256 amountAlreadyClaimed = _claimedBy[msg.sender];

        if (
            amountAlreadyClaimed >=
            numberOfDaysInCouple * 10 ** loveToken.decimals()
        ) revert Airdrop__PreviousTokenAlreadyClaimed();

        uint256 tokenAmountToDistribute = (numberOfDaysInCouple *
            10 ** loveToken.decimals()) - amountAlreadyClaimed;

        // Dust collector : collecting left over tokens 
        if (
            tokenAmountToDistribute >=
            loveToken.balanceOf(address(airdropVault))
        ) {
            tokenAmountToDistribute = loveToken.balanceOf(
                address(airdropVault)
            );
        }
        _claimedBy[msg.sender] += tokenAmountToDistribute;

        emit TokenClaimed(msg.sender, tokenAmountToDistribute);
        //@audit:notes: since it is transferFrom method, we have protection against reentrancy?
        //@audit:notes: no it does not protect, but since we are not having any external call
        //there is no/less scope for reentrancy.
        //@audit:low: should have zero check for tokenAmounttodistribute to avoid wastage of gas. 
        //require(tokenAmountToDistribute > 0, "No tokens to claim at the moment.");
        loveToken.transferFrom(
            address(airdropVault),
            msg.sender,
            tokenAmountToDistribute
        );
    }
}
