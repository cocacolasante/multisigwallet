// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract MultisigWallet {
    uint private proposalNumber;
    address[] public signers;


    uint public votingTime = 86400; // 1 week in seconds

    //address to bool for is allowed to sign
    mapping(address => bool) public isSigner;

    // prop number to prop mapping
    mapping(uint=>Proposal) public proposals;
    mapping(uint =>mapping(address => bool)) public hasVoted;

    struct Proposal{
        ProposalType proposalType;
        ProposalStatus propStatus;
        uint signatures;
        address targetAddress;
        uint proposalNum;
        uint amount; // only if applicable
        uint expiration;

    }

    event NewProposal(uint propNum, uint targetAddress, uint expiration);
    event NewVote(uint propNum);
    event CancelProp(uint propNum);
    event PassTransaction(uint propNum, uint signatures);


    // ENUMS for type and status
    enum ProposalType{sendFunds, addNewOwner}
    enum ProposalStatus{pending, executed, canceled}



    modifier SignerOnly {
        require(isSigner[msg.sender] == true, "only signer");
        _;
    }

    modifier checkTimeRemaining(uint _propNum) {
        require(block.timestamp >= proposals[_propNum].expiration, "time still remaining");
        require(proposals[_propNum].propStatus != ProposalStatus.canceled, "proposal already cancelled");
        require(proposals[_propNum].propStatus != ProposalStatus.executed, "already executed");
        _;
    }



    constructor(){
        signers.push(msg.sender);
        isSigner[msg.sender] = true;
    }

    // proposing a new signer
    function proposeNewSigner(address newOwner) public SignerOnly {
        proposalNumber++;

        // initializing temp prop to add to mapping
        
        Proposal memory tempProp = Proposal(ProposalType.addNewOwner, ProposalStatus.pending, 0, newOwner, proposalNumber, 0, block.timestamp + votingTime);

        proposals[proposalNumber] = tempProp;

    }

    //proposing a send funds transaction
    function proposeNewTransaction(address targetAddress, uint _amount) public SignerOnly{
        require(address(this).balance > _amount, "not enough funds");
        proposalNumber++;
        Proposal memory tempProp = Proposal(ProposalType.sendFunds, ProposalStatus.pending, 0, targetAddress, proposalNumber, _amount, block.timestamp + votingTime);
        proposals[proposalNumber] = tempProp;

    }


    // vote for a proposal

    function forVote(uint _propNum) public SignerOnly{
        require(hasVoted[_propNum][msg.sender] == false, "already voted");
        checkIfValid(_propNum);
        require(proposals[_propNum].propStatus == ProposalStatus.pending, "voting no longer open");

        proposals[_propNum].signatures++;

        hasVoted[_propNum][msg.sender] = true;


    }

    // execute function that determining the type of proposal would determine which helper function is called

    function executeProposal(uint _propNum) public SignerOnly checkTimeRemaining(_propNum){
        
        uint minVotes = getMinReqSigs();
        require(proposals[_propNum].signatures >= minVotes, "not enough votes");
        require(proposals[_propNum].propStatus == ProposalStatus.pending, "proposal no longer pending" );

        Proposal storage tempProp = proposals[_propNum];

        ProposalType propType = tempProp.proposalType;

        if(propType == ProposalType.sendFunds){
            // write send funds function
            sendEther(_propNum);


        } else if(propType == ProposalType.addNewOwner){
            // write add new owner function
            addWalletToArray(_propNum);

        }else {
            return;
        }
        

    }

    // cancel proposal
    function cancelProposal(uint _propNum) public SignerOnly {
        proposals[_propNum].propStatus = ProposalStatus.canceled;
    }

    


    // internal helper functions
    // adding new wallet to signers after approval -- internal function
    function addWalletToArray(uint _propNum) internal {
        signers.push(proposals[_propNum].targetAddress);

        proposals[_propNum].propStatus = ProposalStatus.executed;

    }

    // send ether helper function

    function sendEther(uint _propNum) internal {
        address payee = proposals[_propNum].targetAddress;

        uint amount = proposals[_propNum].amount;

        payable(payee).transfer(amount);
        

    }



    // internal function to get minimum required signatures
    function getMinReqSigs() internal view returns(uint){
        return signers.length /2;
    }

    // check if time frame has passed


    function checkIfValid(uint _propNum) internal {
        uint minVotes = getMinReqSigs();
        if(block.timestamp >= proposals[_propNum].expiration && proposals[_propNum].propStatus != ProposalStatus.canceled && proposals[_propNum].propStatus != ProposalStatus.executed && proposals[_propNum].signatures < minVotes){
            proposals[_propNum].propStatus = ProposalStatus.canceled;
        }
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