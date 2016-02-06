database = require "../services/database"

###
Available commands

@name hello
@description Send a 'Hello world'

@name clear all
@description Empty the 'messages' table only for Developers

@name clear
@description Makes every message invisible
###

module.exports =
  identifier: '~'

  process: (@handler, user, msg) ->
    # TODO: Need to check the user rank and probably other details to verify the identity of the user
    return unless msg.indexOf @identifier is 0

    switch msg.slice(1)
      when 'hello'
        @handler.send "<m t=\"Hello world\" u=\"0\" />"
      when 'clear all'
        database.exec('TRUNCATE TABLE messages').then((data) => @handler.send "<m t=\"Messages cleared. Reload chat.\" u=\"0\" />")
      when 'clear'
        database.exec('UPDATE messages set visible = 0 where id= ?',[@handler.chat.id]).then((data) => @handler.send "<m t=\"Messages cleared. Reload chat.\" u=\"0\" />")
