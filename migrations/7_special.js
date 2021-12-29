// ** Special Race Creation
const SpecialRaceRandomNumberGenerator = artifacts.require('SpecialRaceRandomNumberGenerator.sol')
const SpecialRaceFactory = artifacts.require('SpecialRaceFactory.sol')
const SpecialRaceRouter = artifacts.require('SpecialRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(SpecialRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await SpecialRaceRandomNumberGenerator.deployed();
        await deployer.deploy(SpecialRaceFactory);
        const tokenFactory = await SpecialRaceFactory.deployed();

        await deployer.deploy(SpecialRaceRouter,numberGenerator.address,tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
       
        await numberGenerator.setRacingTokenRouterAddress(SpecialRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(SpecialRaceRouter.address);
    });

}