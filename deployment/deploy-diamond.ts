// deploy.ts
import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import * as Diamond from '../out/Diamond.sol/Diamond.json'
import * as DiamondCutFacet from '../out/DiamondCutFacet.sol/DiamondCutFacet.json';
import * as DiamondLoupeFacet from '../out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json';
import * as OwnershipFacet from '../out/OwnershipFacet.sol/OwnershipFacet.json';
import * as DiamondVaultFacetV1 from '../out/DiamondVaultFacetV1.sol/DiamondVaultFacetV1.json'

dotenv.config();

// Helper function to send a raw transaction
async function sendRawTransaction(wallet: ethers.Wallet, to: string, data: string) {
    const nonce = await wallet.getTransactionCount();
    const gasPrice = await wallet.provider.getGasPrice();
    const gasLimit = 6000000;

    const rawTx = {
        from: wallet.address,
        to: to,
        data: data,
        gasPrice: gasPrice.toHexString(),
        gasLimit: ethers.utils.hexlify(gasLimit),
        nonce: ethers.utils.hexlify(nonce),
        chainId: parseInt(process.env.CHAIN_ID ?? '1')
    };

    const signedTx = await wallet.signTransaction(rawTx);
    const txResponse = await wallet.provider.sendTransaction(signedTx);

    return txResponse;
}

const deploy = async (factory: ethers.ContractFactory, deployer: ethers.Wallet, constructorArgs: any[] = []) => {
    const chainId = await deployer.provider.getNetwork().then((network) => network.chainId);
    const deployTx = factory.getDeployTransaction(...constructorArgs);
    deployTx.chainId = chainId;
    const gasPrice = await deployer.provider.getGasPrice();
    const nonce = await deployer.getTransactionCount("pending");
    deployTx.nonce = nonce;
    const gasEstimate = await deployer.provider.estimateGas(deployTx);

    deployTx.gasPrice = gasPrice.mul(ethers.BigNumber.from(120)).div(100); // Increase gas price by 20%
    deployTx.gasLimit = gasEstimate.mul(ethers.BigNumber.from(120)).div(100); // Increase estimated gas limit by 20%

    const signedTx = await deployer.signTransaction(deployTx);

    // Calculate the contract address before deploying
    const contractAddress = ethers.utils.getContractAddress({
        from: deployer.address,
        nonce: nonce,
    });



    // Send the signed transaction
    const txResponse = await deployer.provider.sendTransaction(signedTx);
    console.log("Transaction Hash:", txResponse.hash);

    // Wait for the transaction to be mined
    await txResponse.wait();

    // Return the deployed contract instance
    return new ethers.Contract(contractAddress, factory.interface, deployer);
};


const createDiamondCut = (cut: [string, string[]][]) => {
    return cut.map(([address, functionId]) => [
        address,
        0,
        functionId.map(id => ethers.utils.hexDataSlice(id, 0, 4)),
    ]);
};

const addDiamondCuts = async (diamondAddress: string, diamondCut: [string, string[]][], deployer: ethers.Wallet) => {
    const diamond = new ethers.Contract(diamondAddress, Diamond.abi, deployer);
    const diamondCutFacet = new ethers.Contract(diamondAddress, DiamondCutFacet.abi, deployer);

    const formattedDiamondCut = createDiamondCut(diamondCut);
    console.log(formattedDiamondCut)

    // Create the transaction data for the diamondCut function call
    const diamondCutFunction = diamondCutFacet.interface.encodeFunctionData("diamondCut", [formattedDiamondCut, ethers.constants.AddressZero, "0x"]);

    // Send the raw transaction for the diamondCut function call
    const txResponse = await sendRawTransaction(deployer, diamondAddress, diamondCutFunction);
    await txResponse.wait();

    console.log('Diamond cuts added successfully');
};

const deployDiamond = async () => {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_ENDPOINT, {
        name: 'Vault Diamond',
        chainId: parseInt(process.env.CHAIN_ID ?? '1'),
    });
    const walletPath = "m/44'/60'/0'/0/0";
    const deployer = ethers.Wallet.fromMnemonic(process.env.SECRET_NEUMONIC ?? "", walletPath).connect(provider);
    //const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY ?? '', provider);

    console.log('Deploying Diamond using account:', deployer.address);

    // Deploy DiamondCutFacet
    const diamondCutFacetFactory = new ethers.ContractFactory(DiamondCutFacet.abi, DiamondCutFacet.bytecode, deployer);
    const diamondCutFacet = await deploy(diamondCutFacetFactory, deployer);
    console.log('DiamondCutFacet deployed at:', diamondCutFacet.address);

    // Deploy DiamondLoupeFacet
    const diamondLoupeFacetFactory = new ethers.ContractFactory(DiamondLoupeFacet.abi, DiamondLoupeFacet.bytecode, deployer);
    const diamondLoupeFacet = await deploy(diamondLoupeFacetFactory, deployer);
    console.log('DiamondLoupeFacet deployed at:', diamondLoupeFacet.address);

    // Deploy OwnershipFacet
    const ownershipFacetFactory = new ethers.ContractFactory(OwnershipFacet.abi, OwnershipFacet.bytecode, deployer);
    const ownershipFacet = await deploy(ownershipFacetFactory, deployer);
    console.log('OwnershipFacet deployed at:', ownershipFacet.address);

    // Deploy DiamondVaultFacetV1
    const diamondVaultFacetV1Factory = new ethers.ContractFactory(DiamondVaultFacetV1.abi, DiamondVaultFacetV1.bytecode, deployer);
    const diamondVaultFacetV1 = await deploy(diamondVaultFacetV1Factory, deployer);
    console.log('DiamondVaultFacetV1 deployed at:', diamondVaultFacetV1.address);


    const diamondCut: [string, string[]][] = [
        // [diamondCutFacet.address, ethers.utils.id('diamondCut((address,uint256[],bytes)[])')],
        [diamondLoupeFacet.address, [ethers.utils.id('facetAddress(bytes4)'), ethers.utils.id('facets()'), ethers.utils.id('facetFunctionSelectors(address)'), ethers.utils.id('facetAddresses()')]],
        [ownershipFacet.address, [ethers.utils.id('owner()'), ethers.utils.id('transferOwnership(address)')]],
        [diamondVaultFacetV1.address, [ethers.utils.id('depositNative()'), ethers.utils.id('depositERC20(address,uint256)'), ethers.utils.id('balances(address,address)')]],
    ];

    // Deploy Diamond
    const diamondFactory = new ethers.ContractFactory(Diamond.abi, Diamond.bytecode, deployer);
    const diamond = await deploy(diamondFactory, deployer, [deployer.address, diamondCutFacet.address]);
    console.log('Diamond deployed at:', diamond.address);

    await addDiamondCuts(diamond.address, diamondCut, deployer);

};

deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });