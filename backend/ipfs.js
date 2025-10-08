const { create } = require('ipfs-http-client');

function makeClient() {
  const projectId = process.env.IPFS_PROJECT_ID;
  const projectSecret = process.env.IPFS_PROJECT_SECRET;
  if (projectId && projectSecret) {
    const auth = 'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64');
    return create({
      host: 'ipfs.infura.io',
      port: 5001,
      protocol: 'https',
      headers: { authorization: auth }
    });
  } else {
    return create({ url: 'http://127.0.0.1:5001' });
  }
}

module.exports = { makeClient };
