noflo = require 'noflo'
uuid = require 'uuid'

try
  microflo = require 'microflo'
catch e
  console.log e

ensureOneIframeRuntime = (runtimes) ->
  filtered = []
  iframeRuntime = null
  for runtime in runtimes
    if runtime.protocol is 'iframe'
      unless iframeRuntime
        iframeRuntime = runtime
        filtered.push runtime
    else
      filtered.push runtime
  unless iframeRuntime
    iframeRuntime =
      label: 'Local NoFlo HTML5 environment'
      id: uuid()
      protocol: 'iframe'
      address: 'preview/iframe.html'
      type: 'noflo-browser'
    filtered.push iframeRuntime
  iframeRuntime.seen = Date.now()
  return filtered

ensureOneMicroFloSimulator = (runtimes) ->
  filtered = []
  foundRuntime = null
  for runtime in runtimes
    if runtime.protocol is 'microflo' and runtime.address is 'simulator://'
      unless foundRuntime
        foundRuntime = runtime
        filtered.push runtime
    else
      filtered.push runtime
  unless foundRuntime
    foundRuntime =
      label: 'Local MicroFlo simulator'
      id: uuid()
      protocol: 'microflo'
      address: 'simulator://'
      type: 'microflo'
    filtered.push foundRuntime
  foundRuntime.seen = Date.now()
  return filtered

ensureMicroFloRuntimePerSerialDevice = (runtimes, callback) ->
  return callback runtimes unless microflo
  return callback runtimes unless microflo.serial.isSupported()

  microflo.serial.listDevices (devices) ->
    # Remove old
    isMicroFloSerial = (rt) ->
      return rt.protocol == 'microflo' && rt.address.indexOf('serial://') != -1
    newRuntimes = runtimes.filter (rt) -> not isMicroFloSerial rt
    # Add new
    for device in devices
      rt =
        label: device
        id: uuid()
        protocol: 'microflo'
        address: 'serial://'+device
        type: 'microflo'
        seen: new Date().toString()
      newRuntimes.push rt
    return callback newRuntimes

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'runtimes',
    datatype: 'array'
  c.outPorts.add 'runtimes',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: 'runtimes'
    out: 'runtimes'
  , (data, groups, out) ->

    runtimesWithOneIframe = ensureOneIframeRuntime data
    runtimesWithMicroFloSimulator = ensureOneMicroFloSimulator runtimesWithOneIframe
    ensureMicroFloRuntimePerSerialDevice runtimesWithMicroFloSimulator, (runtimes) ->
      out.send runtimes

  c
