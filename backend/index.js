require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const { makeClient } = require('./ipfs');
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(bodyParser.json({limit: '10mb'}));

const RPC = process.env.RPC_URL || "http://127.0.0.1:8545";
const provider = new ethers.providers.JsonRpcProvider(RPC);

const adminPk = process.env.PRIVATE_KEY;
const adminWallet = adminPk ? new ethers.Wallet(adminPk, provider) : null;

// Load ABIs if provided in backend/abis
const abisDir = path.join(__dirname, 'abis');
function loadAbi(name) {
  try {
    return JSON.parse(fs.readFileSync(path.join(abisDir, name + '.json')));
  } catch (e) {
    console.warn('ABI not found for', name);
    return null;
  }
}

const diskRegistryAbi = loadAbi('DiskRegistry');
const diskMarketplaceAbi = loadAbi('DiskMarketplace');
const fileRegistryAbi = loadAbi('FileRegistry');

const registryAddr = process.env.DISK_REGISTRY_ADDRESS;
const marketplaceAddr = process.env.DISK_MARKETPLACE_ADDRESS;
const fileRegistryAddr = process.env.FILE_REGISTRY_ADDRESS;

const registry = (diskRegistryAbi && registryAddr) ? new ethers.Contract(registryAddr, diskRegistryAbi, adminWallet || provider) : null;
const marketplace = (diskMarketplaceAbi && marketplaceAddr) ? new ethers.Contract(marketplaceAddr, diskMarketplaceAbi, adminWallet || provider) : null;
const fileRegistry = (fileRegistryAbi && fileRegistryAddr) ? new ethers.Contract(fileRegistryAddr, fileRegistryAbi, adminWallet || provider) : null;

app.get('/', (req, res) => res.send('Disk Rental Backend'));

app.post('/admin/approve-provider', async (req, res) => {
  try {
    const { providerAddress, approve } = req.body;
    if (!adminWallet) return res.status(500).send('NO_ADMIN_KEY');
    if (!registry) return res.status(500).send('REGISTRY_NOT_CONFIGURED');
    const tx = await registry.connect(adminWallet).setProviderApproval(providerAddress, approve);
    await tx.wait();
    res.json({ ok: true, tx: tx.hash });
  } catch (err) { console.error(err); res.status(500).json({ error: err.message }); }
});

app.post('/upload', async (req, res) => {
  try {
    const { filename, contentBase64 } = req.body;
    const client = makeClient();
    const buffer = Buffer.from(contentBase64, 'base64');
    const added = await client.add({ path: filename, content: buffer });
    res.json({ cid: added.cid.toString(), path: added.path });
  } catch (err) { console.error(err); res.status(500).json({ error: err.message }); }
});

app.post('/set-rental-roles', async (req, res) => {
  try {
    const { rentalId, renter, provider: providerAddr } = req.body;
    if (!adminWallet) return res.status(500).send('NO_ADMIN_KEY');
    if (!fileRegistry) return res.status(500).send('FILE_REGISTRY_NOT_CONFIGURED');
    const tx = await fileRegistry.connect(adminWallet).setRentalRoles(rentalId, renter, providerAddr);
    await tx.wait();
    res.json({ ok: true, tx: tx.hash });
  } catch (err) { console.error(err); res.status(500).json({ error: err.message }); }
});

const PORT = process.env.PORT || 4001;
app.listen(PORT, () => console.log(`Backend listening ${PORT}`));
