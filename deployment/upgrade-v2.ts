// deploy.ts
import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import * as Diamond from '../out/Diamond.sol/Diamond.json'
import * as DiamondCutFacet from '../out/DiamondCutFacet.sol/DiamondCutFacet.json';
import * as DiamondVaultFacetV2 from '../out/DiamondVaultFacetV2.sol/DiamondVaultFacetV2.json'

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

const upgradeDiamond = async () => {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_ENDPOINT, {
        name: 'Vault Diamond',
        chainId: parseInt(process.env.CHAIN_ID ?? '1'),
    });
    const walletPath = "m/44'/60'/0'/0/0";
    const deployer = ethers.Wallet.fromMnemonic(process.env.SECRET_NEUMONIC ?? "", walletPath).connect(provider);
    //const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY ?? '', provider);

    console.log('Upgrading Diamond using account:', deployer.address);


    // Deploy DiamondVaultFacetV2
    const diamondVaultFacetV2Factory = new ethers.ContractFactory(DiamondVaultFacetV2.abi, DiamondVaultFacetV2.bytecode, deployer);
    const diamondVaultFacetV2 = await deploy(diamondVaultFacetV2Factory, deployer);
    console.log('DiamondVaultFacetV2 deployed at:', diamondVaultFacetV2.address);


    const diamondCut: [string, string[]][] = [
        [diamondVaultFacetV2.address, [ethers.utils.id('withdraw(address,uint256)')]],
    ];

    await addDiamondCuts(process.env.DIAMOND_ADDRESS ?? '', diamondCut, deployer);

};

upgradeDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });