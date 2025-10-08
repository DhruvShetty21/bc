import React, { useState } from "react";
export default function App() {
  const [addr, setAddr] = useState(null);
  async function connect() {
    if (!window.ethereum) return alert("Install MetaMask");
    const [a] = await window.ethereum.request({ method: "eth_requestAccounts" });
    setAddr(a);
  }
  return (
    <div style={{ padding: 24 }}>
      <h1>Disk Rental Demo</h1>
      <p>Connected: {addr || "not connected"}</p>
      <button onClick={connect}>Connect Wallet</button>
      <hr />
      <p>This frontend is a minimal starting point. Use MetaMask + ethers.js to call contract functions (createListing, rentListing, upload to IPFS via backend).</p>
    </div>
  );
}
