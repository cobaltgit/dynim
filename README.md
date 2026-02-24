# Dynim

A lightweight update client for [Dynu](https://www.dynu.com/) DDNS written in Nim using the [Dynu IP Update Protocol](https://www.dynu.com/en-US/DynamicDNS/IP-Update-Protocol)

Dynim comes in the form of a dependency-free executable weighing less than 1MB, even when statically linked with musl libc.

## Comparison

|              | [**Dynu IP Update Client**](https://www.dynu.com/Downloads/IP-Update-Client-For-Linux)\* | **Dynim**                                      |
|--------------|------------------------------------------------------------------------------------------|------------------------------------------------|
| Language     | C#                                                                                       | Nim                                            |
| Dependencies | .NET Core 8.0                                                                            | :x: Fully static binary                        |
| Size         | **34MB** for executable + libraries (excludes .NET Core runtime)                         | **<850KB** binary                              |
| Containers   | :x: No official container images                                                         | :white_check_mark: Minimal Dockerfile provided |

*Linux client version 1.0.2

## Building

To build:
```sh
$ nimble static   # static binary linked with musl (requires musl-gcc wrapper)
$ nimble cross    # cross-compiles for x86 and arm, 64 and 32-bit binaries (requires zigcc)
```

### Docker

A minimal, secure Dockerfile that builds an image containing only the `dynim` static binary and your configuration is provided:

```sh
$ nimble docker
```

## Configuration

Dynim supports specifying multiple accounts, as well as groups and domain aliases in accordance with the [Dynu IP Update Protocol](https://www.dynu.com/en-US/DynamicDNS/IP-Update-Protocol).

`dynim.json`, to be placed in your current working directory (rename from `dynim.example.json` for a start):
```json
{
  "accounts": [
    {
      "username": "janedoe", // Dynu username
      "password": "41feae87474fb148c70d7ad4aace39bb14a4fa4e9b6283c5b2abb2295beb0eb3", // Plaintext password, or MD5 or SHA256 hash of password
      "hostnames": ["example.com"], // Hostname(s) to update
      "group": "work", // Group of hostnames to update. Takes precedence over `hostnames`
      "alias": "subdomain" // Alias for a single hostname
    }
  ],
  "use_ipv6": true, // Whether to update IPv6 address. For Docker, you must run the container within a network supporting IPv6 addressing
  "delay": 60000 // Delay in milliseconds between updates
}
```

> [!NOTE]  
> In accordance with security best practices, it is recommended to pass the MD5 or SHA256 hash of your Dynu account password in your `dynim.json` configuration rather than your password in plain text
