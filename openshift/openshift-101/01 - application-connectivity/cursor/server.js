const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 8080;
const RESULTS_PATH = path.join(__dirname, 'results.txt');

// Match: layerN (vX) [IP]
const LAYER_REGEX = /layer(\d+)\s*\(v(\d+)\)\s*\[([^\]]+)\]/g;

function parseLine(line) {
  const hops = [];
  let m;
  LAYER_REGEX.lastIndex = 0;
  while ((m = LAYER_REGEX.exec(line)) !== null) {
    hops.push({
      layer: `layer${m[1]}`,
      version: `v${m[2]}`,
      ip: m[3].trim(),
    });
  }
  return hops;
}

function parseResults(content) {
  const lines = content.split('\n').map((l) => l.trim()).filter(Boolean);
  const requests = lines.map((line, index) => {
    const hops = parseLine(line);
    return {
      id: index + 1,
      path: hops,
      layer1: hops[0] || null,
      layer2: hops[1] || null,
      layer3: hops[2] || null,
      pathKey: hops.map((h) => `${h.layer}:${h.version}@${h.ip}`).join(' → '),
    };
  });

  const versionCount = { layer1: {}, layer2: {}, layer3: {} };
  const ipCount = { layer1: {}, layer2: {}, layer3: {} };
  const ipByVersion = { layer1: {}, layer2: {}, layer3: {} };
  const uniquePaths = new Set();

  requests.forEach((req) => {
    uniquePaths.add(req.pathKey);
    [req.layer1, req.layer2, req.layer3].forEach((hop) => {
      if (!hop) return;
      const layer = hop.layer;
      versionCount[layer][hop.version] = (versionCount[layer][hop.version] || 0) + 1;
      ipCount[layer][hop.ip] = (ipCount[layer][hop.ip] || 0) + 1;
      if (!ipByVersion[layer][hop.version]) ipByVersion[layer][hop.version] = {};
      const vIps = ipByVersion[layer][hop.version];
      vIps[hop.ip] = (vIps[hop.ip] || 0) + 1;
    });
  });

  return {
    totalRequests: requests.length,
    uniquePaths: uniquePaths.size,
    requests,
    versionCount,
    ipCount,
    ipByVersion,
    uniquePathList: [...uniquePaths].sort(),
  };
}

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/results', (req, res) => {
  try {
    const content = fs.readFileSync(RESULTS_PATH, 'utf8');
    const data = parseResults(content);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Results viewer running at http://localhost:${PORT}`);
});
