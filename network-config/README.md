# Network Configuration

> **WARNING: LEGACY REFERENCE ONLY — DO NOT DEPLOY**

The `connection-profile-template.json` in this directory is a legacy template from 2019-2020 and contains critical security issues.

## Security Issues

The template uses **insecure protocols** that must not be used in production:

| Component | Current (Insecure) | Required for Production |
|-----------|-------------------|------------------------|
| Orderer   | `grpc://`         | `grpcs://` (TLS)       |
| Peers     | `grpc://`         | `grpcs://` (TLS)       |
| CA        | `http://`         | `https://` (TLS)       |

## Production Requirements

For Fabric 2.5.x deployments, connection profiles must include:

### 1. TLS-enabled URLs
```json
{
  "orderers": {
    "orderer.example.com": {
      "url": "grpcs://orderer.example.com:7050",
      "tlsCACerts": {
        "pem": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
      }
    }
  },
  "peers": {
    "peer0.org1.example.com": {
      "url": "grpcs://peer0.org1.example.com:7051",
      "tlsCACerts": {
        "pem": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
      }
    }
  },
  "certificateAuthorities": {
    "ca.org1.example.com": {
      "url": "https://ca.org1.example.com:7054",
      "tlsCACerts": {
        "pem": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
      }
    }
  }
}
```

### 2. Mutual TLS (mTLS) for Client Authentication
```json
{
  "client": {
    "tlsEnable": true,
    "clientCert": {
      "path": "/path/to/client.crt"
    },
    "clientKey": {
      "path": "/path/to/client.key"
    }
  }
}
```

### 3. Hostname Override (if needed for local development)
```json
{
  "peers": {
    "peer0.org1.example.com": {
      "url": "grpcs://localhost:7051",
      "grpcOptions": {
        "ssl-target-name-override": "peer0.org1.example.com",
        "hostnameOverride": "peer0.org1.example.com"
      },
      "tlsCACerts": {
        "pem": "..."
      }
    }
  }
}
```

## For 2.0 Development

Use **Hyperledger Bevel** (see `../infrastructure/bevel/`) which generates connection profiles with TLS enabled by default.

Alternatively, create new connection profiles following the [Fabric Gateway documentation](https://hyperledger.github.io/fabric-gateway/).
