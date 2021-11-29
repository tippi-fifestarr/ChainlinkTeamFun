// import { Web3Storage } from "web3.storage";

/** Connect to Moralis server */
const serverUrl = "https://t1mmww7s0knr.usemoralis.com:2053/server";
const appId = "LvBSg3ioKrsEAbOhX6fpQGfA7wRdzRSQTHMjgBPE";

Moralis.start({ serverUrl, appId });
let user = Moralis.User.current();

/** Add from here down */
async function login() {
  if (!user) {
    try {
      user = await Moralis.authenticate({
        signingMessage:
          "This is simply to connect and authenticate you are human",
      });
      initApp();
    } catch (error) {
      console.log(error);
    }
  } else {
    Moralis.enableWeb3();
    initApp();
  }
}

function initApp() {
  document.querySelector("#register_button").disabled = false;
  document.querySelector("#register_button").style.cssText += "font-size:large";
  document.querySelector("#connect_button").style.display = "none";
  document.querySelector("#noob_button").style.display = "none";
  document.querySelector("#noob_button2").style.display = "none";
  document.querySelector("#app").style.display = "block";
  document.querySelector("#submit_button").onclick = submit;
}

async function submit() {
  const input = document.querySelector("#input_image");
  let data = input.files[0];
  const imageFile = new Moralis.File(data.name, data);
  await imageFile.saveIPFS();
  let imageHash = imageFile.hash();

  let metadata = {
    name: document.querySelector("#input_name").value,
    description: document.querySelector("#input_description").value,
    motivation: document.querySelector("#floatingInput").value,
    image: "/ipfs/" + imageHash,
  };
  console.log(metadata);
  const jsonFile = new Moralis.File("metadata.json", {
    base64: btoa(JSON.stringify(metadata)),
  });
  await jsonFile.saveIPFS();

  let metadataHash = jsonFile.hash();
  console.log(jsonFile.ipfs());
  let res = await Moralis.Plugins.rarible.lazyMint({
    // can change chain from rinkeby to mainnet
    chain: "rinkeby",
    userAddress: user.get("ethAddress"),
    tokenType: "ERC721",
    tokenUri: "ipfs://" + metadataHash,
    royaltiesAmount: 5, // 0.05% royalty. Optional
  });
  console.log(res);
  document.querySelector(
    "#success_message"
  ).innerHTML = `NFT minted. <a href="https://rinkeby.rarible.com/token/${res.data.result.tokenAddress}:${res.data.result.tokenId}">View NFT`;
  document.querySelector("#success_message").style.display = "block";
  document.querySelector("#success_message").style.cssText += "font-size:large";
  document.querySelector("#register_button").style.display = "none";
  document.querySelector("#later_button").style.display = "block";
  document.querySelector(".delete").style.display = "none";
  // document.querySelector("#tr").style.display = "none";
  window.scrollTo(0, 0);
  setTimeout(() => {
    document.querySelector(".registration").style.display = "none";
  }, 600); // originally only displayed for 5 seconds
  document.querySelector("#l_butt").onclick = goMission;
}

async function goMission() {
  const now = new Date().getTime();
  let metadata = {
    name: document.querySelector("#input_name2").value,
    timestamp: now,
  };
  const jsonFile = new Moralis.File("metadata.json", {
    base64: btoa(JSON.stringify(metadata)),
  });
  await jsonFile.saveIPFS();

  let metadataHash = jsonFile.hash();
  console.log(jsonFile.ipfs());
}

document.querySelector("#connect_button").onclick = login;
