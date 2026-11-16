const fs = require('fs');
const path = require('path');
const NM = '/home/hatch/workspace/contract-build/node_modules';
const solc = require(path.join(NM, 'solc'));
const { keccak256 } = require(path.join(NM, 'js-sha3'));

console.log('solc:', solc.version());
const source = fs.readFileSync(path.join(__dirname, 'AgentDraw.sol'), 'utf8');
const input = {
  language: 'Solidity',
  sources: { 'AgentDraw.sol': { content: source } },
  settings: { optimizer: { enabled: true, runs: 200 }, outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object'] } } }
};
function findImport(p) {
  const full = path.join(NM, p);
  if (fs.existsSync(full)) return { contents: fs.readFileSync(full, 'utf8') };
  return { error: 'File not found: ' + p };
}
const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImport }));
const errors = (output.errors || []).filter(e => e.severity === 'error');
const warnings = (output.errors || []).filter(e => e.severity === 'warning');
console.log('errors:', errors.length, '| warnings:', warnings.length);
errors.forEach(e => console.log('ERROR:', e.formattedMessage));
warnings.forEach(e => console.log('WARN:', (e.formattedMessage || '').split('\n')[0]));
if (errors.length) process.exit(1);
const c = output.contracts['AgentDraw.sol']['AgentDraw'];
if (!c) { console.log('NO CONTRACT OUTPUT'); process.exit(1); }
const bytecode = '0x' + c.evm.bytecode.object;
console.log('COMPILED OK — creation bytes:', c.evm.bytecode.object.length / 2, '| deployed bytes:', c.evm.deployedBytecode.object.length / 2, '| ABI entries:', c.abi.length);
const deployed = '0x' + c.evm.deployedBytecode.object;
const registry = '60b9262456de011f7d15a54cdd8c48baaa8b022f';
console.log('production bytecode contains real registry address:', bytecode.toLowerCase().includes(registry), '| deployed:', deployed.toLowerCase().includes(registry));
fs.writeFileSync(path.join(__dirname, 'AgentDraw.json'), JSON.stringify({ abi: c.abi, bytecode, deployedBytecode: deployed }, null, 2));

function selector(name) {
  const fn = c.abi.find(x => x.type === 'function' && x.name === name);
  if (!fn) return null;
  const sig = name + '(' + fn.inputs.map(i => i.type).join(',') + ')';
  return '0x' + keccak256(sig).slice(0, 8);
}
const wanted = ['totalMinted', 'freeMinted', 'paidMinted', 'mintOpen', 'freeDraw', 'instantDraw', 'currentPrice', 'freeDrawReadyAt', 'freeCooldownRemaining', 'freeRemaining', 'paidRemaining', 'hasAgentId', 'tokenTier', 'freeCountBy', 'paidCountBy', 'lastFreeDrawAt', 'balanceOf', 'ownerOf', 'tokenURI', 'setBaseURI', 'setMintOpen', 'withdraw', 'owner', 'baseURI', 'MAX_SUPPLY', 'FREE_LIMIT', 'PAID_LIMIT', 'BASE_PRICE', 'PRICE_STEP', 'FREE_COOLDOWN', 'AGENT_ID_REGISTRY'];
const selectors = {};
wanted.forEach(n => { selectors[n] = selector(n); });
console.log('selectors:', JSON.stringify(selectors));

const iface = {
  contractName: 'AgentDraw',
  tokenName: 'AgentDraw',
  tokenSymbol: 'DRAW',
  constants: {
    MAX_SUPPLY: 1444,
    FREE_LIMIT: 1222,
    PAID_LIMIT: 222,
    FREE_MAX_PER_WALLET: 2,
    BASE_PRICE_BNB: '0.0012',
    BASE_PRICE_WEI: '1200000000000000',
    PRICE_STEP_BNB: '0.0003',
    PRICE_STEP_WEI: '300000000000000',
    PRICE_STEP_EVERY: 500,
    FREE_COOLDOWN_SECONDS: 90,
    AGENT_ID_REGISTRY: '0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F',
    BASE_URI: 'https://agentdraw.click/meta/'
  },
  abi: c.abi,
  bytecode,
  selectors
};
fs.writeFileSync(path.join(__dirname, '..', 'agentdraw-interface.json'), JSON.stringify(iface, null, 2));
console.log('interface written to ~/workspace/github-push/agentdraw/agentdraw-interface.json');
