startTime = Date.now()

pkg = require '../package'
server = require './services/server'
database = require './services/database'

semver = require 'semver'
{EventEmitter} = require 'events'
_ = require 'underscore'

module.exports =
class Application
  _.extend @prototype, EventEmitter.prototype

  ###
  Section: Properties
  ###
  logger: null
  config: null

  ###
  Section: Construction
  ###
  constructor: ->
    global.Application = this

    @config = require '../config/default'
    @logger = new (require './utils/logger')(Application)

    @logger.log @logger.level.DEBUG, "You are running #{pkg.name} #{pkg.version}"
    @logger.log @logger.level.INFO, "Starting the server in #{@config.env} at port #{@config.port}..."

    # Handle app events
    @handleEvents()

    # Load plugins
    @loadPlugins()

    # Bootstrap the application
    @bootstrap()

  ###
  Section: Private
  ###
  bootstrap: ->
    @logger.log @logger.level.INFO, 'Checking connectivity with database...'

    database.initialize (err) =>
      return @logger.log @logger.level.ERROR, 'No connection with the database', err if err

      server = new server @config.port
      server.bind()

  # Register all application events
  handleEvents: ->
    @on 'application:started', -> @logger.log @logger.level.INFO, "Server started in #{Date.now() - startTime}ms"
    @on 'application:dispose', @dispose

    unless process.platform is 'win32'
      process.on 'SIGTERM', ->
        process.exit 0

  # Load application plugins
  loadPlugins: ->
    plugins = pkg.packageDependencies

    _.mapObject(plugins, (val, key) =>
      try
        # Validate package
        depPkg = require "#{key}/package.json"
        depEngine = depPkg.engines['xat-server']

        if typeof depEngine is 'undefined'
          return throw new Error('The plugin does not support this server')
        else if !semver.satisfies(pkg.version, depEngine)
          return throw new Error("Compatibility error (#{depEngine})")
        else
          dep = require key
          dep.initialize(@)
      catch error then @logger.log @logger.level.ERROR, "Cannot load '#{key}' plugin", error
    )

  # Dispose with success code
  dispose: ->
    process.exit 0
