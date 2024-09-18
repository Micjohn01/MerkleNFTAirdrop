import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { time } from "@nomicfoundation/hardhat-toolbox/network-helpers";

const AirDropEndingTimeInSec = time.duration.seconds(30 * 24 * 60 * 60);
const MyTokenAddress = "0x809c4E72ac8e66226Fe23c5c4a2810B3821E28b2"
const MerkleNFTAirdropModule = buildModule("MerkleNFTAirdropModule", (m) => {
  const endingTime = m.getParameter("_endingTimeInsec", AirDropEndingTimeInSec);
  const myTokenAddress = m.getParameter("_tokenAddress", MyTokenAddress);
  const MerkleNFTAirdrop = m.contract("MerkleNFTAirdrop", [endingTime, myTokenAddress],);

  return { MerkleNFTAirdrop };
});

export default MerkleNFTAirdropModule;