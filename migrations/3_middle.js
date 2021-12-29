// ** Middle Race Creation
const MiddleRaceRandomNumberGenerator = artifacts.require('MiddleRaceRandomNumberGenerator.sol')
const MiddleRaceFactory = artifacts.require('MiddleRaceFactory.sol')
const MiddleRaceRouter = artifacts.require('MiddleRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(MiddleRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await MiddleRaceRandomNumberGenerator.deployed();
        await deployer.deploy(MiddleRaceFactory);
        const tokenFactory = await MiddleRaceFactory.deployed();

        await deployer.deploy(MiddleRaceRouter,numberGenerator.address.tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
        await numberGenerator.setRacingTokenRouterAddress(MiddleRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(MiddleRaceRouter.address);
    });
}



