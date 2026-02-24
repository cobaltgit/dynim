import std/[logging, options as opt]
import chronos/apps/http/httpclient

import config

const IpApi = "https://api.ipify.org"
const Ip6Api = "https://api6.ipify.org"

var
  dynimConfig {.threadvar.}: Config
  logger {.threadvar.}: ConsoleLogger

proc getIp(session: HttpSessionRef): Future[IPInfo] {.async: (raises: [Exception]).} =
  let ipv4Fut = session.fetch(parseUri(IpApi))
  let ipv6Fut = if dynimConfig.useIpv6:
    session.fetch(parseUri(Ip6Api))
  else:
    nil

  let ipv4 = try:
    bytesToString((await ipv4Fut).data)
  except HttpConnectionError as e:
    logger.log(lvlError, "Unable to fetch IPv4 address: " & e.msg)
    ""

  let ipv6 = if ipv6Fut != nil:
    try:
      bytesToString((await ipv6Fut).data)
    except HttpConnectionError as e:
      logger.log(lvlError, "Unable to fetch IPv6 address: " & e.msg)
      ""
  else:
    logger.log(lvlDebug, "Not using IPv6")
    ""

  if (ipv4, ipv6) == ("", ""):
    logger.log(lvlFatal, "Unable to fetch IP addresses!")
    quit(1)
  else:
    logger.log(lvlInfo, "Got IPs: " & ipv4 & ", " & ipv6)
    (ipv4, ipv6)

proc main(): Future[void] {.async: (raises: [Exception]), gcsafe.} =
  logger = newConsoleLogger(fmtStr="[$time] - $levelname: ")
  logger.log(lvlInfo, "Starting Dynim...")

  dynimConfig = parseConfig("dynim.json")
  let sessionFlags = if dynimConfig.useIpv6: {}
                     else: {HttpClientFlag.NoInet6Resolution}
  let session = HttpSessionRef.new(flags = sessionFlags)

  try:
    while true:
      var success = 0
      var error = 0

      logger.log(lvlDebug, "Getting IP addresses")
      let ips = await getIp(session)

      for account in dynimConfig.accounts:
        let hostnames = account.hostnames.get(@[""]).join(",")
        logger.log(lvlInfo, "Updating account: " & account.username & " - hostnames: " & hostnames)
        let resp = await account.update(session, ips)
        case resp
        of "badauth":
          logger.log(lvlError, account.username & ": bad authentication")
          error += 1
        of "abuse":
          logger.log(lvlError, account.username & ": abusive behaviour!")
          error += 1
        of "servererror", "dnserr":
          logger.log(lvlError, account.username & ": server error")
          error += 1
        of "911":
          logger.log(lvlError, account.username & ": update failed due to scheduled maintenance")
          error += 1
        of "nohost":
          logger.log(lvlError, account.username & ": hostname or username not found")
          error += 1
        of "notfqdn":
          logger.log(lvlError, account.username & ": invalid FQDN in one of hostnames: " & hostnames)
          error += 1
        of "numhost":
          logger.log(lvlError, account.username & ": too many hostnames (max. 20)")
          error += 1
        of "unknown":
          logger.log(lvlError, account.username & ": bad request (malformed params?)")
          error += 1
        of "nochg":
          logger.log(lvlInfo, account.username & ": no change")
          success += 1
        else:
          if "good" in resp:
            logger.log(lvlInfo, account.username & ": update successful")
            success += 1
      logger.log(lvlInfo, "Update cycle complete: success=" & $success & ",error=" & $error)
      logger.log(lvlInfo, "Sleeping for " & $dynimConfig.delay & "ms")
      await sleepAsync(dynimConfig.delay)
  finally:
    logger.log(lvlInfo, "Closing HTTP session")
    await noCancel(session.closeWait())

when isMainModule:
  waitFor main()
