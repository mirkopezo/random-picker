//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RandomPicker is VRFConsumerBaseV2, Ownable {
    address private constant VRF_COORDINATOR =
        0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address private constant LINK = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 private constant KEY_HASH =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 private constant CALLBACK_GAS_LIMIT = 400000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable coordinator;
    LinkTokenInterface private immutable linkToken;
    uint64 public subscriptionId;

    mapping(address => bool) private approvers;
    mapping(string => uint256) private leaderboard;
    string[] private poolOfNames;
    string public currentPickedPerson;
    uint256 public currentRandomNumber;
    uint256 public nextPickTime;

    event PersonPicked(string name, uint256 time);

    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(VRF_COORDINATOR) {
        coordinator = VRFCoordinatorV2Interface(VRF_COORDINATOR);
        linkToken = LinkTokenInterface(LINK);
        subscriptionId = _subscriptionId;
    }

    function pickRandomPerson() external {
        require(
            approvers[msg.sender] == true,
            "you are not approved for this!"
        );
        require(
            block.timestamp > nextPickTime,
            "please wait until next thursday!"
        );
        nextPickTime = block.timestamp + 6 days;
        coordinator.requestRandomWords(
            KEY_HASH,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        currentRandomNumber = randomWords[0];
        uint256 currentRandomNumberBounded = currentRandomNumber %
            poolOfNames.length;
        currentPickedPerson = poolOfNames[currentRandomNumberBounded];
        leaderboard[currentPickedPerson]++;
        emit PersonPicked(currentPickedPerson, block.timestamp);
    }

    /* --- Functions that can only be called by the owner --- */

    function setNames(string[] memory _poolOfNames) external onlyOwner {
        poolOfNames = _poolOfNames;
    }

    function setApprover(address addr, bool approved) external onlyOwner {
        approvers[addr] = approved;
    }

    function updateSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function resetTimer() external onlyOwner {
        nextPickTime = 0;
    }

    /* --- Getters --- */

    function isApproved(address addr) external view returns (bool) {
        return approvers[addr];
    }

    function getPoolOfNames() external view returns (string[] memory) {
        return poolOfNames;
    }

    function getCurrentLeaderboard() external view returns (string[] memory) {
        string[] memory currentLeaderboard = new string[](poolOfNames.length);
        for (uint256 i = 0; i < poolOfNames.length; i++) {
            currentLeaderboard[i] = string(
                abi.encodePacked(
                    poolOfNames[i],
                    ":",
                    Strings.toString(leaderboard[poolOfNames[i]])
                )
            );
        }
        return currentLeaderboard;
    }

    function getNumberOfTimesPersonWasDrawn(string memory name)
        external
        view
        returns (uint256)
    {
        return leaderboard[name];
    }
}
