parser = require "../util/parser"
math = require "../util/math"
logger = require "../util/logger"

Authentication = require "../workers/authentication"
Pool = require "../workers/pool"

module.exports = (socket) ->
  logger: new logger(name: 'Handler')

  read: (packet) ->
    # Debug
    @logger.log @logger.level.DEBUG, "-> #{packet}"

    packetTag = parser.getTagName(packet)

    return if typeof socket is "undefined" or typeof socket is "null" or packetTag is null

    switch packetTag
      when "policy-file-request"
        @send "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\0"
      when "y"
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        @send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_102\" />"
      when "j2"
        # Authenticate the client
        Authentication.process(@, packet)
      when "m"
        # Send message
        msg = parser.getAttribute(packet, 't')
      else
        if packetTag.indexOf('w') is 0
          # Pool packet
          @logger.log @logger.level.ERROR, "The pool packet is in development!", packetTag

          # Pool packet structure
          # <w v="3 0 1 2 3"  /> -> this changes the pool order, we need to reconnect the user, send the <i> and <gp> packet and then the pool changed. Finally request only the actual pool messages and set the user actual pool.
          Pool.switch(@, packetTag.split('w')[1])
        else
          @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag

  send: (packet) ->
    socket.write "#{packet}\0"

    # Debug
    @logger.log(@logger.level.DEBUG, "-> Sent: #{packet}")