# AWS Snow Family — Overview

## 1. What is the Snow Family?

Physical devices AWS ships to your location to **transfer massive amounts
of data into/out of AWS offline** — bypassing the internet entirely —
and to **run compute at the edge** in disconnected environments.

```
When to use Snow instead of internet upload:
  Rule of thumb: if uploading over your internet connection
  would take > 1 week → use a Snow device instead

  Example: 100 TB data @ 1 Gbps connection
    Upload time = 100 TB ÷ 1 Gbps = ~9 days → use Snowball
    Snowball: ship device → load data → ship back → ingested in ~1 week
```

---

## 2. Current Snow Family (as of Nov 2024) ⭐

AWS now offers only **one active device family: Snowball Edge**
in two variants. Snowcone and Snowmobile have been **phased out for
new customers**.

| Device | Storage | Compute | Use Case |
|--------|---------|---------|----------|
| **Snowball Edge Storage Optimized** | **210 TB** NVMe SSD | 104 vCPU, 416 GB RAM | Large-scale data migration |
| **Snowball Edge Compute Optimized** | **28 TB** NVMe SSD | 104 vCPU, 416 GB RAM | Edge compute workloads |

> Previous generation (discontinued Nov 12, 2024): Snowball Edge Storage Optimized 80TB,
> Compute Optimized 52 vCPU, and Compute Optimized with GPU — all retired.

---

## 3. Snowball Edge Features

```
Both variants include:
  S3-compatible API: apps use standard S3 SDK to read/write locally
  EC2-compatible compute: run AMIs locally on the device
  AWS IoT Greengrass: run Lambda functions at the edge
  Encryption: 256-bit encryption, AWS KMS key management
  Tamper-evident: ruggedized, shockproof, weather-resistant casing
  Transfer speed: up to 1.5 GB/s (Storage Optimized 210TB) [aws.amazon](https://aws.amazon.com/blogs/storage/aws-snow-device-updates/)
  Clustering: up to 15 devices clustered → petabyte-scale local storage

Storage Optimized (210 TB): best for bulk data migration
Compute Optimized (28 TB): best for ML inference, video processing,
                            IoT analytics in disconnected environments
```

---

## 4. Phased-Out Devices (Exam Awareness)

```
Snowcone (phased out for new customers):
  Was: smallest Snow device (4.5 lbs), 8 TB HDD or 14 TB SSD
  Could transfer via DataSync over internet OR ship back to AWS
  Now: use Snowball Edge instead

Snowmobile (phased out for new customers):
  Was: a 45-foot shipping container truck
  Capacity: up to 100 PB per trip
  Use was: exabyte-scale data center migrations
  Now: large customers contact AWS directly for alternatives
```

> **Exam note:** Older certifications (SAA-C02, CLF-C01) may still reference
> Snowcone and Snowmobile specs — know them for legacy exam questions.
> Current real-world: Snowball Edge is the active product.

---

## 5. Common Use Cases

```
Data migration:          decommission on-prem data center → ship data to AWS S3/Glacier
Disaster recovery:       periodic full backup shipped to AWS
Edge computing:          oil rigs, military bases, ships, factories with no internet
IoT data collection:     gather sensor data in remote locations → ship to AWS for analysis
Content distribution:    pre-load media content onto device → ship to remote location
```

---

## 6. How the Ordering Process Works

```
1. Order device via AWS console (Snow Family → Create Job)
2. AWS ships Snowball Edge to your location (~4–6 business days)
3. Connect to your network → install Snowball client
4. Transfer data to device (S3-compatible local endpoint)
5. Ship device back to AWS (prepaid shipping label included)
6. AWS ingests data into your specified S3 bucket
7. AWS wipes device securely (NIST 800-88 compliant erasure)
```

---

## 7. Key Exam Points

- [ ] Snow Family purpose: offline data transfer + edge compute — NOT internet-based
- [ ] Active devices: Snowball Edge Storage Optimized (210 TB) and Compute Optimized (28 TB)
- [ ] Snowcone + Snowmobile: **phased out for new customers** as of 2024
- [ ] Data upload to S3 uses S3-compatible local API on the device
- [ ] Encryption: always 256-bit + KMS — data encrypted before leaving your facility
- [ ] AWS wipes device after ingestion (NIST 800-88)
- [ ] Rule of thumb: > 1 week upload time via internet → use Snowball
- [ ] Clustering: up to 15 Snowball Edge devices together for petabyte-scale
