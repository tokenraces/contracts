// ** Little Race Creation
const LittleRaceRandomNumberGenerator = artifacts.require('LittleRaceRandomNumberGenerator.sol')
const LittleRaceFactory = artifacts.require('LittleRaceFactory.sol')
const LittleRaceRouter = artifacts.require('LittleRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(LittleRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await LittleRaceRandomNumberGenerator.deployed();
        await deployer.deploy(LittleRaceFactory);
        const tokenFactory = await LittleRaceFactory.deployed();

        await deployer.deploy(LittleRaceRouter,numberGenerator.address,tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
        await numberGenerator.setRacingTokenRouterAddress(LittleRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(LittleRaceRouter.address);
    });
}