# Silver Stack - Self-Hosted CI/CD on iximiuz Labs

Custom rootfs images for Jenkins, SonarQube, and Nexus on iximiuz Labs playgrounds.

## Directory Structure

```
iximiuz/
├── rootfs/                    # Custom rootfs image definitions
│   ├── jenkins/              # Jenkins LTS with Java 21
│   ├── sonarqube/            # SonarQube with PostgreSQL
│   └── nexus/                # Nexus Repository Manager
├── docs/                      # Setup documentation
├── .github/workflows/         # CI/CD automation
└── README.md                 # This file
```

## Quick Start

See individual service README files:
- [Jenkins Setup](./rootfs/jenkins/README.md)
- [SonarQube Setup](./rootfs/sonarqube/README.md)
- [Nexus Setup](./rootfs/nexus/README.md)

## Documentation

Complete guides available in `docs/` directory.

## Author

Muhammad Ibtisam Iqbal
