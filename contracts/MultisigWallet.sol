// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract MultisigWallet {
    uint private proposalNumber;
    address[] public signers;

    uint public requiredSignatures = signers.length / 2;

    //address to bool for is allowed to sign
    mapping(address => bool) public isSigner;

    // prop number to prop mapping
    mapping(uint=>Proposal) public proposals;
    mapping(uint =>mapping(address => bool)) public hasVoted;

    struct Transaction{
        address payable payee;
        uint amount;
        bool executed;
    }

    struct Proposal{
        ProposalType proposalType;
        uint signatures;
        bool executed;
        address targetAddress;
        uint proposalNum;

    }



    enum ProposalType{sendFunds, addNewOwner, signTransaction}
    enum ProposalStatus{pending, executed, votedDown, canceled}

    modifier SignerOnly {
        require(isSigner[msg.sender] == true, "only signer");
        _;
    }

    constructor(){
        signers.push(msg.sender);
        isSigner[msg.sender] = true;
    }

    function proposeNewSigner(address newOwner) public SignerOnly {
        proposalNumber++;
        
        Proposal memory tempProp = Proposal(ProposalType.addNewOwner, 0, false, newOwner, proposalNumber);

        proposals[proposalNumber] = tempProp;

    }

    function forVote(uint _propNum) public SignerOnly{
        require(hasVoted[_propNum][msg.sender] == false, "already voted");

        proposals[_propNum].signatures++;

        hasVoted[_propNum][msg.sender] = true;


    }

    




    


}