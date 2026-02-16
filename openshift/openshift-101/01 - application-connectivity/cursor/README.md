# Results viewer

Web application that parses `results.txt` and displays a breakdown of request paths (layer1 → layer2 → layer3) with versions and IPs.

## Run

```bash
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000).

## Data

- **Summary**: Total requests and number of unique paths.
- **By layer**: For each of layer1, layer2, layer3: version counts and IP counts.
- **Requests**: First 100 request paths in table form.
- **Unique paths**: Sorted list of all distinct path combinations.
