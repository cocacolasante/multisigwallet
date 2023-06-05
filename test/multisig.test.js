const { expect } = require("chai");
const {ethers} = require("hardhat");
const {moveTime} = require("../utils/moveTime.js");

describe("Multi Signature Wallet", () =>{
    let MultiSig, deployer, user1, user2, user3, proposal
    beforeEach(async () =>{
        [deployer, user1, user2, user3 ] = await ethers.getSigners();

        const multiSigFactory = await ethers.getContractFactory("MultisigWallet")
        MultiSig = await multiSigFactory.deploy();
        await MultiSig.deployed();

    })
    it("checks the deployer was added to signers", async () =>{
        expect(await MultiSig.signers(0)).to.equal(deployer.address);
        expect(await MultiSig.isSigner(deployer.address)).to.equal(true)

    })
    describe("Adding New Signer", () =>{
        it("proposes a new signer", async () =>{
            await MultiSig.connect(deployer).proposeNewSigner(user1.address);
            proposal = await MultiSig.proposals(1)
            expect(proposal.proposalType).to.equal(1)
            expect(proposal.targetAddress).to.equal(user1.address)
        })
        beforeEach(async () =>{
            await MultiSig.connect(deployer).proposeNewSigner(user1.address);
        })
        it("checks the vote for function", async () =>{
            await MultiSig.connect(deployer).forVote(1)
            proposal = await MultiSig.proposals(1)

            expect(proposal.signatures).to.equal(1)
            

        })
        it("checks the execute vote function to add new wallet", async () =>{
            await MultiSig.connect(deployer).forVote(1)
            await moveTime(90000);

            await MultiSig.connect(deployer).executeProposal(1);

            expect(await MultiSig.signers(1)).to.equal(user1.address)
        })
    })
    describe("Transfer funds", () =>{
        
        it("propose a new transfer", async () =>{
            const transaction = await deployer.sendTransaction({
                to: MultiSig.address,
                value: ethers.utils.parseEther('2'),
              });
          
              // Wait for the transaction to be mined
            await transaction.wait();
            await MultiSig.connect(deployer).proposeNewTransaction(user2.address, ethers.utils.parseEther("1"))

            proposal = await MultiSig.proposals(1)
            expect(proposal.targetAddress).to.equal(user2.address)
            

        })
        beforeEach(async () =>{
            const transaction = await deployer.sendTransaction({
                to: MultiSig.address,
                value: ethers.utils.parseEther('2'),
              });
          
              // Wait for the transaction to be mined
            await transaction.wait();
            await MultiSig.connect(deployer).proposeNewTransaction(user2.address, ethers.utils.parseEther("1"))
            await MultiSig.connect(deployer).forVote(1);
            
        })
        it("checks the ether was sent", async () =>{
            let initialBalance = await ethers.provider.getBalance(user2.address);
            
            await moveTime(90000);
            await MultiSig.connect(deployer).executeProposal(1);

            let finalBalance = await ethers.provider.getBalance(user2.address)
            

            expect(BigInt(finalBalance) - BigInt(initialBalance)).to.equal(ethers.utils.parseEther("1"))
       })
       it("checks the proposal was cancelled", async () =>{
            await MultiSig.connect(deployer).proposeNewTransaction(user1.address, ethers.utils.parseEther("1"))

            await MultiSig.connect(deployer).cancelProposal(2)

            proposal = await MultiSig.proposals(2)

            expect(proposal.propStatus).to.equal(2)
       })

        describe("fail cases", () =>{
            it("checks the fail case for Signer only", async () =>{
                await expect(MultiSig.connect(user2).proposeNewSigner(user1.address)).to.be.reverted;
            })
            it("checks the fail case for expired/cancelled proposals", async () =>{
                await MultiSig.connect(deployer).proposeNewTransaction(user1.address, ethers.utils.parseEther("1"))

                await moveTime(90000);
                proposal = await MultiSig.proposals(2)

                await expect(MultiSig.connect(deployer).executeProposal(2)).to.be.reverted;
            })
            it("checks ")
       })
    })  
})