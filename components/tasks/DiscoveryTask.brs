' Looks for the Family Dashboard integration on the standard Home Assistant
' port. Roku does not expose a dependable mDNS service browser, so try the
' conventional hostname and then probe the Roku's local IPv4 /24 in batches.
sub init()
    m.top.functionName = "discover"
end sub

sub discover()
    m.top.status = "searching"
    candidates = ["http://homeassistant.local:8123"]

    info = CreateObject("roDeviceInfo")
    addresses = info.GetIPAddrs()
    localIp = ""
    if addresses <> invalid
        for each interfaceName in addresses
            address = addresses[interfaceName]
            if address <> invalid
                value = address.ToStr()
                parts = value.Tokenize(".")
                if parts.Count() = 4 and Left(value, 4) <> "127."
                    localIp = value
                    exit for
                end if
            end if
        end for
    end if

    if localIp <> ""
        octets = localIp.Tokenize(".")
        prefix = octets[0] + "." + octets[1] + "." + octets[2] + "."
        for host = 1 to 254
            candidate = prefix + host.ToStr()
            if candidate <> localIp
                candidates.Push("http://" + candidate + ":8123")
            end if
        end for
    end if

    batchSize = 32
    for first = 0 to candidates.Count() - 1 step batchSize
        last = first + batchSize - 1
        if last >= candidates.Count() then last = candidates.Count() - 1
        found = ProbeBatch(candidates, first, last)
        if found <> ""
            m.top.foundUrl = found
            m.top.status = "found"
            return
        end if
    end for
    m.top.status = "not_found"
end sub

function ProbeBatch(candidates as object, first as integer, last as integer) as string
    port = CreateObject("roMessagePort")
    requests = []
    for index = first to last
        xfer = CreateObject("roUrlTransfer")
        xfer.SetMessagePort(port)
        xfer.RetainBodyOnError(true)
        xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
        xfer.InitClientCertificates()
        xfer.SetUrl(candidates[index] + "/api/family_dashboard/device")
        if xfer.AsyncGetToString()
            requests.Push({ transfer: xfer, url: candidates[index] })
        end if
    end for

    ' Most LAN responses arrive immediately. A short batch deadline keeps a
    ' full /24 scan responsive even when unused addresses silently drop traffic.
    for tick = 1 to 15
        msg = Wait(100, port)
        while msg <> invalid
            if Type(msg) = "roUrlEvent"
                body = msg.GetString()
                code = msg.GetResponseCode()
                if code = 401 and Instr(1, body, "invalid_token") > 0
                    sourceId = msg.GetSourceIdentity()
                    for each request in requests
                        if request.transfer.GetIdentity() = sourceId then return request.url
                    end for
                end if
            end if
            msg = Wait(0, port)
        end while
    end for
    return ""
end function
