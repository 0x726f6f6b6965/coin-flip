// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is VRFConsumerBaseV2, Ownable {

    uint256 private constant IN_PROGRESS = 42;
    uint256 private constant FEE = 100000000000000;
    uint256 private constant REMAIN = 4000000000000000;
    uint256 private constant PRIZE = 2000000000000000;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    // for sepolia testnet
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;

    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 40000;
    uint32 numWords = 1;

    bytes32 s_keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    

    mapping(uint256 => address) private flipers;
    mapping(address => uint256) private prizes;
    mapping(address => uint256) private results;
    mapping(address => uint256) private guess;

    event CoinFlipped(uint256 indexed requestId, address indexed fliper);
    event CoinFlipResult(uint256 indexed requestId, uint256 indexed result, bool getPrize);
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function flipCoin(uint256 _guess) public payable returns (uint256 requestId) {
        require(results[msg.sender] == 0, "Already flipped");
        require(address(this).balance > REMAIN, "Please donate this contract");
        require(msg.value >= FEE, "The value insufficient");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        flipers[requestId] = msg.sender;
        results[msg.sender] = IN_PROGRESS;
        guess[msg.sender] = _guess;
        emit CoinFlipped(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 f2Value = (randomWords[0] % 2) + 1;
        results[flipers[requestId]] = f2Value;
        bool win = f2Value == guess[flipers[requestId]] ? true : false;
        if (win) {
            prizes[flipers[requestId]] = PRIZE;
        }
        emit CoinFlipResult(requestId, f2Value, win);
    }

    function withdrawPrizes() public reset {
        uint256 prize = prizes[msg.sender];
        if (prize > 0) {
            prizes[msg.sender] = 0;
            (bool success,) = msg.sender.call{value: prize}("Prize Withdraw");
            require(success, "Insufficient Balance");
        }
    }

    function withdrawAll() public onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("WithdrawAll");
        require(success, "tx failed");
    }

    function resetCoin() public {
        require(results[msg.sender] != 0, "Please flip first");
        require(results[msg.sender] != IN_PROGRESS, "Flip in progress");
        results[msg.sender] = 0;
    }

    function getPrize() public view returns (uint256) {
        return prizes[msg.sender];
    }

    function getFlipResult() public view returns (string memory , string memory){
        require(results[msg.sender] != 0, "Please flip first");
        require(results[msg.sender] != IN_PROGRESS, "Flip in progress");
        return (getCoinString(results[msg.sender]), getCoinString(guess[msg.sender]));
    }

    function getCoinString(uint256 id) private pure returns (string memory) {
        string[2] memory coinString = [
            "Heads",
            "Tails"
        ];
        return coinString[id - 1];
    }

    receive() external payable {}

    modifier reset() {
        require(results[msg.sender] != 0, "Please flip first");
        require(results[msg.sender] != IN_PROGRESS, "Flip in progress");
        results[msg.sender] = 0;
        _;
    }
}