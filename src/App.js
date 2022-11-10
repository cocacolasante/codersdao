import { ethers } from 'ethers';
import { useState, useEffect } from 'react';
import nft1 from "./assets/1.png"
import { CODERS_ADDRESS } from './contract-config/contracts';
import coderNftAbi from "./contract-abi/codersNftAbi.json"
import './App.css';

const toWei = (num) => ethers.utils.parseEther(num.toString())
const fromWei = (num) => ethers.utils.formatEther(num)

function App() {
  const [activeAccount, setActiveAccount] = useState()
  const [currentNetwork, setCurrentNetwork] = useState()
  const [mintFee, setMintFee] = useState()
  const [mintCount, setMintCount] = useState()


  const checkIfWalletIsConnected = async () =>{
    
    try{
      const {ethereum} = window;
      if(!ethereum){
        alert("Please Install Metamask Wallet Extension")
        return;
      } else{
        console.log("Ethereum Object Found")
      }

      const accounts = await ethereum.request({method: "eth_requestAccounts"})

      if(accounts.length !== 0 ){
        const account = accounts[0]
        setActiveAccount(account)
        console.log(`Connected to ${account}`)
      }

      const chainId = await ethereum.request({method: "eth_chainId"})

      setCurrentNetwork(chainId);

      ethereum.on('chainChanged', handleChainChanged);

      function handleChainChanged(_chainId) {
        window.location.reload();
      }

    }catch(error){
      console.log(error)
    }
  }

  const connectWallet = async () =>{
    try {
      const {ethereum} = window;
      if(!ethereum){
        alert("please install metamask")
        return;

      }
      const accounts = await ethereum.request({method: "eth_requestAccounts"})
      setActiveAccount(accounts[0])
      console.log(`Account connected: ${accounts[0]}`)
      
    }catch(error){
      console.log(error)
    }
  }

  const mintNft = async () =>{
    try{
      const {ethereum} = window;
      if(ethereum){
        const provider = new ethers.providers.Web3Provider(ethereum)
        const signer = provider.getSigner()
        const CodersNFT = new ethers.Contract(CODERS_ADDRESS, coderNftAbi.abi, signer)
        let mintPrice = await CodersNFT.mintPrice()
        

        const txn = await CodersNFT.mint(activeAccount, {value: mintPrice})
        const receipt = await txn;
        await receipt.wait()

        if(receipt.status === 1){
          alert("NFT Sucessfully Minted")
        }else{
          alert("Mint unsucessful")
        }

      }

    }catch(error){
      console.log(error)
    }
  }

  const getNFTContractData = async () =>{
    try {
      const {ethereum} = window;
      if(ethereum){
        const provider = new ethers.providers.Web3Provider(ethereum)
        const CodersNFT = new ethers.Contract(CODERS_ADDRESS, coderNftAbi.abi, provider)
        
        let mintNumber = await CodersNFT.returnTokenCount()
        mintNumber = mintNumber.toString()
        
        setMintCount(mintNumber)

        let mintCost = await CodersNFT.mintPrice()
        mintCost = mintCost.toString()
        setMintFee(mintCost)


      }

    }catch(error){
      console.log(error)
    }
  }

  useEffect(()=>{
    checkIfWalletIsConnected();
    getNFTContractData();
  },[])
  
  return (
    <div className="App">
      <div className='mint-btn-div'>
      {!activeAccount ?  <button className='mint-btn ' onClick={connectWallet}>Connect Wallet</button> : <button className='mint-btn '>{activeAccount.slice(0, 6)}...{activeAccount.slice(-6)}</button> }
        
      </div>
        <h1 className='name-header'>CyberPunk Coders</h1>
      <div className='main-div'>
        <h2>Mint Today</h2>
        <img className='nft-image' alt="nft" src={nft1} />
        <div className='minting-inputs-div' >
          <h3>{mintCount} out of 339 Minted</h3>
          <h6>Mint Yours Today!!</h6>
          <p>Current Mint Price: {mintFee}</p>
          <button onClick={mintNft} className='mint-btn'>Mint Today!</button>
        </div>
      </div>

      <div className='footer-container'>
        <footer>Cyberpunk Coders @2022</footer>
      </div>
      
    </div>
  );
}

export default App;
