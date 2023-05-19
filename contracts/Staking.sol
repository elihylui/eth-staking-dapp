// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Staking {
    address public owner;

    struct Position {
        uint positionId;
        address walletAddress; //the address created the position
        uint createdDate;
        uint unlockDate;
        uint percentInterest;
        uint weiStaked;
        uint weiInterest;
        bool open;
    }

    Position position;

    uint public currentPositionId;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionIdsByAddress;
    mapping(uint => uint) public tiers; //number of days & interest rates
    uint[] public lockPeriods;

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        tiers[0] = 700;
        tiers[30] = 800;
        tiers[60] = 900;
        tiers[90] = 1200;

        lockPeriods.push(0);
        lockPeriods.push(30);
        lockPeriods.push(60);
        lockPeriods.push(90);
    }

    function stakeEther(uint numDays) external payable { //the function to be called when "stake" button is clicked
        require(tiers[numDays] > 0, "Mappingg not found"); //make sure people can't stake for a random number of days

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            msg.value,
            calculateInterest(tiers[numDays], msg.value),
            true
            );

        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
    }

    function calculateInterest(uint basisPoints, uint weiAmount) private pure returns(uint) {
        return basisPoints * weiAmount / 10000;
    }

    function getLockPeriods() external view returns(uint[] memory) {
        return lockPeriods;
    }

    function getInterest(uint numDays) external view returns(uint) {
        return tiers[numDays];
    }

    function getPositionsById(uint positionId) external view returns(Position memory) {
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress) external view returns(uint[] memory) {
        return positionIdsByAddress[walletAddress];
    }

    function closePosition(uint positionId) external { //executed when the button "unstake" is clicked
        require(positions[positionId].walletAddress == msg.sender, "Only position creater may modify position");
        require(positions[positionId].open == true, "Position is closed");

        positions[positionId].open = false;

        uint amount = positions[positionId].weiStaked + positions[positionId].weiInterest;
        payable(msg.sender).call{value: amount}("");
    }
}
