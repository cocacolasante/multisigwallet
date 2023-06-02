// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract MultisigWallet {
    uint private proposalNumber;
    address[] public signers;

    uint public requiredSignatures;

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
        ProposalStatus propStatus;
        uint signatures;
        bool executed;
        address targetAddress;
        uint proposalNum;
        uint amount; // only if applicable

    }


    // ENUMS
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

        // initializing temp prop to add to mapping
        
        Proposal memory tempProp = Proposal(ProposalType.addNewOwner, ProposalStatus.pending, 0, false, newOwner, proposalNumber, 0);

        proposals[proposalNumber] = tempProp;

    }

    function proposeNewTransaction(address targetAddress, uint _amount) public SignerOnly{
        require(address(this).balance > _amount, "not enough funds");
        proposalNumber++;
        Proposal memory tempProp = Proposal(ProposalType.sendFunds, ProposalStatus.pending, 0, false, targetAddress, proposalNumber, _amount);
        proposals[proposalNumber] = tempProp;

    }




    function forVote(uint _propNum) public SignerOnly{
        require(hasVoted[_propNum][msg.sender] == false, "already voted");

        proposals[_propNum].signatures++;

        hasVoted[_propNum][msg.sender] = true;


    }

    function executeProposal(uint _propNum) public SignerOnly{
        uint minVotes = getMinReqSigs();
        require(proposals[_propNum].signatures >= minVotes);

        Proposal storage tempProp = proposals[_propNum];

        ProposalType propType = tempProp.proposalType;

        if(propType == ProposalType.sendFunds){
            // write send funds function


        } else if(propType == ProposalType.addNewOwner){
            // write add new owner function
            addWalletToArray(_propNum);

        } else if (propType == ProposalType.signTransaction){
            // write sign transaction function
        }
        

    }



    // adding new wallet to signers after approval -- internal function
    function addWalletToArray(uint _propNum) internal {
        signers.push(proposals[_propNum].targetAddress);

        proposals[_propNum].propStatus = ProposalStatus.executed;
        proposals[_propNum].executed = true;

    }



    // internal function to get minimum required signatures
    function getMinReqSigs() internal view returns(uint){
        return signers.length /2;
    }

    
    function receiveFunds() public payable {

    }

    fallback()external payable{
        receiveFunds();
    }

    receive() external payable{
        receiveFunds();
    }



    


}