// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract CoinFlipV2 is VRFV2WrapperConsumerBase, Ownable {
    event CoinFlipRequest(uint256 requestId);
    event CoinFlipResult(uint256 requestId, bool isWin);

    struct CoinFlipStatus {
        uint256 randomWord;
        uint256 fees;
        address player;
        bool isWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

    enum CoinFlipSelection {
        HEADS,
        TAILS
    }

    mapping(uint256 => CoinFlipStatus) internal statuses;

    address constant linkAddr = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant vrfWrapperAddr =
        0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    uint128 constant entryFees = 0.001 ether;
    uint32 constant callbackGasLimit = 1_000_000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;

    constructor()
        payable
        VRFV2WrapperConsumerBase(linkAddr, vrfWrapperAddr)
        Ownable(msg.sender)
    {}

    function flip(CoinFlipSelection choice) external payable returns (uint256) {
        require(msg.value == entryFees, "Entry fees not enough");

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        statuses[requestId] = CoinFlipStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            player: msg.sender,
            isWin: false,
            fulfilled: false,
            choice: choice
        });

        emit CoinFlipRequest(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(statuses[requestId].fees > 0, "Request not found");
        statuses[requestId].randomWord = randomWords[0];
        statuses[requestId].fulfilled = true;
        CoinFlipSelection result = randomWords[0] % 2 == 0
            ? CoinFlipSelection.HEADS
            : CoinFlipSelection.TAILS;
        if (result == statuses[requestId].choice) {
            statuses[requestId].isWin = true;
            payable(statuses[requestId].player).transfer(entryFees * 2);
        }

        emit CoinFlipResult(requestId, statuses[requestId].isWin);
    }

    function getStatus(
        uint256 requestId
    ) public view returns (CoinFlipStatus memory) {
        return statuses[requestId];
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}
