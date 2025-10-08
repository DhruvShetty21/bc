# Disk Rental - Project Skeleton

This repository contains a runnable skeleton for a Disk Space Rental System using Solidity (Hardhat), a small Node.js backend, and a minimal React frontend.

## Quickstart (local testing)

1. Install dependencies (root + frontend):
   ```bash
   npm install
   cd frontend
   npm install
   cd ..
   ```

2. Start a local Hardhat node in a separate terminal:
   ```bash
   npx hardhat node
   ```

3. Deploy contracts to local node:
   ```bash
   npx hardhat run scripts/deploy.js --network localhost
   ```

4. Copy ABIs from `artifacts/contracts/*.json` to `backend/abis/` (create that folder) so the backend can load ABIs.

5. Create `backend/.env` based on `backend/.env.example` and fill in RPC_URL and PRIVATE_KEY

6. Start backend:
   ```bash
   npm run start:backend
   # or from root
   node backend/index.js
   ```

7. Start frontend:
   ```bash
   cd frontend
   npm run start
   ```

Notes:
- This is a demo skeleton. Do not use admin private keys on production servers.
- Encrypt files client-side before uploading to IPFS.
- Add tests and extra checks before production use.
