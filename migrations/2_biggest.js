// ** Biggest Race Creation
const BiggestRaceRandomNumberGenerator = artifacts.require('BiggestRaceRandomNumberGenerator.sol')
const BiggestRaceFactory = artifacts.require('BiggestRaceFactory.sol')
const BiggestRaceRouter = artifacts.require('BiggestRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(BiggestRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await BiggestRaceRandomNumberGenerator.deployed();
        await deployer.deploy(BiggestRaceFactory);
        const tokenFactory = await BiggestRaceFactory.deployed();

        await deployer.deploy(BiggestRaceRouter,numberGenerator.address.tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
        await numberGenerator.setRacingTokenRouterAddress(BiggestRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(BiggestRaceRouter.address);
    });
}



