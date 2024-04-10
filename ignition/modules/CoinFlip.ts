import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CoinFlipModule = buildModule("CoinFlip", (m) => {
  const token = m.contractAt("CoinToken", "0x6Ee5977CF20Ede0D0465877Da9423d8eC278BB55");
  const contract = m.contract("CoinFlipV2", [token]);

  return { contract };
});

export default CoinFlipModule;
