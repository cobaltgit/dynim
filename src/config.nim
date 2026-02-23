import std/[json, options, strutils]
import chronos/apps/http/httpclient

const
  DefaultDelay = 60000
  UseIpv6 = true

type IPInfo* = tuple[ipv4: string, ipv6: string]

type Account* = object
  username*: string
  password*: string
  hostnames*: Option[seq[string]]
  alias*: Option[string]
  group*: Option[string]

proc getUrl(account: Account, ipv4: string, ipv6: string): string =
  if account.hostnames.isNone() and account.group.isNone():
    raise newException(ValueError, "must have at least one hostname or a group")

  result = "https://api.dynu.com/nic/update?" & "&username=" & account.username &
    "&password=" & account.password & "&myip=" & ipv4 & "&myipv6=" & ipv6

  if account.group.isSome():
    result &= "&group=" & account.group.get()
  else:
    let hostnames = account.hostnames.get()
    result &= "hostname=" & hostnames.join(",")
    if account.alias.isSome():
      result &= "&alias=" & account.alias.get()

proc update*(account: Account, session: HttpSessionRef, ip: IPInfo): Future[string] {.async.} =
  let ipv6 = if ip.ipv6.len > 0:
    ip.ipv6
  else:
    "no"
  let url = account.getUrl(ip.ipv4, ipv6)
  let resp = await session.fetch(parseUri(url))
  bytesToString(resp.data)

type Config* = object
  accounts*: seq[Account]
  delay*: int
  useIpv6*: bool

proc parseConfig*(path: string): Config =
  var accounts: seq[Account] = @[]

  let json = parseJson(readFile(path))
  for account in json["accounts"].getElems():
    var hostnames: Option[seq[string]] = none(seq[string])
    if account.contains("hostnames"):
      var hs: seq[string] = @[]
      for hostname in account["hostnames"].getElems():
        hs.add(hostname.getStr())
      hostnames = some(hs)

    let alias =
      if account.contains("alias"): some(account["alias"].getStr())
      else: none(string)

    let group =
      if account.contains("group"): some(account["group"].getStr())
      else: none(string)

    accounts.add(Account(
      username: account["username"].getStr(),
      password: account["password"].getStr(),
      hostnames: hostnames,
      alias: alias,
      group: group
    ))

  let delay = if json.contains("delay"):
    json["delay"].getInt()
  else:
    DefaultDelay

  let useIpv6 = if json.contains("use_ipv6"):
    json["use_ipv6"].getBool()
  else:
    UseIpv6

  result = Config(
    accounts: accounts,
    delay: delay,
    useIpv6: useIpv6
  )
