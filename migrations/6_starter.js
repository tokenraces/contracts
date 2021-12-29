// ** Starter Race Creation
const StarterRaceRandomNumberGenerator = artifacts.require('StarterRaceRandomNumberGenerator.sol')
const StarterRaceFactory = artifacts.require('StarterRaceFactory.sol')
const StarterRaceRouter = artifacts.require('StarterRaceRouter.sol')

module.exports = function(deployer) {
    deployer.deploy(StarterRaceRandomNumberGenerator,process.env.VRF_COORDINATOR,process.env.LINK_ADDRESS,process.env.FEE,process.env.KEY_HASH).then(async() => {
        const numberGenerator = await StarterRaceRandomNumberGenerator.deployed();
        await deployer.deploy(StarterRaceFactory);
        const tokenFactory = await StarterRaceFactory.deployed();

        await deployer.deploy(StarterRaceRouter,numberGenerator.address,tokenFactory.address,process.env.WETH_ADDRESS,process.env.UNISWAP_V2_ROUTER_ADDRESS);
       
        await numberGenerator.setRacingTokenRouterAddress(StarterRaceRouter.address);    
        await tokenFactory.setRacingTokenRouterAddress(StarterRaceRouter.address);
    });

}