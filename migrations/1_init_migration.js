const NodeFactory = artifacts.require('GPR_NodeFactory');

module.exports = function(deployer, network) {
    if (network === 'mainnet') {
        deployer.deploy(NodeFactory,'Global Property Registry', 'http://realhost:3000');
    } else if (network === 'sepolia') {
        deployer.deploy(NodeFactory,'Global Property Registry', 'http://testhost:3000');
    } else {
        deployer.deploy(NodeFactory,'Global Property Registry', 'http://localhost:3000');
    }
  
};
