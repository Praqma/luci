# Luci Understands Continuous Integration

## Local Configuration
You need to specify a bit of configuration to work with Luci. This is done 
in ~/.luci folder (you can use the env var LUCI_CONFIG).

### Directory zetta_config

The communication with Zetta cloud in Luci is going throught the zetta-tools Docker container. When starting the 
zetta-tools container it is sourcing all *.sh files in $LUCI_CONFIG/zetta_config. To authenticate to Zetta it must
define the following env vars:
- ZETTA_DOMAIN_NAME
- ZETTA_DOMAIN_ID
- ZETTA_USERNAME
- ZETTA_PASSWORD

For example a file named credentials.sh with content:
```
ZETTA_DOMAIN_NAME=praqma
ZETTA_DOMAIN_ID=807427196c02496ea86bc65a110472e6
ZETTA_USERNAME=jas
ZETTA_PASSWORD=mysecret
```

