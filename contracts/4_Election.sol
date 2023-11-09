// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.18;

struct Candidate{
    string name;
    uint voteCount;
}
struct Voter{
    bool isRegister;
    bool isVoted;
    uint voteIndex;
}
contract Election{
    address public manager;
    Candidate [] public candidates;
    mapping(address => Voter) public voter;
    constructor(){
        manager = msg.sender;
    } 
    modifier onlyManager{
        require(msg.sender == manager,"You Can't Manager");
        _;
    }
    function addCandidate (string memory name) public{
        candidates.push(Candidate(name,0));
    }
    function register(address person) onlyManager public{
        voter[person].isRegister = true;
    }
    function vote(uint index) public{
        require(voter[msg.sender].isRegister,"You Can't Register");
        require(!voter[msg.sender].isVoted,"You ate Elected");
        voter[msg.sender].voteIndex = index;
        voter[msg.sender].isVoted = true;
        candidates[index].voteCount+=1;
    }
}