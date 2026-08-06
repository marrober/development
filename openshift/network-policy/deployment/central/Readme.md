# Process and network baselines

## Process Baseline Generation 

If an application executes its initialization commands and normal background scripts within 30 minutes, ROX_BASELINE_GENERATION_DURATION="30m" tells Central to stop recording new commands at the 30-minute mark. Any shell execution occurring after this window triggers a runtime anomaly alert.

## Network Baseline Observation 

If a deployment communicates with a database or external API only once every few hours, configuring ROX_NETWORK_BASELINE_OBSERVATION_PERIOD="4h" forces Central to aggregate and watch network connections for 4 hours before locking down the network graph. This prevents legitimate, infrequent connections from being blocked or alerted on mistakenly.

There is no concept of locking a network baseline in ACS via the web UI. Instead use the ‘Alert on baseline violation’ button. This effectively locks the network baseline and any new network communication will result in a violation. Confusingly via the API this setting is shown as ‘locked’.