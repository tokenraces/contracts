// ** Smallest Race Creation
const SmallestRaceRandomNumberGenerator = artifacts.require('SmallestRaceRandomNumberGenerator.sol')
const SmallestRaceFactory = artifacts.require('SmallestRaceFactory.sol')
const SmallestRaceRouter = artifacts.require('SmallestRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(SmallestRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await SmallestRaceRandomNumberGenerator.deployed();
        await deployer.deploy(SmallestRaceFactory);
        const tokenFactory = await SmallestRaceCreateFactory.deployed();

        await deployer.deploy(SmallestRaceRouter,numberGenerator.address,tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
        await numberGenerator.setRacingTokenRouterAddress(SmallestRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(SmallestRaceRouter.address);
    });
}