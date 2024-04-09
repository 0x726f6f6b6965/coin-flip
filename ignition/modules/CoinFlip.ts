import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ONE_GWEI: bigint = 1_000_000_000n;

const CoinFlipModule = buildModule("CoinFlip", (m) => {
  const coinAmount = m.getParameter("coinAmount", ONE_GWEI);
  const contract = m.contract("CoinFlipV2", [], {value: coinAmount});

  return { contract };
});

export default CoinFlipModule;
