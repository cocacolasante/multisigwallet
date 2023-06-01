const { expect } = require("chai");
const {ethers} = require("hardhat");

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
    })
})